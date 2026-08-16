import 'package:flutter_test/flutter_test.dart';
import 'package:jam_sholat_tv/core/constants/app_constants.dart';
import 'package:jam_sholat_tv/domain/models/app_config.dart';

void main() {
  group('AppConfig', () {
    test('defaults() is populated from AppConstants', () {
      final config = AppConfig.defaults();

      expect(config.homeDuration, AppConstants.homeDuration);
      expect(config.adzanDuration, AppConstants.adzanDuration);
      expect(config.jumatDuration, AppConstants.jumatDuration);
      expect(config.hijriCorrection, AppConstants.hijriCorrection);
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
    });

    test('clamps hijriCorrection to [-2, 2]', () {
      expect(AppConfig.fromJson({'hijriCorrection': 9}).hijriCorrection, 2);
      expect(AppConfig.fromJson({'hijriCorrection': -9}).hijriCorrection, -2);
      expect(AppConfig.fromJson({'hijriCorrection': 1}).hijriCorrection, 1);
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
        'homeDuration': 7,
        'hijriCorrection': 1,
        'eventImages': [
          {'type': 'image', 'url': 'assets/a.png'},
        ],
      });

      final restored = AppConfig.fromJson(original.toJson());

      expect(restored.homeDuration, 7);
      expect(restored.hijriCorrection, 1);
      expect(restored.eventImages, hasLength(1));
      expect(restored.eventImages.first.type, 'IMAGE');
      expect(restored.eventImages.first.url, 'assets/a.png');
    });
  });
}
