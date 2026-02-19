import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/prayer_model.dart';

class PrayerService {
  final Dio _dio = Dio();
  final String cityId = "1225"; 

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
    
    // KUNCI: API MyQuran pakai format DD/MM/YYYY di field 'tanggal'
    String todayDate = DateFormat('dd/MM/yyyy').format(now);
    String monthKey = DateFormat('yyyy-MM').format(now);

    if (allData.containsKey(monthKey)) {
      List monthList = allData[monthKey];
      
      // Cari data yang string tanggalnya mengandung DD/MM/YYYY hari ini
      var foundData = monthList.firstWhere(
        (item) => item['tanggal'].contains(todayDate),
        orElse: () => null,
      );

      if (foundData != null) {
        // Gunakan Model untuk parsing
        PrayerSchedule schedule = PrayerSchedule.fromJson(foundData);
        
        // Kembalikan dalam bentuk Map agar main.dart mudah pakai
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
