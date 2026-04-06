import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:hijriyah_indonesia/hijriyah_indonesia.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../models/prayer_model.dart';

class PrayerService {
  final Dio _dio = Dio();
  final Logger _logger = Logger();

  static Map<String, String> calculateCountdown(Map<String, String> jadwal) {
    final now = DateTime.now();
    DateTime? nextTime;
    String nextName = "";

    bool isFriday = now.weekday == DateTime.friday;

    List<String> order = [
      "Subuh",
      "Syuruq",
      isFriday ? "Jumat" : "Dzuhur",
      "Ashar",
      "Maghrib",
      "Isya",
    ];

    for (String name in order) {
      String? t = jadwal[name] ?? (name == "Jumat" ? jadwal["Dzuhur"] : null);

      if (t == null || t == "--:--" || t.isEmpty) continue;

      final parts = t.split(':');
      var pTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );

      if (pTime.isAfter(now)) {
        nextTime = pTime;
        nextName = name;
        break;
      }
    }

    if (nextTime == null) {
      nextName = "Subuh";
      String? t = jadwal["Subuh"];
      if (t != null && t != "--:--") {
        final parts = t.split(':');
        nextTime = DateTime(
          now.year,
          now.month,
          now.day + 1,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      }
    }

    String countdown = "00:00:00";
    if (nextTime != null) {
      final diff = nextTime.difference(now);
      String h = diff.inHours.toString().padLeft(2, '0');
      String m = (diff.inMinutes % 60).toString().padLeft(2, '0');
      String s = (diff.inSeconds % 60).toString().padLeft(2, '0');
      countdown = "$h:$m:$s";
    }

    return {"nextName": nextName, "countdown": countdown};
  }

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

  static int getIqomahDuration(String prayerName) {
    if (AppConstants.isDebug) return AppConstants.iqomahTestingDuration;

    final hijri = Hijriyah.now();
    bool isRamadhan = hijri.hMonth == AppConstants.monthOfRamadhan;

    if (prayerName == "Subuh") {
      return AppConstants.iqomahSubuhDuration;
    } else if (prayerName == "Maghrib" && isRamadhan) {
      return AppConstants.iqomahMaghribRamadhanDuration;
    } else {
      return AppConstants.iqomahDefaultDuration;
    }
  }
}
