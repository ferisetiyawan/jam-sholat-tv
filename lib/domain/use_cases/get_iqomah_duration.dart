import 'package:hijriyah_indonesia/hijriyah_indonesia.dart';

import '../../core/constants/app_constants.dart';

/// Selects how long the iqomah stage lasts for a given prayer.
///
/// Rules: Subuh = 15 minutes; Maghrib during Ramadhan (hijri month 9) = 15
/// minutes; everything else = 10 minutes. In debug builds a few seconds are
/// used to speed up testing.
class GetIqomahDuration {
  int call(String prayerName) {
    if (AppConstants.isDebug) return AppConstants.iqomahTestingDuration;

    final hijri = Hijriyah.now();
    bool isRamadhan = hijri.hMonth == AppConstants.monthOfRamadhan;

    if (prayerName == "Subuh") {
      return AppConstants.iqomahSubuhDuration;
    } else if (prayerName == "Maghrib" && isRamadhan) {
      return AppConstants.iqomahMaghribRamadhanDuration;
    } else {
      return AppConstants.iqomahDefaultDuration;
    }
  }
}
