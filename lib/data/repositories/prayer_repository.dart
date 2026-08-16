import '../../domain/models/app_config.dart';
import '../../domain/use_cases/calculate_prayer_times.dart';

/// Single source of truth for the prayer schedule.
///
/// Prayer times are computed fully on-device (Kemenag method) by
/// [CalculatePrayerTimes] — no network, bundled assets, or cache involved.
class PrayerRepository {
  PrayerRepository({CalculatePrayerTimes? calculator})
      : _calculator = calculator ?? const CalculatePrayerTimes();

  final CalculatePrayerTimes _calculator;

  /// Returns today's jadwal (prayer times) map, computed locally for [now]
  /// (defaults to `DateTime.now()`). Pass [config] to use runtime-editable
  /// calc parameters (location/madhab/ihtiyat); omitted uses [AppConstants].
  Map<String, String> getTodayJadwal({DateTime? now, AppConfig? config}) =>
      _calculator(now: now, config: config);
}
