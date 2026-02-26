import 'package:flutter/foundation.dart';

class AppConstants {
  static const bool isDebug = kDebugMode;

  // --- main.dart ---
  static const int homeDuration = 10;
  static const int eventDuration = 20;
  static const int adzanDuration = 180;
  static const int jumatDuration = 2700;

  // --- prayer_service.dart ---
  static const int iqomahSubuhDuration = 900; // 15 minutes
  static const int iqomahMaghribRamadhanDuration = 900; // 15 minutes
  static const int iqomahDefaultDuration = 600; // 10 minutes
  static const int iqomahTestingDuration = 15;
  static const int monthOfRamadhan = 9; // 9 = Ramadhan in Hijri Calendar
  
  // ID Kota untuk API
  static const String cityId = "1225"; 

  // --- ASSETS ---
  static const List<String> eventImages = [
    'assets/images/kajian1.svg',
    'assets/images/kajian2.svg',
    'assets/images/kajian3.svg',
  ];
}
