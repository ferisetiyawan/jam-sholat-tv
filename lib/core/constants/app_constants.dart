import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/foundation.dart';

class AppConstants {
  static const bool isDebug = kDebugMode;

  // --- feature toggles ---
  /// Set to `false` to remove the financial report from the home-screen idle
  /// cycle (the clock+schedule then runs alone).
  static const bool enableFinancialReport = true;

  // --- duration defaults (ConfigProvider) ---
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

  // --- prayer calculation (Kemenag / adhan_dart) ---
  // All prayer times are computed fully on-device; no network or bundled
  // schedule is needed. Fine-tune the coordinates to the masjid's exact
  // position.
  static const double latitude = -6.40; // Depok
  static const double longitude = 106.82; // Depok
  static const double fajrAngle = 20.0; // Kemenag
  static const double ishaAngle = 18.0; // Kemenag
  static const Madhab madhab = Madhab.shafi;

  /// Serialized names accepted for [madhab] in `AppConfig` (kept in sync with
  /// the adhan_dart enum so `domain/` never imports adhan_dart directly).
  static final List<String> madhabNames = [
    for (final Madhab m in Madhab.values) m.name,
  ];
  // Per-prayer ihtiyat (minutes) applied to the raw calculation, Kemenag keys.
  static const Map<String, int> ihtiyat = {
    'imsak': 2,
    'subuh': 2,
    'terbit': -3,
    'dhuhur': 3,
    'ashar': 2,
    'maghrib': 3,
    'isya': 2,
  };

  // --- audio_service.dart ---
  static const String adzanBeepAssetPath = 'sounds/beep_adzan.wav';
  static const String iqomahBeepAssetPath = 'sounds/beep_iqomah.wav';

  // --- app_provider.dart ---
  static const int minutesBeforeMaghrib =
      30; // live makkah before maghrib, in minutes
  static const int minutesBeforeJumat =
      30; // live makkah before jumat, in minutes

  // --- ASSETS ---
  static const String backgroundImage = 'assets/images/background_masjid.jpeg';

  // marquee text
  static const String marqueeText =
      'Selamat Datang di Masjid Al Hijrah CGE - Jagalah Kebersihan dan Matikan Handphone saat Sholat - ';
}
