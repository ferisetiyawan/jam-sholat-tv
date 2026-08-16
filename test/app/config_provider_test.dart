import 'package:flutter_test/flutter_test.dart';
import 'package:jam_sholat_tv/app/providers/config_provider.dart';
import 'package:jam_sholat_tv/core/constants/app_constants.dart';

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
  });
}
