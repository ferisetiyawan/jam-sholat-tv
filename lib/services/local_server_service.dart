import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:logger/logger.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/providers/config_provider.dart';
import '../domain/models/app_config.dart';
import 'network_info_helper.dart';

/// Embedded HTTP server that lets the masjid configure the TV from a browser
/// on the same Wi-Fi network.
///
/// Binds to `0.0.0.0:<port>` (default 8080) and exposes:
///
/// - `GET  /api/config` — current effective config as JSON
/// - `POST /api/config` — save new values (persists to SharedPreferences and
///   hot-applies them to [ConfigProvider])
/// - everything else — the static editor UI from `assets/web/` (`/` →
///   `index.html`)
///
/// Every `/api/*` request must authenticate with a per-device secret token
/// (as `?token=…` or `Authorization: Bearer …`). The token is generated once
/// and persisted, so the URL/QR stays stable across restarts.
class LocalServerService {
  LocalServerService({
    required ConfigProvider configProvider,
    int port = defaultPort,
  })  : _configProvider = configProvider,
        _port = port;

  static const int defaultPort = 8080;

  /// The most recently started instance, used by the TV UI to build the QR
  /// URL. Null while the server is stopped.
  static LocalServerService? instance;

  static const String _tokenPrefsKey = 'config_auth_token';
  static const String _eventImagePrefsKey = 'config_event_image';

  final ConfigProvider _configProvider;
  final int _port;
  final NetworkInfoHelper _networkInfo = const NetworkInfoHelper();
  final Logger _logger = Logger();

  HttpServer? _server;
  late String _authToken;
  late Handler _staticHandler;
  late Handler _handler;

  /// The secret that must accompany every `/api/*` call.
  String get authToken => _authToken;

  /// The fully-built shelf handler (also used directly by tests).
  Handler get handler => _handler;

  bool get isRunning => _server != null;

  /// The actual bound port (`_port`, or the ephemeral one when 0).
  int get effectivePort => _server?.port ?? _port;

  /// Binds the server. A bind failure (e.g. port already taken) is logged and
  /// swallowed so a missing config server never blocks the TV.
  Future<void> start() async {
    await _ensureToken();
    _handler = _buildHandler();
    try {
      _server = await shelf_io.serve(_handler, InternetAddress.anyIPv4, _port);
      instance = this;
      _logger.d('Local config server listening on port $effectivePort');
    } catch (e) {
      _logger.e('Failed to start local config server: $e');
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    if (identical(instance, this)) instance = null;
  }

  /// `http://<local-ip>:<port>` (no token), or null when the IP is unknown.
  Future<String?> get localUrl async {
    final String? ip = await _networkInfo.localIPv4();
    if (ip == null) return null;
    return 'http://$ip:$effectivePort';
  }

  /// The URL to embed in the QR code — includes the auth token so that
  /// scanning it yields a working, authenticated session.
  Future<String?> get authenticatedUrl async {
    final String? url = await localUrl;
    if (url == null) return null;
    return '$url?token=$_authToken';
  }

  // --- auth token ----------------------------------------------------------

  Future<void> _ensureToken() async {
    final prefs = await SharedPreferences.getInstance();
    final String? stored = prefs.getString(_tokenPrefsKey);
    if (stored == null || stored.isEmpty) {
      _authToken = _generateToken();
      await prefs.setString(_tokenPrefsKey, _authToken);
    } else {
      _authToken = stored;
    }
  }

  String _generateToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  // --- handler composition -------------------------------------------------

  Handler _buildHandler() {
    _staticHandler = _buildStaticHandler();

    final apiRouter = Router()
      ..get('/config', _getConfig)
      ..post('/config', _postConfig);

    final Handler apiHandler = const Pipeline()
        .addMiddleware(_corsMiddleware())
        .addMiddleware(_authMiddleware())
        .addHandler(apiRouter.call);

    final router = Router(notFoundHandler: _staticHandler)
      ..mount('/api/', apiHandler);

    return const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(router.call);
  }

  /// Serves `assets/web/` from disk when present (dev / `flutter test` runs
  /// from the project root), otherwise from the Flutter asset bundle, which is
  /// the only option on Android release builds.
  Handler _buildStaticHandler() {
    const webDir = 'assets/web';
    if (Directory(webDir).existsSync()) {
      return createStaticHandler(webDir, defaultDocument: 'index.html');
    }
    return _assetBundleHandler;
  }

  static const Map<String, String> _mimeTypes = {
    '.html': 'text/html; charset=utf-8',
    '.js': 'text/javascript; charset=utf-8',
    '.css': 'text/css; charset=utf-8',
    '.png': 'image/png',
    '.svg': 'image/svg+xml',
    '.ico': 'image/x-icon',
    '.json': 'application/json; charset=utf-8',
  };

  Future<Response> _assetBundleHandler(Request request) {
    final String path =
        request.url.path.isEmpty ? 'index.html' : request.url.path;
    final String ext = path.contains('.')
        ? path.substring(path.lastIndexOf('.'))
        : '';
    final String mime = _mimeTypes[ext] ?? 'application/octet-stream';

    return rootBundle.load('assets/web/$path').then(
      (data) => Response.ok(
        data.buffer.asUint8List(),
        headers: {'content-type': mime},
      ),
    ).catchError((_) => Response.notFound('Not found'));
  }

  // --- auth middleware -----------------------------------------------------

  bool _isAuthorized(Request request) {
    final String? token = _tokenFromRequest(request);
    return token != null && _secureEquals(token, _authToken);
  }

  String? _tokenFromRequest(Request request) {
    final String? query = request.url.queryParameters['token'];
    if (query != null && query.isNotEmpty) return query;

    final String? auth = request.headers['authorization'];
    if (auth != null && auth.toLowerCase().startsWith('bearer ')) {
      return auth.substring(7);
    }
    return null;
  }

  bool _secureEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  Middleware _authMiddleware() {
    return (Handler inner) {
      return (Request request) async {
        if (!_isAuthorized(request)) {
          return Response(401,
              body: 'Unauthorized',
              headers: {'content-type': 'text/plain; charset=utf-8'});
        }
        return inner(request);
      };
    };
  }

  // --- CORS (harmless for the same-origin UI; helps direct curl/dev tools) --

  static const Map<String, String> _corsHeaders = {
    'access-control-allow-origin': '*',
    'access-control-allow-methods': 'GET, POST, OPTIONS',
    'access-control-allow-headers': 'authorization, content-type',
  };

  Middleware _corsMiddleware() {
    return (Handler inner) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeaders);
        }
        final Response response = await inner(request);
        return response.change(headers: _corsHeaders);
      };
    };
  }

  // --- API routes ----------------------------------------------------------

  Future<Response> _getConfig(Request request) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> json = _configProvider.config.toJson();
    final String? eventImage = prefs.getString(_eventImagePrefsKey);
    if (eventImage != null) {
      json['eventImage'] = eventImage;
    }
    return _jsonResponse(json);
  }

  Future<Response> _postConfig(Request request) async {
    final Object? decoded = _decodeBody(await _readBody(request));
    if (decoded is! Map<String, dynamic>) {
      return _jsonResponse({'error': 'Expected a JSON object'}, status: 400);
    }
    if (_hasNegativeDuration(decoded)) {
      return _jsonResponse(
        {'error': 'Durations cannot be negative'},
        status: 400,
      );
    }

    final AppConfig config = AppConfig.fromJson(decoded);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      ConfigProvider.configPrefsKey,
      jsonEncode(config.toJson()),
    );

    final dynamic eventImage = decoded['eventImage'];
    if (eventImage is String) {
      await prefs.setString(_eventImagePrefsKey, eventImage);
    } else {
      await prefs.remove(_eventImagePrefsKey);
    }

    // Apply immediately so the TV picks it up without a restart.
    _configProvider.applyConfig(config);

    return _jsonResponse(config.toJson());
  }

  Future<String> _readBody(Request request) async {
    try {
      return await request.readAsString();
    } catch (_) {
      return '';
    }
  }

  Object? _decodeBody(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  bool _hasNegativeDuration(Map<String, dynamic> json) {
    const keys = [
      'homeDuration',
      'eventDuration',
      'reportDuration',
      'adzanDuration',
      'jumatDuration',
      'shalatDuration',
      'isyraqDuration',
      'waitingIsyraqDuration',
      'iqomahSubuhDuration',
      'iqomahMaghribRamadhanDuration',
      'iqomahDefaultDuration',
      'iqomahTestingDuration',
      'minutesBeforeMaghrib',
      'minutesBeforeJumat',
    ];
    for (final key in keys) {
      final dynamic value = json[key];
      if (value is num && value < 0) return true;
    }
    return false;
  }

  Response _jsonResponse(Map<String, dynamic> json, {int status = 200}) {
    return Response(status,
        body: jsonEncode(json),
        headers: {'content-type': 'application/json; charset=utf-8'});
  }
}
