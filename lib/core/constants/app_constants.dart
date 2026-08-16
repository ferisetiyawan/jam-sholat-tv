import 'package:flutter/foundation.dart';

class AppConstants {
  static const bool isDebug = kDebugMode;

  // --- prayer_schedule_service.dart ---
  static const int homeDuration = isDebug ? 2 : 10;
  static const int eventDuration = isDebug ? 3 : 20;
  static const int reportDuration = isDebug ? 3 : 20;
  static const int adzanDuration = 180;
  static const int jumatDuration = isDebug ? 10 : 2700;
  static const int shalatDuration = isDebug ? 10 : 600;
  static const int isyraqDuration = isDebug ? 10 : 600;
  static const int hijriCorrection = -1;
  static const int waitingIsyraqDuration = isDebug ? 15 : 900; // 15 minutes
  static const int iqomahSubuhDuration = 900; // 15 minutes
  static const int iqomahMaghribRamadhanDuration = 900; // 15 minutes
  static const int iqomahDefaultDuration = 600; // 10 minutes
  static const int iqomahTestingDuration = 5;
  static const int monthOfRamadhan = 9; // 9 = Ramadhan in Hijri Calendar
  static const String cityId =
      "1225"; // City ID form Adzan API, can be used to fetch prayer times for specific location

  // --- audio_service.dart ---
  static const String adzanBeepAssetPath = 'sounds/beep_adzan.wav';
  static const String iqomahBeepAssetPath = 'sounds/beep_iqomah.wav';

  // --- app_provider.dart ---
  static const int minutesBeforeMaghrib =
      30; // live makkah before maghrib, in minutes
  static const int minutesBeforeJumat =
      30; // live makkah before jumat, in minutes

  // --- ASSETS ---
  static const List<String> prayerScheduleFiles = [
    '202603.json',
    '202604.json',
    '202605.json',
    '202606.json',
    '202607.json',
    '202608.json',
  ];
  static const String backgroundImage = 'assets/images/background_masjid.jpeg';

  // marquee text
  static const String marqueeText =
      'Selamat Datang di Masjid Al Hijrah CGE - Jagalah Kebersihan dan Matikan Handphone saat Sholat - ';
}
