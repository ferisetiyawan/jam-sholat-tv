import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/foundation.dart';

class AppConstants {
  static const bool isDebug = kDebugMode;

  // --- feature toggles ---
  /// Set to `false` to remove the financial report from the home-screen idle
  /// cycle (the clock+schedule then runs alone).
  static const bool enableFinancialReport = true;

  // --- duration defaults (ConfigProvider) ---
  // Units: durations below marked MINUTES are configured and stored in minutes
  // (converted to seconds when the countdown runs); the rest stay in seconds.
  // In debug builds the state machine shortens the minute-based durations to a
  // few seconds so the prayer cycle can be tested quickly.
  static const int homeDuration = isDebug ? 2 : 10;
  static const int eventDuration = isDebug ? 3 : 20;
  static const int reportDuration = isDebug ? 3 : 20;
  static const int adzanDuration = 3; // minutes
  static const int jumatDuration = 45; // minutes
  static const int shalatDuration = 10; // minutes
  static const int isyraqDuration = 10; // minutes
  static const int hijriCorrection = -1;
  static const int waitingIsyraqDuration = 15; // minutes
  static const int iqomahSubuhDuration = 15; // minutes
  static const int iqomahMaghribRamadhanDuration = 15; // minutes
  static const int iqomahDefaultDuration = 10; // minutes

  /// Seconds the iqomah stage lasts in debug builds only. Debug-only: hidden
  /// from the config dashboard and never used in release builds.
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

  /// YouTube URL of the live Makkah (Masjid al-Haram) stream shown during the
  /// pre-Maghrib / pre-Jumat live mode. Editable at runtime through the local
  /// config server's "Konfigurasi Live Makkah" (dashboard). Verified 24/7 feed
  /// (AlQuran4K); if it ever stops, the masjid can swap it from the dashboard.
  static const String liveMakkahUrl =
      'https://www.youtube.com/watch?v=_y45JcS3MlQ'; // Makkah Live HD (AlQuran4K)

  // --- ASSETS ---
  static const String backgroundImage = 'assets/images/background_masjid.jpeg';

  // marquee text
  static const String marqueeText =
      'Selamat Datang di Masjid Al Hijrah CGE - Jagalah Kebersihan dan Matikan Handphone saat Sholat - ';
}
