import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/providers/config_provider.dart';
import '../core/constants/app_constants.dart';
import '../domain/models/app_config.dart';
import '../domain/models/event_image.dart';
import 'network_info_helper.dart';

/// Embedded HTTP server that lets the masjid configure the TV from a browser
/// on the same Wi-Fi network.
///
/// Binds to `0.0.0.0:<port>` (default 8080) and exposes:
///
/// - `GET  /api/config` — current effective config as JSON
/// - `POST /api/config` — save new values (persists to SharedPreferences and
///   hot-applies them to [ConfigProvider])
/// - `POST /api/upload/background` — replace the background image (multipart
///   not required; raw image bytes in the body)
/// - `POST /api/upload/event` — add an event image (max [maxEventImages])
/// - `DELETE /api/event/<index>` — remove an event image
/// - `DELETE /api/background` — restore the bundled background image
/// - `GET  /images/<name>` — public: serves uploaded images (no token) so the
///   TV and the editor UI can render them
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
    Directory? imagesDirectory,
  })  : _configProvider = configProvider,
        _port = port,
        _imagesDirectory = imagesDirectory;

  static const int defaultPort = 8080;

  /// Hard cap on uploaded images, and on the number of event images the TV can
  /// cycle on the home screen.
  static const int maxImageBytes = 10 * 1024 * 1024; // 10 MB
  static const int maxEventImages = 10;

  /// The most recently started instance, used by the TV UI to build the QR
  /// URL. Null while the server is stopped.
  static LocalServerService? instance;

  static const String _tokenPrefsKey = 'config_auth_token';

  final ConfigProvider _configProvider;
  final int _port;

  /// Injectable for tests; when null the real app-support dir is resolved
  /// lazily on the first file operation (`getApplicationSupportDirectory`).
  final Directory? _imagesDirectory;
  Directory? _resolvedImagesDir;

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
      ..post('/config', _postConfig)
      ..post('/upload/background', _uploadBackground)
      ..post('/upload/event', _uploadEvent)
      ..delete('/event/<index>', _deleteEvent)
      ..delete('/background', _deleteBackground);

    final Handler apiHandler = const Pipeline()
        .addMiddleware(_corsMiddleware())
        .addMiddleware(_authMiddleware())
        .addHandler(apiRouter.call);

    // Uploaded images are served *publicly* (no token) so the TV can load
    // them via NetworkImage/CachedNetworkImage and the browser can <img> them
    // same-origin; only uploads/config edits are token-protected.
    final Router imagesRouter = Router()..get('/<name>', _getImage);

    final router = Router(notFoundHandler: _staticHandler)
      ..mount('/api/', apiHandler)
      ..mount('/images/', imagesRouter.call)
      ..get('/bundled/background', _getBundledBackground);

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
    'access-control-allow-methods': 'GET, POST, OPTIONS, DELETE',
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
    return _jsonResponse(_configProvider.config.toJson());
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
    final String? calcError = _validateCalcParams(decoded);
    if (calcError != null) {
      return _jsonResponse({'error': calcError}, status: 400);
    }

    final AppConfig config = AppConfig.fromJson(decoded);
    await _persistAndApply(config);

    return _jsonResponse(config.toJson());
  }

  /// Returns an error message if any provided prayer-calc value is out of
  /// range, else null. Only validates keys that are actually present, so
  /// partial payloads stay allowed.
  String? _validateCalcParams(Map<String, dynamic> json) {
    final double? latitude = _parseDouble(json['latitude']);
    if (latitude != null && (latitude < -90.0 || latitude > 90.0)) {
      return 'latitude must be between -90 and 90';
    }
    final double? longitude = _parseDouble(json['longitude']);
    if (longitude != null && (longitude < -180.0 || longitude > 180.0)) {
      return 'longitude must be between -180 and 180';
    }
    final double? fajrAngle = _parseDouble(json['fajrAngle']);
    if (fajrAngle != null && (fajrAngle <= 0.0 || fajrAngle > 40.0)) {
      return 'fajrAngle must be in (0, 40]';
    }
    final double? ishaAngle = _parseDouble(json['ishaAngle']);
    if (ishaAngle != null && (ishaAngle <= 0.0 || ishaAngle > 40.0)) {
      return 'ishaAngle must be in (0, 40]';
    }
    return null;
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  /// Persists [config] to SharedPreferences and hot-applies it. Every
  /// mutating endpoint funnels through here so the TV reflects changes without
  /// a restart and they survive relaunches.
  Future<void> _persistAndApply(AppConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      ConfigProvider.configPrefsKey,
      jsonEncode(config.toJson()),
    );
    _configProvider.applyConfig(config);
  }

  // --- image uploads / serving ----------------------------------------------

  Future<Response> _uploadBackground(Request request) =>
      _uploadImage(request, isBackground: true);

  Future<Response> _uploadEvent(Request request) =>
      _uploadImage(request, isBackground: false);

  Future<Response> _uploadImage(
    Request request, {
    required bool isBackground,
  }) async {
    final int? contentLength = request.contentLength;
    if (contentLength != null && contentLength > maxImageBytes) {
      return _jsonResponse({'error': 'Image too large'}, status: 413);
    }

    final Uint8List bytes = await _readBodyBytes(request);
    if (bytes.length > maxImageBytes) {
      return _jsonResponse({'error': 'Image too large'}, status: 413);
    }
    if (bytes.isEmpty) {
      return _jsonResponse({'error': 'Empty body'}, status: 400);
    }

    final String? ext = _imageExtension(request, bytes);
    if (ext == null) {
      return _jsonResponse(
        {'error': 'Unsupported image type (jpeg/png/webp/gif only)'},
        status: 415,
      );
    }

    if (!isBackground &&
        _configProvider.config.eventImages.length >= maxEventImages) {
      return _jsonResponse(
        {'error': 'Maximum $maxEventImages event images reached'},
        status: 400,
      );
    }

    final Directory dir = await _ensureImagesDir();
    final String prefix = isBackground ? 'bg_' : 'ev_';
    // Two uploads in the same millisecond would collide on the filename and
    // silently overwrite; suffix a counter until the name is free so every
    // upload stays unique (which also busts the TV's image caches).
    String fileName = '$prefix${DateTime.now().millisecondsSinceEpoch}$ext';
    File out = File('${dir.path}${Platform.pathSeparator}$fileName');
    var attempt = 1;
    while (out.existsSync()) {
      fileName =
          '$prefix${DateTime.now().millisecondsSinceEpoch}_$attempt$ext';
      out = File('${dir.path}${Platform.pathSeparator}$fileName');
      attempt++;
    }
    await out.writeAsBytes(bytes, flush: true);

    if (isBackground) {
      // Only one background survives; drop any previous upload so the TV never
      // serves a stale cached image.
      await _deleteFiles(dir, prefix: 'bg_', except: fileName);
      await _persistAndApply(
        AppConfig.fromJson({
          ..._configProvider.config.toJson(),
          'backgroundImage': _imageUrlFor(fileName),
        }),
      );
    } else {
      await _persistAndApply(
        AppConfig.fromJson({
          ..._configProvider.config.toJson(),
          'eventImages': [
            ..._configProvider.config.eventImages.map((e) => e.toJson()),
            EventImage(type: 'IMAGE', url: _imageUrlFor(fileName)).toJson(),
          ],
        }),
      );
    }

    return _jsonResponse(_configProvider.config.toJson());
  }

  Future<Uint8List> _readBodyBytes(Request request) async {
    final BytesBuilder builder = BytesBuilder(copy: false);
    await for (final List<int> chunk in request.read()) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  /// Resolves the file extension for an upload from the `Content-Type` header,
  /// falling back to magic-byte sniffing when the header is generic (a browser
  /// `fetch(body: File)` commonly sends `application/octet-stream`). Returns
  /// null for non-raster types (e.g. SVG/text), which are rejected.
  String? _imageExtension(Request request, List<int> bytes) {
    final String? contentType = request.headers['content-type']?.toLowerCase();
    if (contentType != null) {
      final String mime = contentType.split(';').first.trim();
      final String? fromMime = _imageExtByMime[mime];
      if (fromMime != null) return fromMime;
    }
    return _extFromMagic(bytes);
  }

  static const Map<String, String> _imageExtByMime = {
    'image/png': '.png',
    'image/jpeg': '.jpg',
    'image/jpg': '.jpg',
    'image/gif': '.gif',
    'image/webp': '.webp',
  };

  String? _extFromMagic(List<int> bytes) {
    if (bytes.length < 4) return null;
    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return '.png';
    }
    // GIF: "GIF8"
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
      return '.gif';
    }
    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return '.jpg';
    }
    // WEBP: "RIFF" .... "WEBP"
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return '.webp';
    }
    return null;
  }

  Future<Response> _deleteEvent(Request request, String index) async {
    final int? i = int.tryParse(index);
    if (i == null) {
      return _jsonResponse({'error': 'Invalid index'}, status: 400);
    }
    final List<EventImage> images = _configProvider.config.eventImages;
    if (i < 0 || i >= images.length) {
      return _jsonResponse({'error': 'Index out of range'}, status: 404);
    }

    final EventImage removed = images[i];
    // Only delete the file when it is one of ours (uploaded via the server);
    // external/legacy URLs are left untouched.
    if (_isOwnedImageUrl(removed.url)) {
      final String name = removed.url.split('/').last;
      final File file = File(
        '${(await _ensureImagesDir()).path}${Platform.pathSeparator}$name',
      );
      if (file.existsSync()) {
        try {
          await file.delete();
        } catch (e) {
          _logger.e('Failed to delete event image $name: $e');
        }
      }
    }

    await _persistAndApply(
      AppConfig.fromJson({
        ..._configProvider.config.toJson(),
        'eventImages': [
          for (int j = 0; j < images.length; j++)
            if (j != i) images[j].toJson(),
        ],
      }),
    );
    return _jsonResponse(_configProvider.config.toJson());
  }

  Future<Response> _deleteBackground(Request request) async {
    final Directory dir = await _ensureImagesDir();
    await _deleteFiles(dir, prefix: 'bg_');
    await _persistAndApply(
      AppConfig.fromJson({
        ..._configProvider.config.toJson(),
        'backgroundImage': AppConstants.backgroundImage,
      }),
    );
    return _jsonResponse(_configProvider.config.toJson());
  }

  /// Whether [url] points at a file we uploaded — the absolute baked form
  /// (`http://127.0.0.1:<port>/images/<name>`) or a relative `/images/<name>`.
  /// The path must be exactly `images/<single-name>` so we can compute the
  /// on-disk filename safely.
  bool _isOwnedImageUrl(String url) {
    Uri uri;
    try {
      uri = Uri.parse(url);
    } catch (_) {
      return false;
    }
    final List<String> segments = uri.pathSegments;
    final bool safeSegment = segments.length == 2 &&
        segments[0] == 'images' &&
        segments[1].isNotEmpty &&
        !segments[1].contains('/') &&
        !segments[1].contains('\\') &&
        !segments[1].contains('..');
    return safeSegment;
  }

  /// Deletes every file in [dir] whose name starts with [prefix], skipping
  /// [except] if given. Failures are logged, never thrown.
  Future<void> _deleteFiles(
    Directory dir, {
    required String prefix,
    String? except,
  }) async {
    final List<File> matches = dir
        .listSync()
        .whereType<File>()
        .where((File f) => f.path.split(Platform.pathSeparator).last
            .startsWith(prefix))
        .where((File f) =>
            f.path.split(Platform.pathSeparator).last != except)
        .toList();
    for (final File file in matches) {
      try {
        await file.delete();
      } catch (e) {
        _logger.e('Failed to delete ${file.path}: $e');
      }
    }
  }

  /// The directory that holds uploaded images, created on first use. Uses the
  /// injected [imagesDirectory] (tests), else the app-support dir.
  Future<Directory> _ensureImagesDir() async {
    final Directory? resolved = _resolvedImagesDir;
    if (resolved != null) return resolved;

    final Directory dir = _imagesDirectory ??
        Directory(
          '${(await getApplicationSupportDirectory()).path}'
          '${Platform.pathSeparator}config_images',
        );
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    _resolvedImagesDir = dir;
    return dir;
  }

  /// The absolute URL the TV will use to load an uploaded image. `127.0.0.1`
  /// is the device itself, so the TV always reaches its own embedded server.
  String _imageUrlFor(String fileName) =>
      'http://127.0.0.1:$_port/images/$fileName';

  static const Map<String, String> _imageMimeTypes = {
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.gif': 'image/gif',
    '.webp': 'image/webp',
  };

  /// Serves an uploaded image. Public (no token) so the TV's
  /// NetworkImage/CachedNetworkImage and the browser's `<img>` tags can load
  /// them; guarded against path traversal since this route is unauthenticated.
  Future<Response> _getImage(Request request, String name) async {
    if (name.isEmpty ||
        name.contains('/') ||
        name.contains('\\') ||
        name.contains('..')) {
      return Response.notFound('Not found');
    }

    final Directory dir = await _ensureImagesDir();
    final File file = File('${dir.path}${Platform.pathSeparator}$name');
    if (!file.existsSync()) return Response.notFound('Not found');

    final String ext = name.contains('.')
        ? name.substring(name.lastIndexOf('.')).toLowerCase()
        : '';
    final String mime = _imageMimeTypes[ext] ?? 'application/octet-stream';
    return Response.ok(
      file.readAsBytesSync(),
      headers: {'content-type': mime, 'cache-control': 'no-cache'},
    );
  }

  /// Serves the bundled default background (`AppConstants.backgroundImage`)
  /// over HTTP. Public (no token) like `/images/*` — the asset is app-owned —
  /// so the dashboard preview can display it even though bundled assets aren't
  /// reachable as real files on Android. Mirrors `_buildStaticHandler`: when the
  /// asset is on disk (e.g. `flutter test` runs from the project root) read it
  /// as a file; otherwise load it from `rootBundle` (dev/release on Android).
  Future<Response> _getBundledBackground(Request request) async {
    final String asset = AppConstants.backgroundImage;
    final String ext = asset.contains('.')
        ? asset.substring(asset.lastIndexOf('.')).toLowerCase()
        : '';
    final String mime = _imageMimeTypes[ext] ?? 'application/octet-stream';
    try {
      final File file = File(asset);
      List<int> bytes;
      if (file.existsSync()) {
        bytes = await file.readAsBytes();
      } else {
        final ByteData data = await rootBundle.load(asset);
        bytes = data.buffer.asUint8List();
      }
      return Response.ok(
        bytes,
        headers: {'content-type': mime, 'cache-control': 'no-cache'},
      );
    } catch (_) {
      return Response.notFound('Not found');
    }
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
