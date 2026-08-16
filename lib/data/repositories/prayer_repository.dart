import '../services/prayer_schedule_service.dart';

/// Single source of truth for prayer schedules.
///
/// Wraps [PrayerScheduleService] (asset/API/SharedPreferences access) and
/// exposes the "today's jadwal" domain concept to the rest of the app.
class PrayerRepository {
  PrayerRepository({PrayerScheduleService? service})
      : _service = service ?? PrayerScheduleService();

  final PrayerScheduleService _service;

  /// Fetches and persists ~6 months of prayer schedules (offline-first).
  Future<void> fetchAndSaveSixMonths() => _service.fetchAndSaveSixMonths();

  /// Returns today's jadwal (prayer times) map, or `null` when unavailable.
  Future<Map<String, String>?> getTodayJadwal() =>
      _service.getTodayJadwalMap();
}
