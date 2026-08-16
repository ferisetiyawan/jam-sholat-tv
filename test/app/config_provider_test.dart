import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jam_sholat_tv/app/providers/config_provider.dart';
import 'package:jam_sholat_tv/core/constants/app_constants.dart';
import 'package:jam_sholat_tv/domain/models/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ConfigProvider', () {
    test('serves fixed AppConstants defaults (no remote config)', () {
      final config = ConfigProvider();

      expect(config.homeDuration, AppConstants.homeDuration);
      expect(config.eventDuration, AppConstants.eventDuration);
      expect(config.reportDuration, AppConstants.reportDuration);
      expect(config.adzanDuration, AppConstants.adzanDuration);
      expect(config.jumatDuration, AppConstants.jumatDuration);
      expect(config.shalatDuration, AppConstants.shalatDuration);
      expect(config.isyraqDuration, AppConstants.isyraqDuration);
      expect(config.waitingIsyraqDuration, AppConstants.waitingIsyraqDuration);
      expect(config.iqomahSubuhDuration, AppConstants.iqomahSubuhDuration);
      expect(
        config.iqomahMaghribRamadhanDuration,
        AppConstants.iqomahMaghribRamadhanDuration,
      );
      expect(config.iqomahDefaultDuration, AppConstants.iqomahDefaultDuration);
      expect(config.iqomahTestingDuration, AppConstants.iqomahTestingDuration);
      expect(config.hijriCorrection, AppConstants.hijriCorrection);
      expect(config.minutesBeforeMaghrib, AppConstants.minutesBeforeMaghrib);
      expect(config.minutesBeforeJumat, AppConstants.minutesBeforeJumat);
      expect(config.marqueeText, AppConstants.marqueeText);
      expect(config.backgroundImage, AppConstants.backgroundImage);
      expect(
        config.enableFinancialReport,
        AppConstants.enableFinancialReport,
      );
    });

    test('event images are empty (announcements disabled)', () {
      expect(ConfigProvider().eventImages, isEmpty);
    });

    test('load() merges persisted overrides over AppConstants', () async {
      SharedPreferences.setMockInitialValues({
        ConfigProvider.configPrefsKey:
            jsonEncode({'homeDuration': 5, 'marqueeText': 'hai'}),
      });

      final config = ConfigProvider();
      expect(config.homeDuration, AppConstants.homeDuration);

      await config.load();

      expect(config.homeDuration, 5);
      expect(config.marqueeText, 'hai');
      // Fields not persisted fall back to defaults.
      expect(config.adzanDuration, AppConstants.adzanDuration);
    });

    test('load() falls back to defaults when nothing is saved', () async {
      SharedPreferences.setMockInitialValues({});

      final config = ConfigProvider();
      await config.load();

      expect(config.homeDuration, AppConstants.homeDuration);
      expect(config.marqueeText, AppConstants.marqueeText);
    });

    test('applyConfig() hot-applies and notifies listeners', () {
      final config = ConfigProvider();
      var notifications = 0;
      config.addListener(() => notifications++);

      config.applyConfig(
        AppConfig.fromJson({'homeDuration': 9, 'marqueeText': 'baru'}),
      );

      expect(config.homeDuration, 9);
      expect(config.marqueeText, 'baru');
      expect(notifications, 1);
    });
  });
}
