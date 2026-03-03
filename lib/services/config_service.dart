import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';

class ConfigService {
  final Dio _dio = Dio();
  final Logger _logger = Logger();
  static const String _cacheKey = 'local_config_cache';

  Future<Map<String, dynamic>> fetchRemoteConfig() async {
    Map<String, dynamic> finalData = {};

    try {
      final response = await _dio.get(
        'https://script.google.com/macros/s/AKfycbw4Gp-TV5gmqsBWfFmHYPW5d7_1nBRiAmfEbTBOxWEqzHDnOzUkxhASZ2Bq8m6VgnEZdg/exec?action=config',
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        final remoteData = response.data['data'] as Map<String, dynamic>;

        finalData = _ensureFullConfig(remoteData);

        await _saveToCache(finalData);
        _logger.i("Remote config fetched and cached successfully.");
        return finalData;
      }
    } catch (e) {
      _logger.e("Fetch failed, reverting to cache/backup: $e");
    }

    return await _loadFromCache();
  }

  Map<String, dynamic> _ensureFullConfig(Map<String, dynamic> source) {
    return {
      'homeDuration': source['homeDuration'] ?? AppConstants.homeDuration,
      'eventDuration': source['eventDuration'] ?? AppConstants.eventDuration,
      'reportDuration': source['reportDuration'] ?? AppConstants.reportDuration,
      'adzanDuration': source['adzanDuration'] ?? AppConstants.adzanDuration,
      'jumatDuration': source['jumatDuration'] ?? AppConstants.jumatDuration,

      'iqomahSubuhDuration':
          source['iqomahSubuhDuration'] ?? AppConstants.iqomahSubuhDuration,
      'iqomahMaghribRamadhanDuration':
          source['iqomahMaghribRamadhanDuration'] ??
          AppConstants.iqomahMaghribRamadhanDuration,
      'iqomahDefaultDuration':
          source['iqomahDefaultDuration'] ?? AppConstants.iqomahDefaultDuration,

      'cityId': source['cityId'] ?? AppConstants.cityId,
      'minutesBeforeMaghrib':
          source['minutesBeforeMaghrib'] ?? AppConstants.minutesBeforeMaghrib,
      'minutesBeforeJumat':
          source['minutesBeforeJumat'] ?? AppConstants.minutesBeforeJumat,

      'eventImages': source['eventImages'] ?? AppConstants.eventImages,
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

    if (cachedStr != null) {
      return _ensureFullConfig(jsonDecode(cachedStr));
    }

    return _ensureFullConfig({});
  }
}
