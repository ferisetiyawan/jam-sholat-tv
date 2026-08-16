import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/app_config.dart';
import '../../domain/models/event_image.dart';

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

  AppConfig _config = AppConfig.defaults();

  AppConfig get config => _config;

  /// Merges persisted overrides (if any) on top of the [AppConstants]
  /// defaults. Call once at startup, before the widget tree builds.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(configPrefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      _config = AppConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
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

  int get homeDuration => _config.homeDuration;
  int get eventDuration => _config.eventDuration;
  int get reportDuration => _config.reportDuration;
  int get adzanDuration => _config.adzanDuration;
  int get jumatDuration => _config.jumatDuration;
  int get shalatDuration => _config.shalatDuration;
  int get isyraqDuration => _config.isyraqDuration;
  int get hijriCorrection => _config.hijriCorrection;
  int get waitingIsyraqDuration => _config.waitingIsyraqDuration;
  int get iqomahSubuhDuration => _config.iqomahSubuhDuration;
  int get iqomahMaghribRamadhanDuration =>
      _config.iqomahMaghribRamadhanDuration;
  int get iqomahDefaultDuration => _config.iqomahDefaultDuration;
  int get iqomahTestingDuration => _config.iqomahTestingDuration;
  int get minutesBeforeMaghrib => _config.minutesBeforeMaghrib;
  int get minutesBeforeJumat => _config.minutesBeforeJumat;
  String get marqueeText => _config.marqueeText;
  String get backgroundImage => _config.backgroundImage;
  List<EventImage> get eventImages => _config.eventImages;
  bool get enableFinancialReport => _config.enableFinancialReport;
}
