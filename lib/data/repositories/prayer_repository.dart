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
  /// (defaults to `DateTime.now()`).
  Map<String, String> getTodayJadwal({DateTime? now}) => _calculator(now: now);
}
