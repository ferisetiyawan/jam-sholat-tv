import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jam_sholat_tv/app/providers/config_provider.dart';
import 'package:jam_sholat_tv/core/constants/app_constants.dart';
import 'package:jam_sholat_tv/domain/models/app_config.dart';
import 'package:jam_sholat_tv/domain/models/financial_summary.dart';
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

    test('serves prayer-calc defaults from AppConstants', () {
      final config = ConfigProvider();

      expect(config.latitude, AppConstants.latitude);
      expect(config.longitude, AppConstants.longitude);
      expect(config.fajrAngle, AppConstants.fajrAngle);
      expect(config.ishaAngle, AppConstants.ishaAngle);
      expect(config.madhab, AppConstants.madhab.name);
      expect(config.ihtiyat, AppConstants.ihtiyat);
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

    test('load() applies persisted prayer-calc overrides', () async {
      SharedPreferences.setMockInitialValues({
        ConfigProvider.configPrefsKey: jsonEncode({
          'latitude': 3.60,
          'longitude': 98.67,
          'madhab': 'hanafi',
          'ihtiyat': {'subuh': 5},
        }),
      });

      final config = ConfigProvider();
      await config.load();

      expect(config.latitude, 3.60);
      expect(config.longitude, 98.67);
      expect(config.madhab, 'hanafi');
      expect(config.ihtiyat['subuh'], 5);
      expect(config.ihtiyat['maghrib'], AppConstants.ihtiyat['maghrib']);
      expect(config.ihtiyat, hasLength(7));
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

    test('serves the offline financial sample by default', () {
      final sample = FinancialSummary.offlineSample();
      final config = ConfigProvider();

      expect(config.financialSummary.totalKasMasjid, sample.totalKasMasjid);
      expect(config.financialSummary.saldoKasDate, sample.saldoKasDate);
      expect(config.financialSummary.weeklyIncome, hasLength(5));
    });

    test('load() applies a persisted financialSummary override', () async {
      SharedPreferences.setMockInitialValues({
        ConfigProvider.configPrefsKey: jsonEncode({
          'financialSummary': {
            'totalKasMasjid': 5000000,
            'saldoKasDate': '2026-06-04T00:00:00.000Z',
            'weeklyIncome': [
              {
                'periodeStart': '2026-05-01T00:00:00.000Z',
                'periodeEnd': '2026-05-07T00:00:00.000Z',
                'pemasukan': 750000,
              },
            ],
          },
        }),
      });

      final config = ConfigProvider();
      await config.load();

      expect(config.financialSummary.totalKasMasjid, 5000000);
      expect(config.financialSummary.weeklyIncome, hasLength(1));
      expect(config.financialSummary.weeklyIncome.first.pemasukan, 750000);
    });
  });
}
