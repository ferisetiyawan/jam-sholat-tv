import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jam_sholat_tv/app/providers/config_provider.dart';
import 'package:jam_sholat_tv/core/constants/app_constants.dart';
import 'package:jam_sholat_tv/services/local_server_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ConfigProvider provider;
  late LocalServerService server;
  late Directory tempDir;

  Uri api(String path) => Uri.parse(
        'http://127.0.0.1:${server.effectivePort}$path',
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    tempDir = Directory.systemTemp.createTempSync('config_images_test');
    provider = ConfigProvider();
    server = LocalServerService(
      configProvider: provider,
      port: 0,
      imagesDirectory: tempDir,
    );
  });

  tearDown(() async {
    await server.stop();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Future<(int, String)> get(String path, {String? token}) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(api(path));
      if (token != null) {
        request.headers.set('authorization', 'Bearer $token');
      }
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      return (response.statusCode, body);
    } finally {
      client.close(force: true);
    }
  }

  Future<(int, String)> post(String path, String body, {String? token}) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(api(path));
      if (token != null) {
        request.headers.set('authorization', 'Bearer $token');
      }
      request.headers.contentType = ContentType.json;
      request.write(body);
      final response = await request.close();
      final text = await response.transform(utf8.decoder).join();
      return (response.statusCode, text);
    } finally {
      client.close(force: true);
    }
  }

  Future<(int, String)> del(String path, {String? token}) async {
    final client = HttpClient();
    try {
      final request = await client.deleteUrl(api(path));
      if (token != null) {
        request.headers.set('authorization', 'Bearer $token');
      }
      final response = await request.close();
      final text = await response.transform(utf8.decoder).join();
      return (response.statusCode, text);
    } finally {
      client.close(force: true);
    }
  }

  Future<(int, String)> upload(
    String path,
    List<int> bytes, {
    String? token,
    String contentType = 'image/png',
  }) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(api(path));
      if (token != null) {
        request.headers.set('authorization', 'Bearer $token');
      }
      request.headers.contentType = ContentType.parse(contentType);
      request.add(bytes);
      final response = await request.close();
      final text = await response.transform(utf8.decoder).join();
      return (response.statusCode, text);
    } finally {
      client.close(force: true);
    }
  }

  Future<(int, List<int>)> getBytes(String path) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(api(path));
      final response = await request.close();
      final bytes = await response
          .fold<List<int>>(<int>[], (acc, chunk) => acc..addAll(chunk));
      return (response.statusCode, bytes);
    } finally {
      client.close(force: true);
    }
  }

  /// A tiny-but-valid PNG header; enough for magic-byte sniffing and serving.
  final List<int> pngBytes = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

  List<File> filesWithPrefix(String prefix) => tempDir
      .listSync()
      .whereType<File>()
      .where(
        (f) => f.path.split(Platform.pathSeparator).last.startsWith(prefix),
      )
      .toList();

  group('LocalServerService', () {
    test('binds and serves the API; unauthenticated requests get 401', () async {
      await server.start();

      final (noToken, _) = await get('/api/config');
      expect(noToken, 401);

      final (badToken, _) =
          await get('/api/config', token: 'not-the-real-token');
      expect(badToken, 401);

      final (ok, body) = await get('/api/config', token: server.authToken);
      expect(ok, 200);
      final Map<String, dynamic> json =
          jsonDecode(body) as Map<String, dynamic>;
      expect(json['homeDuration'], AppConstants.homeDuration);
      expect(json['enableFinancialReport'], AppConstants.enableFinancialReport);
    });

    test('POST /api/config hot-applies and persists', () async {
      await server.start();

      final (status, body) = await post(
        '/api/config',
        jsonEncode({'homeDuration': 5, 'marqueeText': 'Selamat datang'}),
        token: server.authToken,
      );
      expect(status, 200);
      expect(jsonDecode(body)['homeDuration'], 5);

      // Hot-applied to the running provider.
      expect(provider.homeDuration, 5);
      expect(provider.marqueeText, 'Selamat datang');

      // GET reflects the new value.
      final (_, getBody) = await get('/api/config', token: server.authToken);
      expect(jsonDecode(getBody)['homeDuration'], 5);

      // A fresh provider (new launch) loads the persisted value.
      final reloaded = ConfigProvider();
      await reloaded.load();
      expect(reloaded.homeDuration, 5);
      expect(reloaded.marqueeText, 'Selamat datang');
    });

    test('POST rejects malformed bodies and negative durations', () async {
      await server.start();

      final (badJson, _) =
          await post('/api/config', '{not json', token: server.authToken);
      expect(badJson, 400);

      final (negative, _) = await post(
        '/api/config',
        jsonEncode({'homeDuration': -5}),
        token: server.authToken,
      );
      expect(negative, 400);

      // No change was applied.
      expect(provider.homeDuration, AppConstants.homeDuration);
    });

    test('serves the editor UI at / and 404s missing files', () async {
      await server.start();

      final (root, rootBody) = await get('/');
      expect(root, 200);
      expect(rootBody, contains('Pengaturan Jam Sholat TV'));

      final (index, indexBody) = await get('/index.html');
      expect(index, 200);
      expect(indexBody, contains('Pengaturan'));

      final (missing, _) = await get('/does-not-exist.js');
      expect(missing, 404);
    });
  });

  group('LocalServerService images & calc params', () {
    test('GET /api/config exposes calc fields, no legacy eventImage', () async {
      await server.start();

      final (status, body) = await get('/api/config', token: server.authToken);
      expect(status, 200);
      final Map<String, dynamic> json =
          jsonDecode(body) as Map<String, dynamic>;

      expect(json['latitude'], AppConstants.latitude);
      expect(json['longitude'], AppConstants.longitude);
      expect(json['fajrAngle'], AppConstants.fajrAngle);
      expect(json['ishaAngle'], AppConstants.ishaAngle);
      expect(json['madhab'], AppConstants.madhab.name);
      expect(json['ihtiyat'], isA<Map>());
      expect(json.containsKey('eventImage'), isFalse);
    });

    test('POST /api/config persists+applies calc params; range validated',
        () async {
      await server.start();

      final (ok, okBody) = await post(
        '/api/config',
        jsonEncode({
          'latitude': 3.60,
          'longitude': 98.67,
          'madhab': 'hanafi',
          'ihtiyat': {'subuh': 5},
        }),
        token: server.authToken,
      );
      expect(ok, 200);
      expect(jsonDecode(okBody)['madhab'], 'hanafi');

      // Hot-applied to the running provider.
      expect(provider.latitude, 3.60);
      expect(provider.longitude, 98.67);
      expect(provider.madhab, 'hanafi');
      expect(provider.ihtiyat['subuh'], 5);

      // A fresh provider (new launch) loads the persisted values.
      final reloaded = ConfigProvider();
      await reloaded.load();
      expect(reloaded.latitude, 3.60);
      expect(reloaded.madhab, 'hanafi');
      expect(reloaded.ihtiyat['subuh'], 5);

      final (badLat, badLatBody) = await post(
        '/api/config',
        jsonEncode({'latitude': 91}),
        token: server.authToken,
      );
      expect(badLat, 400);
      expect(badLatBody, contains('latitude'));

      final (badAngle, _) = await post(
        '/api/config',
        jsonEncode({'ishaAngle': 55}),
        token: server.authToken,
      );
      expect(badAngle, 400);
    });

    test('uploads a background image and serves it publicly', () async {
      await server.start();

      final (status, body) = await upload(
        '/api/upload/background',
        pngBytes,
        token: server.authToken,
      );
      expect(status, 200);
      final Map<String, dynamic> json =
          jsonDecode(body) as Map<String, dynamic>;
      final String bg = json['backgroundImage'] as String;
      expect(bg, contains('/images/bg_'));

      expect(provider.backgroundImage, bg);
      expect(filesWithPrefix('bg_'), hasLength(1));

      // Public fetch — no token needed.
      final (imgStatus, imgBytes) = await getBytes('/images/${bg.split('/').last}');
      expect(imgStatus, 200);
      expect(imgBytes, pngBytes);
    });

    test('re-uploading a background replaces the previous file', () async {
      await server.start();

      await upload('/api/upload/background', pngBytes, token: server.authToken);
      final (_, secondBody) = await upload(
        '/api/upload/background',
        pngBytes,
        token: server.authToken,
      );
      expect(secondBody, contains('/images/bg_'));
      expect(filesWithPrefix('bg_'), hasLength(1));
    });

    test('uploads event images up to the 10-image cap', () async {
      await server.start();

      for (var i = 0; i < 10; i++) {
        final (status, body) = await upload(
          '/api/upload/event',
          pngBytes,
          token: server.authToken,
        );
        expect(status, 200, reason: 'upload #$i');
        expect(jsonDecode(body)['eventImages'] as List, hasLength(i + 1));
      }

      final (over, overBody) = await upload(
        '/api/upload/event',
        pngBytes,
        token: server.authToken,
      );
      expect(over, 400);
      expect(overBody, contains('Maximum'));

      expect(provider.eventImages, hasLength(10));
      expect(filesWithPrefix('ev_'), hasLength(10));
    });

    test('DELETE /api/event/<index> removes the entry and its file', () async {
      await server.start();

      await upload('/api/upload/event', pngBytes, token: server.authToken);
      await upload('/api/upload/event', pngBytes, token: server.authToken);
      expect(provider.eventImages, hasLength(2));
      expect(filesWithPrefix('ev_'), hasLength(2));

      final (status, body) = await del('/api/event/0', token: server.authToken);
      expect(status, 200);
      expect(jsonDecode(body)['eventImages'] as List, hasLength(1));
      expect(provider.eventImages, hasLength(1));
      expect(filesWithPrefix('ev_'), hasLength(1));

      final (badIndex, _) = await del('/api/event/99', token: server.authToken);
      expect(badIndex, 404);
    });

    test('DELETE removes external-URL event entries without touching files',
        () async {
      await server.start();

      await post(
        '/api/config',
        jsonEncode({
          'eventImages': [
            {'type': 'IMAGE', 'url': 'https://example.com/remote.png'},
          ],
        }),
        token: server.authToken,
      );
      expect(provider.eventImages, hasLength(1));

      final (status, body) = await del('/api/event/0', token: server.authToken);
      expect(status, 200);
      expect(jsonDecode(body)['eventImages'] as List, isEmpty);
      expect(filesWithPrefix('ev_'), isEmpty);
    });

    test('DELETE /api/background restores the bundled image', () async {
      await server.start();

      await upload('/api/upload/background', pngBytes, token: server.authToken);
      expect(provider.backgroundImage, contains('/images/bg_'));

      final (status, body) =
          await del('/api/background', token: server.authToken);
      expect(status, 200);
      expect(jsonDecode(body)['backgroundImage'], AppConstants.backgroundImage);
      expect(provider.backgroundImage, AppConstants.backgroundImage);
      expect(filesWithPrefix('bg_'), isEmpty);
    });

    test('image serving is guarded: unknown and traversal names get 404',
        () async {
      await server.start();

      final (missing, _) = await getBytes('/images/nope.png');
      expect(missing, 404);

      final (traversal, _) = await getBytes('/images/..%2fpubspec.yaml');
      expect(traversal, 404);
    });

    test('uploads require auth and reject bad bodies', () async {
      await server.start();

      final (unauth, _) = await upload('/api/upload/background', pngBytes);
      expect(unauth, 401);

      final (textType, textBody) = await upload(
        '/api/upload/background',
        [0x54, 0x45, 0x58, 0x54], // "TEXT" — not a raster image
        token: server.authToken,
        contentType: 'text/plain',
      );
      expect(textType, 415);
      expect(textBody, contains('Unsupported'));

      final (empty, _) = await upload(
        '/api/upload/background',
        <int>[],
        token: server.authToken,
        contentType: 'application/octet-stream',
      );
      expect(empty, 400);

      final (oversized, _) = await upload(
        '/api/upload/background',
        List<int>.filled(LocalServerService.maxImageBytes + 1, 0),
        token: server.authToken,
        contentType: 'application/octet-stream',
      );
      expect(oversized, 413);
    });
  });
}
