import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/prayer_model.dart';

class PrayerService {
  final Dio _dio = Dio();
  final String cityId = "1225"; 

  static Map<String, String> calculateCountdown(Map<String, String> jadwal) {
    final now = DateTime.now();
    DateTime? nextTime;
    String nextName = "";

    List<String> order = ["Subuh", "Syuruq", "Dzuhur", "Ashar", "Maghrib", "Isya"];

    for (String name in order) {
      String? t = jadwal[name];
      if (t == null || t == "--:--" || t.isEmpty) continue;

      final parts = t.split(':');
      var pTime = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));

      if (pTime.isAfter(now)) {
        nextTime = pTime;
        nextName = name;
        break; 
      }
    }

    // Jika sudah lewat Isya, targetnya adalah Subuh besok
    if (nextTime == null) {
      nextName = "Subuh";
      String? t = jadwal["Subuh"];
      if (t != null && t != "--:--") {
        final parts = t.split(':');
        nextTime = DateTime(now.year, now.month, now.day + 1, int.parse(parts[0]), int.parse(parts[1]));
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

    return {
      "nextName": nextName,
      "countdown": countdown,
    };
  }

  Future<void> fetchAndSaveSixMonths() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    DateTime now = DateTime.now();

    try {
      Map<String, dynamic> allSchedules = {};
      for (int i = 0; i < 6; i++) {
        DateTime targetDate = DateTime(now.year, now.month + i, 1);
        String year = targetDate.year.toString();
        String month = targetDate.month.toString().padLeft(2, '0');

        final response = await _dio.get(
          'https://api.myquran.com/v2/sholat/jadwal/$cityId/$year/$month'
        );

        if (response.statusCode == 200) {
          allSchedules['$year-$month'] = response.data['data']['jadwal'];
        }
      }
      await prefs.setString('offline_prayer_data', jsonEncode(allSchedules));
    } catch (e) {
      print("Error fetching: $e");
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

        // Cek apakah hari ini Jumat
        bool isFriday = DateTime.now().weekday == DateTime.friday;

        return {
          "Subuh": schedule.subuh,
          "Syuruq": schedule.syuruq,
          isFriday ? "Jumat" : "Dzuhur": schedule.dzuhur,
          "Ashar": schedule.ashar,
          "Maghrib": schedule.maghrib,
          "Isya": schedule.isya,
        };
      }
    }
    return null;
  }
}
