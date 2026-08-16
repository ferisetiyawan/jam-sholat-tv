import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/repositories/config_repository.dart';
import '../../domain/models/app_config.dart';
import '../../domain/models/event_image.dart';

/// Exposes the merged runtime [AppConfig] to the widget tree.
///
/// Holds no fetching/caching logic of its own — that lives in
/// [ConfigRepository]. The provider re-fetches the config once a minute and
/// notifies listeners. Before the first successful fetch, every getter falls
/// back to [AppConfig] defaults.
class ConfigProvider extends ChangeNotifier {
  ConfigProvider({ConfigRepository? repository})
      : _repository = repository ?? ConfigRepository();

  final ConfigRepository _repository;

  AppConfig? _config;

  AppConfig get config => _config ?? AppConfig.defaults();

  int get homeDuration => config.homeDuration;
  int get eventDuration => config.eventDuration;
  int get reportDuration => config.reportDuration;
  int get adzanDuration => config.adzanDuration;
  int get jumatDuration => config.jumatDuration;
  int get shalatDuration => config.shalatDuration;
  int get isyraqDuration => config.isyraqDuration;
  int get hijriCorrection => config.hijriCorrection;
  int get waitingIsyraqDuration => config.waitingIsyraqDuration;
  int get iqomahSubuhDuration => config.iqomahSubuhDuration;
  int get iqomahMaghribRamadhanDuration =>
      config.iqomahMaghribRamadhanDuration;
  int get iqomahDefaultDuration => config.iqomahDefaultDuration;
  int get iqomahTestingDuration => config.iqomahTestingDuration;
  int get minutesBeforeMaghrib => config.minutesBeforeMaghrib;
  int get minutesBeforeJumat => config.minutesBeforeJumat;
  String get marqueeText => config.marqueeText;
  String get backgroundImage => config.backgroundImage;
  List<EventImage> get eventImages => config.eventImages;

  Future<void> init() async {
    await loadConfig();

    Timer.periodic(const Duration(minutes: 1), (timer) async {
      await loadConfig();
    });
  }

  Future<void> loadConfig() async {
    try {
      _config = await _repository.fetchConfig();
      notifyListeners();
    } catch (e) {
      debugPrint("ConfigProvider Error: $e");
    }
  }
}
