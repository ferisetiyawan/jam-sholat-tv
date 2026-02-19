import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer_model.dart';

class PrayerService {
  final Dio _dio = Dio();
  // Ganti ID Kota sesuai lokasi (Contoh: 1219 untuk Depok/Cimanggis)
  // Cek ID kota Anda di https://api.myquran.com/v2/sholat/kota/semua
  final String cityId = "1225"; 

  Future<void> fetchAndSaveSixMonths() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    DateTime now = DateTime.now();

    try {
      Map<String, dynamic> allSchedules = {};

      for (int i = 0; i < 6; i++) {
        // Menghitung bulan dan tahun untuk 6 bulan ke depan
        DateTime targetDate = DateTime(now.year, now.month + i, 1);
        String year = targetDate.year.toString();
        String month = targetDate.month.toString().padLeft(2, '0');

        final response = await _dio.get(
          'https://api.myquran.com/v2/sholat/jadwal/$cityId/$year/$month'
        );

        if (response.statusCode == 200) {
          // Simpan data per bulan ke dalam Map besar
          List jadwalBulanIni = response.data['data']['jadwal'];
          allSchedules['$year-$month'] = jadwalBulanIni;
        }
      }

      // Simpan semua data (6 bulan) ke Local Storage sebagai String JSON
      await prefs.setString('offline_prayer_data', jsonEncode(allSchedules));
      print("Berhasil menyimpan jadwal 6 bulan secara offline!");
      
    } catch (e) {
      print("Gagal mengambil data: $e");
      // Jika gagal (misal tidak ada internet), aplikasi akan tetap pakai data lama di storage
    }
  }

  // Fungsi untuk mengambil jadwal hari ini dari Local Storage
  Future<PrayerSchedule?> getTodaySchedule() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? rawData = prefs.getString('offline_prayer_data');
    
    if (rawData == null) return null;

    Map<String, dynamic> allData = jsonDecode(rawData);
    DateTime now = DateTime.now();
    String key = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    String todayDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    if (allData.containsKey(key)) {
      List monthData = allData[key];
      // Cari data yang tanggalnya sesuai hari ini (format API biasanya 'Senin, 01/01/2024')
      // Note: Anda mungkin perlu menyesuaikan parsing tanggal sesuai format response API yang tepat
      var todayData = monthData.firstWhere(
        (element) => element['date'].contains("${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}"),
        orElse: () => null
      );

      if (todayData != null) {
        return PrayerSchedule.fromJson(todayData);
      }
    }
    return null;
  }
}
