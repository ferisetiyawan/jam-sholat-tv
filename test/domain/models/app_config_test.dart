import 'package:flutter_test/flutter_test.dart';
import 'package:jam_sholat_tv/core/constants/app_constants.dart';
import 'package:jam_sholat_tv/domain/models/app_config.dart';
import 'package:jam_sholat_tv/domain/models/financial_summary.dart';

void main() {
  group('AppConfig', () {
    test('defaults() is populated from AppConstants', () {
      final config = AppConfig.defaults();

      expect(config.masjidName, AppConstants.masjidName);
      expect(config.locationName, AppConstants.locationName);
      expect(config.homeDuration, AppConstants.homeDuration);
      expect(config.adzanDuration, AppConstants.adzanDuration);
      expect(config.jumatDuration, AppConstants.jumatDuration);
      expect(config.hijriCorrection, AppConstants.hijriCorrection);
      expect(config.hijriKalender, AppConstants.hijriKalender);
      expect(config.marqueeText, AppConstants.marqueeText);
      expect(config.backgroundImage, AppConstants.backgroundImage);
      expect(config.eventImages, isEmpty);
    });

    test('fromJson merges remote values over defaults', () {
      final config = AppConfig.fromJson({
        'homeDuration': 5,
        'hijriCorrection': 0,
        'marqueeText': 'Selamat datang',
      });

      expect(config.homeDuration, 5);
      expect(config.hijriCorrection, 0);
      expect(config.marqueeText, 'Selamat datang');
      // Unset keys fall back to defaults.
      expect(config.adzanDuration, AppConstants.adzanDuration);
      expect(config.masjidName, AppConstants.masjidName);
      expect(config.locationName, AppConstants.locationName);
    });

    test('identity fields override from JSON and fall back when empty', () {
      expect(
        AppConfig.fromJson({'masjidName': 'Masjid An-Nur'}).masjidName,
        'Masjid An-Nur',
      );
      expect(
        AppConfig.fromJson({'locationName': 'Jl. Merdeka No. 1'}).locationName,
        'Jl. Merdeka No. 1',
      );
      expect(AppConfig.fromJson({'masjidName': '   '}).masjidName,
          AppConstants.masjidName);
      expect(AppConfig.fromJson({'locationName': '   '}).locationName,
          AppConstants.locationName);
      expect(AppConfig.fromJson({}).masjidName, AppConstants.masjidName);
      expect(AppConfig.fromJson({}).locationName, AppConstants.locationName);
    });

    test('clamps hijriCorrection to [-2, 2]', () {
      expect(AppConfig.fromJson({'hijriCorrection': 9}).hijriCorrection, 2);
      expect(AppConfig.fromJson({'hijriCorrection': -9}).hijriCorrection, -2);
      expect(AppConfig.fromJson({'hijriCorrection': 1}).hijriCorrection, 1);
    });

    test('hijriKalender is normalized and falls back on unknown values', () {
      expect(AppConfig.fromJson({'hijriKalender': 'KHGT'}).hijriKalender, 'khgt');
      expect(AppConfig.fromJson({'hijriKalender': 'bogus'}).hijriKalender,
          AppConstants.hijriKalender);
      expect(AppConfig.fromJson({'hijriKalender': ''}).hijriKalender,
          AppConstants.hijriKalender);
      expect(AppConfig.fromJson({}).hijriKalender, AppConstants.hijriKalender);
    });

    test('parses event images and defaults to empty list', () {
      final config = AppConfig.fromJson({
        'eventImages': [
          {'type': 'image', 'url': 'https://example.com/a.png'},
          {'type': 'SVG', 'url': 'assets/b.svg'},
        ],
      });

      expect(config.eventImages, hasLength(2));
      expect(config.eventImages.first.type, 'IMAGE');
      expect(config.eventImages.first.url, 'https://example.com/a.png');
      expect(config.eventImages.last.type, 'SVG');

      expect(AppConfig.defaults().eventImages, isEmpty);
    });

    test('enableFinancialReport defaults on, parses explicit values', () {
      expect(AppConfig.defaults().enableFinancialReport, true);
      expect(AppConfig.fromJson({}).enableFinancialReport, true);
      expect(
        AppConfig.fromJson({'enableFinancialReport': false})
            .enableFinancialReport,
        false,
      );
      expect(
        AppConfig.fromJson({'enableFinancialReport': 'false'})
            .enableFinancialReport,
        false,
      );
    });

    test('round-trips through toJson/fromJson', () {
      final original = AppConfig.fromJson({
        'masjidName': 'Masjid An-Nur',
        'locationName': 'Jl. Merdeka No. 1',
        'homeDuration': 7,
        'hijriCorrection': 1,
        'hijriKalender': 'khgt',
        'eventImages': [
          {'type': 'image', 'url': 'assets/a.png'},
        ],
      });

      final restored = AppConfig.fromJson(original.toJson());

      expect(restored.masjidName, 'Masjid An-Nur');
      expect(restored.locationName, 'Jl. Merdeka No. 1');
      expect(restored.homeDuration, 7);
      expect(restored.hijriCorrection, 1);
      expect(restored.hijriKalender, 'khgt');
      expect(restored.eventImages, hasLength(1));
      expect(restored.eventImages.first.type, 'IMAGE');
      expect(restored.eventImages.first.url, 'assets/a.png');
    });

    test('prayer-calc fields default to AppConstants', () {
      final config = AppConfig.defaults();

      expect(config.latitude, AppConstants.latitude);
      expect(config.longitude, AppConstants.longitude);
      expect(config.fajrAngle, AppConstants.fajrAngle);
      expect(config.ishaAngle, AppConstants.ishaAngle);
      expect(config.madhab, AppConstants.madhab.name);
      expect(config.ihtiyat, AppConstants.ihtiyat);
    });

    test('fromJson overrides location, angles, madhab and ihtiyat', () {
      final config = AppConfig.fromJson({
        'latitude': 3.60,
        'longitude': 98.67,
        'fajrAngle': 19.5,
        'ishaAngle': 17.0,
        'madhab': 'hanafi',
        'ihtiyat': {'subuh': 5, 'isya': 7},
      });

      expect(config.latitude, 3.60);
      expect(config.longitude, 98.67);
      expect(config.fajrAngle, 19.5);
      expect(config.ishaAngle, 17.0);
      expect(config.madhab, 'hanafi');
      expect(config.ihtiyat['subuh'], 5);
      expect(config.ihtiyat['isya'], 7);
    });

    test('ihtiyat merges partially over the full default map', () {
      final config = AppConfig.fromJson({'ihtiyat': {'subuh': 5}});

      expect(config.ihtiyat, hasLength(7));
      expect(config.ihtiyat['subuh'], 5);
      expect(config.ihtiyat['maghrib'], AppConstants.ihtiyat['maghrib']);
      expect(config.ihtiyat['terbit'], AppConstants.ihtiyat['terbit']);
    });

    test('madhab is normalized and falls back on unknown values', () {
      expect(AppConfig.fromJson({'madhab': 'HANAFI'}).madhab, 'hanafi');
      expect(AppConfig.fromJson({'madhab': 'bogus'}).madhab,
          AppConstants.madhab.name);
      expect(AppConfig.fromJson({'madhab': ''}).madhab,
          AppConstants.madhab.name);
    });

    test('clamps latitude and longitude on parse', () {
      expect(AppConfig.fromJson({'latitude': 91}).latitude, 90.0);
      expect(AppConfig.fromJson({'latitude': -91}).latitude, -90.0);
      expect(AppConfig.fromJson({'longitude': 181}).longitude, 180.0);
      expect(AppConfig.fromJson({'longitude': -181}).longitude, -180.0);
    });

    test('round-trips prayer-calc fields through toJson/fromJson', () {
      final original = AppConfig.fromJson({
        'latitude': 3.60,
        'madhab': 'hanafi',
        'ihtiyat': {'subuh': 5},
      });

      final restored = AppConfig.fromJson(original.toJson());

      expect(restored.latitude, 3.60);
      expect(restored.longitude, AppConstants.longitude);
      expect(restored.madhab, 'hanafi');
      expect(restored.ihtiyat['subuh'], 5);
      expect(restored.ihtiyat['maghrib'], AppConstants.ihtiyat['maghrib']);
    });

    test('financialSummary defaults to the offline sample', () {
      final sample = FinancialSummary.offlineSample();
      final config = AppConfig.defaults();

      expect(config.financialSummary.totalKasMasjid, sample.totalKasMasjid);
      expect(config.financialSummary.saldoKasDate, sample.saldoKasDate);
      expect(config.financialSummary.weeklyIncome, hasLength(5));
      expect(AppConfig.fromJson({}).financialSummary.totalKasMasjid,
          sample.totalKasMasjid);
    });

    test('fromJson parses a provided financialSummary', () {
      final config = AppConfig.fromJson({
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
      });

      expect(config.financialSummary.totalKasMasjid, 5000000);
      expect(config.financialSummary.weeklyIncome, hasLength(1));
      expect(config.financialSummary.weeklyIncome.first.pemasukan, 750000);
    });

    test('round-trips financialSummary through toJson/fromJson', () {
      final original = AppConfig.fromJson({
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
      });

      final restored = AppConfig.fromJson(original.toJson());

      expect(restored.financialSummary.totalKasMasjid, 5000000);
      expect(restored.financialSummary.weeklyIncome, hasLength(1));
      expect(restored.financialSummary.weeklyIncome.first.pemasukan, 750000);
      expect(
        restored.financialSummary.weeklyIncome.first.periodeStart,
        DateTime.parse('2026-05-01T00:00:00.000Z'),
      );
    });
  });
}
