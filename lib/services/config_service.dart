import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';

class ConfigService {
  final Dio _dio = Dio();
  final Logger _logger = Logger();
  static const String _cacheKey = 'local_config_cache';

  Future<Map<String, dynamic>> fetchRemoteConfig() async {
    try {
      final response = await _dio.get(
        'https://script.google.com/macros/s/AKfycbw4Gp-TV5gmqsBWfFmHYPW5d7_1nBRiAmfEbTBOxWEqzHDnOzUkxhASZ2Bq8m6VgnEZdg/exec?action=config',
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          followRedirects: true,
        ),
      );

      if (response.statusCode == 200) {
        var remoteData = response.data['data'] as Map<String, dynamic>;

        remoteData = await _syncAssets(remoteData);

        final finalData = _ensureFullConfig(remoteData);

        await _saveToCache(finalData);

        _logger.i("Remote config & assets synced successfully.");
        return finalData;
      }
    } catch (e) {
      _logger.e("Sync failed: $e");
    }

    return await _loadFromCache();
  }

  Future<Map<String, dynamic>> _syncAssets(Map<String, dynamic> data) async {
    if (data['eventImages'] == null) return data;

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
    return data;
  }

  Map<String, dynamic> _ensureFullConfig(Map<String, dynamic> source) {
    return {
      'homeDuration': source['homeDuration'] ?? AppConstants.homeDuration,
      'eventDuration': source['eventDuration'] ?? AppConstants.eventDuration,
      'reportDuration': source['reportDuration'] ?? AppConstants.reportDuration,
      'adzanDuration': source['adzanDuration'] ?? AppConstants.adzanDuration,
      'jumatDuration': source['jumatDuration'] ?? AppConstants.jumatDuration,
      'shalatDuration': source['shalatDuration'] ?? AppConstants.shalatDuration,

      'iqomahSubuhDuration':
          source['iqomahSubuhDuration'] ?? AppConstants.iqomahSubuhDuration,
      'iqomahMaghribRamadhanDuration':
          source['iqomahMaghribRamadhanDuration'] ??
          AppConstants.iqomahMaghribRamadhanDuration,
      'iqomahDefaultDuration':
          source['iqomahDefaultDuration'] ?? AppConstants.iqomahDefaultDuration,

      'minutesBeforeMaghrib':
          source['minutesBeforeMaghrib'] ?? AppConstants.minutesBeforeMaghrib,
      'minutesBeforeJumat':
          source['minutesBeforeJumat'] ?? AppConstants.minutesBeforeJumat,

      'eventImages':
          (source['eventImages'] != null &&
              (source['eventImages'] as List).isNotEmpty)
          ? source['eventImages']
          : AppConstants.eventImages,
      'backgroundImage':
          source['backgroundImage'] ?? AppConstants.backgroundImage,
      'marqueeText': source['marqueeText'] ?? AppConstants.marqueeText,
    };
  }

  Future<void> _saveToCache(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(data));
  }

  Future<Map<String, dynamic>> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedStr = prefs.getString(_cacheKey);
    if (cachedStr != null) return _ensureFullConfig(jsonDecode(cachedStr));
    return _ensureFullConfig({});
  }
}
