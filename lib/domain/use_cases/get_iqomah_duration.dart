import 'package:hijriyah_indonesia/hijriyah_indonesia.dart';

import '../../core/constants/app_constants.dart';
import '../models/app_config.dart';

/// Selects how long the iqomah stage lasts for a given prayer, in MINUTES.
///
/// Rules: Subuh = `config.iqomahSubuhDuration`; Maghrib during Ramadhan (hijri
/// month 9) = `config.iqomahMaghribRamadhanDuration`; everything else =
/// `config.iqomahDefaultDuration`. All three come from the runtime config
/// (defaults 15 / 15 / 10 minutes) so the dashboard edits take effect. In debug
/// builds a few seconds are used to speed up testing.
class GetIqomahDuration {
  int call(String prayerName, AppConfig config) {
    if (AppConstants.isDebug) return AppConstants.iqomahTestingDuration;

    final hijri = Hijriyah.now();
    final bool isRamadhan = hijri.hMonth == AppConstants.monthOfRamadhan;

    if (prayerName == "Subuh") {
      return config.iqomahSubuhDuration;
    } else if (prayerName == "Maghrib" && isRamadhan) {
      return config.iqomahMaghribRamadhanDuration;
    } else {
      return config.iqomahDefaultDuration;
    }
  }
}
