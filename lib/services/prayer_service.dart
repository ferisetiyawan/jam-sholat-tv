import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer_model.dart';

class PrayerService {
  final Dio _dio = Dio();
  final String cityId = "1225";

  // Ambil data 6 bulan & simpan offline
  Future<void> fetchAndSaveSixMonths() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    DateTime now = DateTime.now();
    try {
      Map<String, dynamic> allSchedules = {};
      for (int i = 0; i < 6; i++) {
        DateTime targetDate = DateTime(now.year, now.month + i, 1);
        String year = targetDate.year.toString();
        String month = targetDate.month.toString().padLeft(2, '0');

        final response = await _dio.get('https://api.myquran.com/v2/sholat/jadwal/$cityId/$year/$month');
        if (response.statusCode == 200) {
          allSchedules['$year-$month'] = response.data['data']['jadwal'];
        }
      }
      await prefs.setString('offline_prayer_data', jsonEncode(allSchedules));
    } catch (e) {
      print("Gagal update data API, menggunakan cache yang ada: $e");
    }
  }

  // Ambil jadwal khusus hari ini dalam bentuk Map simpel
  Future<Map<String, String>?> getTodayJadwalMap() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? rawData = prefs.getString('offline_prayer_data');
    if (rawData == null) return null;

    Map<String, dynamic> allData = jsonDecode(rawData);
    DateTime now = DateTime.now();
    String keyMonth = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    
    // Format tanggal hari ini yang akan kita cari di data API (YYYY-MM-DD)
    String todayString = DateFormat('yyyy-MM-dd').format(now);

    if (allData.containsKey(keyMonth)) {
      List monthData = allData[keyMonth];
      
      // Cari data yang field 'date'-nya mengandung tanggal hari ini
      var todayData = monthData.firstWhere(
        (element) => element['date'] == todayString,
        orElse: () => null
      );

      if (todayData != null) {
        return {
          "Subuh": todayData['subuh'] ?? "--:--",
          "Syuruq": todayData['terbit'] ?? "--:--",
          "Dzuhur": todayData['dzuhur'] ?? "--:--",
          "Ashar": todayData['ashar'] ?? "--:--",
          "Maghrib": todayData['maghrib'] ?? "--:--",
          "Isya": todayData['isya'] ?? "--:--",
        };
      }
    }
    return null;
  }
}
