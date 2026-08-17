import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/app_config.dart';
import '../../domain/models/event_image.dart';
import '../../domain/models/financial_summary.dart';

/// Exposes the [AppConfig] to the widget tree.
///
/// The base config comes from [AppConfig] defaults — i.e. the local
/// [AppConstants] values. Overrides saved through the local config server are
/// persisted under [configPrefsKey] and merged on top at startup via [load],
/// and can be hot-applied at runtime via [applyConfig]. It stays a
/// [ChangeNotifier] so screens and the state machine rebuild on change.
class ConfigProvider extends ChangeNotifier {
  ConfigProvider();

  /// SharedPreferences key holding the last saved config (a JSON object in
  /// the same shape as `AppConfig.toJson()`).
  static const String configPrefsKey = 'app_config_json';

  /// Config keys whose unit changed from seconds to MINUTES (v2). A config
  /// saved before that change carries seconds (e.g. `adzanDuration: 180`);
  /// [load] migrates those so an upgraded TV doesn't run multi-minute screens
  /// for what was meant to be a few seconds.
  static const List<String> _minuteDurationKeys = [
    'adzanDuration',
    'jumatDuration',
    'shalatDuration',
    'isyraqDuration',
    'waitingIsyraqDuration',
    'iqomahSubuhDuration',
    'iqomahMaghribRamadhanDuration',
    'iqomahDefaultDuration',
  ];

  AppConfig _config = AppConfig.defaults();

  AppConfig get config => _config;

  /// Converts a persisted config that still stores durations in seconds to the
  /// current minute-based unit. Detection is by content: a value above 59 can
  /// not be minutes in any realistic masjid config, so it is a legacy seconds
  /// value. No-op for configs already in minutes.
  static void _migrateLegacyConfig(Map<String, dynamic> json) {
    final bool looksLegacy = _minuteDurationKeys.any((key) {
      final dynamic value = json[key];
      return value is num && value > 59;
    });
    if (!looksLegacy) return;
    for (final String key in _minuteDurationKeys) {
      final dynamic value = json[key];
      if (value is num && value > 0) {
        json[key] = (value / 60).round();
      }
    }
  }

  /// Merges persisted overrides (if any) on top of the [AppConstants]
  /// defaults. Call once at startup, before the widget tree builds.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(configPrefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final Map<String, dynamic> decoded =
          jsonDecode(raw) as Map<String, dynamic>;
      _migrateLegacyConfig(decoded);
      _config = AppConfig.fromJson(decoded);
      notifyListeners();
    } catch (_) {
      // Corrupt saved config falls back to defaults; never crash the TV.
    }
  }

  /// Replaces the running config immediately and notifies listeners. Used by
  /// the local config server so changes apply without restarting the app.
  void applyConfig(AppConfig config) {
    _config = config;
    notifyListeners();
  }

  String get masjidName => _config.masjidName;
  String get locationName => _config.locationName;
  int get homeDuration => _config.homeDuration;
  int get eventDuration => _config.eventDuration;
  int get reportDuration => _config.reportDuration;
  int get adzanDuration => _config.adzanDuration;
  int get jumatDuration => _config.jumatDuration;
  int get shalatDuration => _config.shalatDuration;
  int get isyraqDuration => _config.isyraqDuration;
  int get hijriCorrection => _config.hijriCorrection;
  String get hijriKalender => _config.hijriKalender;
  int get waitingIsyraqDuration => _config.waitingIsyraqDuration;
  int get iqomahSubuhDuration => _config.iqomahSubuhDuration;
  int get iqomahMaghribRamadhanDuration =>
      _config.iqomahMaghribRamadhanDuration;
  int get iqomahDefaultDuration => _config.iqomahDefaultDuration;
  int get iqomahTestingDuration => _config.iqomahTestingDuration;
  int get minutesBeforeMaghrib => _config.minutesBeforeMaghrib;
  int get minutesBeforeJumat => _config.minutesBeforeJumat;
  String get liveMakkahUrl => _config.liveMakkahUrl;
  double get latitude => _config.latitude;
  double get longitude => _config.longitude;
  double get fajrAngle => _config.fajrAngle;
  double get ishaAngle => _config.ishaAngle;
  String get calculationMethod => _config.calculationMethod;
  String get madhab => _config.madhab;
  Map<String, int> get ihtiyat => _config.ihtiyat;
  String get marqueeText => _config.marqueeText;
  String get backgroundImage => _config.backgroundImage;
  List<EventImage> get eventImages => _config.eventImages;
  bool get enableFinancialReport => _config.enableFinancialReport;
  FinancialSummary get financialSummary => _config.financialSummary;
}
