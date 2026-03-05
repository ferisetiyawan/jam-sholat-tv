import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../services/config_service.dart';

class ConfigProvider extends ChangeNotifier {
  final ConfigService _service = ConfigService();

  Map<String, dynamic> _settings = {};

  int get homeDuration =>
      _settings['homeDuration'] ?? AppConstants.homeDuration;
  int get eventDuration =>
      _settings['eventDuration'] ?? AppConstants.eventDuration;
  int get reportDuration =>
      _settings['reportDuration'] ?? AppConstants.reportDuration;
  int get adzanDuration =>
      _settings['adzanDuration'] ?? AppConstants.adzanDuration;
  int get jumatDuration =>
      _settings['jumatDuration'] ?? AppConstants.jumatDuration;

  int get iqomahSubuhDuration =>
      _settings['iqomahSubuhDuration'] ?? AppConstants.iqomahSubuhDuration;
  int get iqomahMaghribRamadhanDuration =>
      _settings['iqomahMaghribRamadhanDuration'] ??
      AppConstants.iqomahMaghribRamadhanDuration;
  int get iqomahDefaultDuration =>
      _settings['iqomahDefaultDuration'] ?? AppConstants.iqomahDefaultDuration;
  int get iqomahTestingDuration =>
      _settings['iqomahTestingDuration'] ?? AppConstants.iqomahTestingDuration;

  int get minutesBeforeMaghrib =>
      _settings['minutesBeforeMaghrib'] ?? AppConstants.minutesBeforeMaghrib;
  int get minutesBeforeJumat =>
      _settings['minutesBeforeJumat'] ?? AppConstants.minutesBeforeJumat;
  String get marqueeText =>
      _settings['marqueeText'] ?? AppConstants.marqueeText;

  String get backgroundImage =>
      _settings['backgroundImage'] ?? AppConstants.backgroundImage;

  List<String> get eventImages {
    if (_settings['eventImages'] != null) {
      final List<String> remoteImages = List<String>.from(
        _settings['eventImages'],
      );

      if (remoteImages.isNotEmpty) {
        return remoteImages;
      }
    }
    return AppConstants.eventImages;
  }

  Future<void> init() async {
    await loadConfig();

    Timer.periodic(const Duration(minutes: 1), (timer) async {
      await loadConfig();
    });
  }

  Future<void> loadConfig() async {
    try {
      _settings = await _service.fetchRemoteConfig();
      notifyListeners();
    } catch (e) {
      debugPrint("ConfigProvider Error: $e");
    }
  }
}
