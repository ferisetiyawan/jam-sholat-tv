import 'package:flutter/foundation.dart';

class AppConstants {
  static const bool isDebug = kDebugMode;

  // --- main.dart ---
  static const int homeDuration = isDebug ? 3 : 10;
  static const int eventDuration = isDebug ? 5 : 20;
  static const int adzanDuration = 180;
  static const int jumatDuration = isDebug ? 10 : 2700;

  // --- prayer_service.dart ---
  static const int iqomahSubuhDuration = 900; // 15 minutes
  static const int iqomahMaghribRamadhanDuration = 900; // 15 minutes
  static const int iqomahDefaultDuration = 600; // 10 minutes
  static const int iqomahTestingDuration = 15;
  static const int monthOfRamadhan = 9; // 9 = Ramadhan in Hijri Calendar
  static const String cityId =
      "1225"; // City ID form Adzan API, can be used to fetch prayer times for specific location

  // --- audio_service.dart ---
  static const String adzanBeepAssetPath = 'sounds/beep_adzan.wav';
  static const String iqomahBeepAssetPath = 'sounds/beep_iqomah.wav';

  // --- app_provider.dart ---
  static const int minutesBeforeMaghrib =
      120; // live makkah before maghrib, in minutes
  static const int minutesBeforeJumat =
      30; // live makkah before jumat, in minutes

  // --- ASSETS ---
  static const List<String> eventImages = [
    'assets/images/kajian1.svg',
    'assets/images/kajian2.svg',
  ];
}
