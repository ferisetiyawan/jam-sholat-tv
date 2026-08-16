import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../models/prayer_schedule.dart';

/// Offline-first prayer schedule access.
///
/// Bundled monthly JSON assets are the primary source; missing months are
/// fetched from the myquran.com API. Everything is persisted in
/// SharedPreferences under `offline_prayer_data`.
class PrayerScheduleService {
  final Dio _dio = Dio();
  final Logger _logger = Logger();

  Future<void> fetchAndSaveSixMonths() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    DateTime now = DateTime.now();

    String targetPathSuffix = DateFormat('/yyyy/MM').format(now);
    String currentMonthKey = DateFormat('yyyy-MM').format(now);

    String? existingData = prefs.getString('offline_prayer_data');
    Map<String, dynamic> combinedSchedules = existingData != null
        ? jsonDecode(existingData)
        : {};

    if (combinedSchedules.containsKey(currentMonthKey)) {
      _logger.d(
        "Data for $currentMonthKey already exists in local storage. Skipping fetch.",
      );
      return;
    }

    _logger.d(
      "Data for $currentMonthKey not found in local storage. Attempting to load from assets...",
    );

    bool foundInAssets = false;

    for (String fileName in AppConstants.prayerScheduleFiles) {
      try {
        String jsonString = await rootBundle.loadString(
          'assets/schedules/$fileName',
        );
        Map<String, dynamic> decoded = jsonDecode(jsonString);

        String fullPath = decoded['request']?['path'] ?? "";
        List<String> pathParts = fullPath.split('/');

        if (pathParts.length >= 6) {
          String year = pathParts[4];
          String month = pathParts[5];
          String key = "$year-$month";

          combinedSchedules[key] = decoded['data']['jadwal'];

          if (fullPath.endsWith(targetPathSuffix)) {
            foundInAssets = true;
            _logger.i(
              "Data for $currentMonthKey loaded from assets successfully.",
            );
          }
        }
      } catch (e) {
        continue;
      }
    }

    await prefs.setString('offline_prayer_data', jsonEncode(combinedSchedules));

    if (!foundInAssets) {
      _logger.w(
        "Data with target path suffix $targetPathSuffix not found in assets. Will attempt to fetch from API.",
      );
      await _fetchOnlineSchedules(prefs, combinedSchedules);
    }
  }

  Future<void> _fetchOnlineSchedules(
    SharedPreferences prefs,
    Map<String, dynamic> currentMap,
  ) async {
    DateTime now = DateTime.now();
    try {
      for (int i = 0; i < 6; i++) {
        await Future.delayed(const Duration(seconds: 2));

        DateTime targetDate = DateTime(now.year, now.month + i, 1);
        String year = targetDate.year.toString();
        String month = targetDate.month.toString().padLeft(2, '0');
        String key = "$year-$month";

        if (!currentMap.containsKey(key)) {
          final response = await _dio.get(
            'https://api.myquran.com/v2/sholat/jadwal/${AppConstants.cityId}/$year/$month',
            options: Options(
              sendTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          );

          if (response.statusCode == 200) {
            currentMap[key] = response.data['data']['jadwal'];
            _logger.d("Successfully downloaded schedule $key from API.");
          }
        }
      }
      await prefs.setString('offline_prayer_data', jsonEncode(currentMap));
    } catch (e) {
      _logger.e('Error fetching prayer data', error: e);

      rethrow;
    }
  }

  /// Returns today's prayer times as a jadwal map (`Subuh`, `Syuruq`, `Dzuhur`,
  /// `Ashar`, `Maghrib`, `Isya`), or `null` when no data is available locally.
  Future<Map<String, String>?> getTodayJadwalMap() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? rawData = prefs.getString('offline_prayer_data');
    if (rawData == null) return null;

    Map<String, dynamic> allData = jsonDecode(rawData);
    DateTime now = DateTime.now();

    String todayDate = DateFormat('dd/MM/yyyy').format(now);
    String monthKey = DateFormat('yyyy-MM').format(now);

    if (allData.containsKey(monthKey)) {
      List monthList = allData[monthKey];

      var foundData = monthList.firstWhere(
        (item) => item['tanggal'].contains(todayDate),
        orElse: () => null,
      );

      if (foundData != null) {
        PrayerSchedule schedule = PrayerSchedule.fromJson(foundData);

        return {
          "Subuh": schedule.subuh,
          "Syuruq": schedule.syuruq,
          "Dzuhur": schedule.dzuhur,
          "Ashar": schedule.ashar,
          "Maghrib": schedule.maghrib,
          "Isya": schedule.isya,
        };
      }
    }
    return null;
  }
}
