import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/providers/config_provider.dart';
import '../domain/models/app_config.dart';

/// Polls the master device's public config endpoint every [syncInterval] and
/// applies the result to [ConfigProvider]. Only active on follower devices.
///
/// Call [start] once after [ConfigProvider.load]; call [stop] on dispose.
class FollowerSyncService {
  FollowerSyncService({
    required ConfigProvider configProvider,
    this.syncInterval = const Duration(seconds: 30),
  }) : _configProvider = configProvider;

  final ConfigProvider _configProvider;
  final Duration syncInterval;
  final Logger _logger = Logger();

  Timer? _timer;
  DateTime? lastSyncAt;
  String? lastError;

  bool get isRunning => _timer != null;

  void start() {
    if (_timer != null) return;
    _sync(); // immediate first sync
    _timer = Timer.periodic(syncInterval, (_) => _sync());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _sync() async {
    final masterUrl = _configProvider.masterUrl.trimRight();
    if (masterUrl.isEmpty) {
      lastError = 'Master URL belum diatur';
      return;
    }
    final uri = Uri.tryParse('$masterUrl/api/public/config');
    if (uri == null) {
      lastError = 'Master URL tidak valid: $masterUrl';
      return;
    }
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      final req = await client.getUrl(uri);
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      client.close();

      if (res.statusCode != 200) {
        lastError = 'Master mengembalikan HTTP ${res.statusCode}';
        _logger.w('Follower sync error: $lastError');
        return;
      }

      final dynamic decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        lastError = 'Respons master tidak valid';
        return;
      }

      // Preserve this device's own role fields.
      decoded['deviceRole'] = _configProvider.deviceRole;
      decoded['masterUrl'] = _configProvider.masterUrl;

      final newConfig = AppConfig.fromJson(decoded);
      _configProvider.applyConfig(newConfig);

      // Persist so the config survives a restart.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(ConfigProvider.configPrefsKey, jsonEncode(decoded));

      lastSyncAt = DateTime.now();
      lastError = null;
      _logger.d('Follower synced from master at $masterUrl');
    } catch (e) {
      lastError = e.toString();
      _logger.w('Follower sync failed: $e');
    }
  }
}
