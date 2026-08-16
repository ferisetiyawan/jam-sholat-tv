import 'package:flutter/material.dart';

import '../../domain/models/app_config.dart';
import '../../domain/models/event_image.dart';

/// Exposes the fixed, fully-offline [AppConfig] to the widget tree.
///
/// All tunables (durations, hijri correction, marquee/background fallbacks)
/// come from [AppConfig] defaults — i.e. the local [AppConstants] values. The
/// remote config fetch was removed, so this provider never changes after
/// construction; it stays a [ChangeNotifier] only to keep the existing
/// provider wiring intact.
class ConfigProvider extends ChangeNotifier {
  ConfigProvider();

  final AppConfig _config = AppConfig.defaults();

  AppConfig get config => _config;

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
}
