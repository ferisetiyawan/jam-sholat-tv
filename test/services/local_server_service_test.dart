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

  Uri api(String path) => Uri.parse(
        'http://127.0.0.1:${server.effectivePort}$path',
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    provider = ConfigProvider();
    server = LocalServerService(configProvider: provider, port: 0);
  });

  tearDown(() async {
    await server.stop();
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
}
