import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/app_config.dart';

/// Fetches the remote runtime config (Google Apps Script) and keeps event-image
/// assets in sync, with a SharedPreferences offline cache fallback.
class ConfigRemoteService {
  final Dio _dio = Dio();
  final Logger _logger = Logger();
  static const String _cacheKey = 'local_config_cache';

  static const String _endpoint =
      'https://script.google.com/macros/s/AKfycbw4Gp-TV5gmqsBWfFmHYPW5d7_1nBRiAmfEbTBOxWEqzHDnOzUkxhASZ2Bq8m6VgnEZdg/exec?action=config';

  /// Returns the merged [AppConfig]. On any failure falls back to the last
  /// successfully cached config (or defaults when no cache exists).
  Future<AppConfig> fetchRemoteConfig() async {
    try {
      final response = await _dio.get(
        _endpoint,
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          followRedirects: true,
        ),
      );

      if (response.statusCode == 200) {
        final remoteData = response.data['data'] as Map<String, dynamic>;

        await _syncAssets(remoteData);

        final config = AppConfig.fromJson(remoteData);

        await _saveToCache(config);

        _logger.i("Remote config & assets synced successfully.");
        return config;
      }
    } catch (e) {
      _logger.e("Sync failed: $e");
    }

    return await _loadFromCache();
  }

  /// Downloads remote event images to the app documents dir, rewriting each
  /// entry's `url` to the local file path, and cleans up stale files.
  Future<void> _syncAssets(Map<String, dynamic> data) async {
    if (data['eventImages'] == null) return;

    final directory = await getApplicationDocumentsDirectory();
    final List<dynamic> images = List.from(data['eventImages']);
    final List<String> downloadedPaths = [];

    for (var i = 0; i < images.length; i++) {
      String url = images[i]['url']?.toString() ?? '';
      String type = images[i]['type']?.toString().toUpperCase() ?? 'IMAGE';

      if (url.startsWith('http')) {
        try {
          String extName = type.toLowerCase();
          String fileName = "event_${url.hashCode}.$extName";

          String filePath = "${directory.path}/$fileName";
          File file = File(filePath);

          if (!await file.exists()) {
            _logger.d("Downloading new asset: $url");
            await _dio.download(url, filePath);
          }

          images[i]['url'] = filePath;
          downloadedPaths.add(filePath);
        } catch (e) {
          _logger.e("Failed to sync asset $url: $e");
        }
      } else {
        downloadedPaths.add(url);
      }
    }

    try {
      final allFiles = directory.listSync();
      for (var f in allFiles) {
        if (f is File &&
            f.path.contains("event_") &&
            !downloadedPaths.contains(f.path)) {
          await f.delete();
          _logger.d("Cleanup: Deleted old asset ${f.path}");
        }
      }
    } catch (e) {
      _logger.e("Cleanup error: $e");
    }

    data['eventImages'] = images;
  }

  Future<void> _saveToCache(AppConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(config.toJson()));
  }

  Future<AppConfig> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedStr = prefs.getString(_cacheKey);
    if (cachedStr != null) {
      return AppConfig.fromJson(jsonDecode(cachedStr) as Map<String, dynamic>);
    }
    return AppConfig.defaults();
  }
}
