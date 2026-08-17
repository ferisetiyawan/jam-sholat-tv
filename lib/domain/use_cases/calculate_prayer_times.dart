import 'package:adhan_dart/adhan_dart.dart';

import '../../core/constants/app_constants.dart';
import '../models/app_config.dart';

/// Computes today's prayer schedule fully on-device (Kemenag method) using
/// [adhan_dart].
///
/// Returns the canonical jadwal map in insertion order:
/// `Subuh`, `Syuruq`, `Dzuhur`, `Ashar`, `Maghrib`, `Isya` with `HH:mm`
/// values. Imsak is intentionally NOT emitted — the app's jadwal contract has
/// no imsak slot (the `ihtiyat['imsak']` constant is kept for reference).
///
/// Ihtiyat is applied exactly like the Kemenag reference: the raw time is
/// shifted by the per-prayer minutes, then leftover seconds are rounded up to
/// the next minute (ceil) for the five salat times and dropped (floor) for
/// terbit/Syuruq.
class CalculatePrayerTimes {
  const CalculatePrayerTimes();

  /// [now] is injectable for deterministic testing; defaults to `DateTime.now()`.
  ///
  /// Pass an [AppConfig] to use runtime-editable calc parameters (location,
  /// angles, madhab, ihtiyat); when omitted the [AppConstants] defaults are
  /// used unchanged.
  Map<String, String> call({DateTime? now, AppConfig? config}) {
    final date = now ?? DateTime.now();

    final double latitude = config?.latitude ?? AppConstants.latitude;
    final double longitude = config?.longitude ?? AppConstants.longitude;
    // The presets (Kemenag / Muhammadiyah) resolve through the effective
    // getters, so their angles are pinned regardless of stale saved values.
    final double fajrAngle =
        config?.effectiveFajrAngle ?? AppConstants.fajrAngle;
    final double ishaAngle =
        config?.effectiveIshaAngle ?? AppConstants.ishaAngle;
    final Madhab madhab = _madhabFrom(config?.madhab);
    final Map<String, int> ihtiyat = config?.ihtiyat ?? AppConstants.ihtiyat;

    // Elevation (when explicitly enabled) dips the observer's horizon, so the
    // rising/setting edges move: Syuruq lands earlier and Maghrib later. The
    // Subuh/Isya depression angles are published from the sea-level horizon
    // (Kemenag & Muhammadiyah) and are deliberately left untouched.
    final bool useElevation =
        (config?.useElevation ?? false) && (config?.elevationMeters ?? 0) > 0;

    final params = CalculationMethodParameters.other()
      ..fajrAngle = fajrAngle
      ..ishaAngle = ishaAngle
      ..madhab = madhab;

    final times = PrayerTimes(
      coordinates: Coordinates(latitude, longitude),
      date: DateTime.utc(date.year, date.month, date.day),
      calculationParameters: params,
      precision: true,
    );

    // The dip shifts Maghrib later by the same amount Syuruq shifts earlier:
    // both are the same solar-altitude crossing (-0.833°), symmetric about
    // solar transit, so a deeper horizon angle moves them by an equal duration.
    // adhan_dart's `maghribAngle` pushes the setting edge out directly; the
    // rising edge is derived from that shift. (This is exact to the second —
    // adhan keeps sub-minute precision with `precision: true`.)
    DateTime syuruq = times.sunrise;
    DateTime maghrib = times.maghrib;
    if (useElevation) {
      final double dip = AppConfig.horizonDip(config!.elevationMeters);
      final elevated = PrayerTimes(
        coordinates: Coordinates(latitude, longitude),
        date: DateTime.utc(date.year, date.month, date.day),
        calculationParameters: params
          ..maghribAngle = AppConstants.sunsetAngle + dip,
        precision: true,
      );
      // The elevated setting edge is Maghrib itself; the rising edge moves by
      // the same duration (equal solar-altitude crossing, symmetric about
      // solar transit).
      maghrib = elevated.maghrib;
      syuruq = times.sunrise.subtract(maghrib.difference(times.maghrib));
    }

    // Formats a raw (UTC) prayer time into "HH:mm" after applying [ihtiyat]
    // minutes. `ceil` rounds leftover seconds up (salat); false drops them
    // (terbit/Syuruq). Reading `.toLocal()` keeps times on the device wall
    // clock, matching the app's `timeString`.
    String fmt(DateTime raw, int ihtiyatMinutes, {bool ceil = true}) {
      final local = raw.toLocal();
      var totalSeconds = local.hour * 3600 + local.minute * 60 + local.second;
      totalSeconds += ihtiyatMinutes * 60;
      if (ceil && totalSeconds % 60 != 0) {
        totalSeconds += 60 - (totalSeconds % 60);
      }
      final m = totalSeconds ~/ 60;
      final h = ((m ~/ 60) % 24).toString().padLeft(2, '0');
      final min = (m % 60).toString().padLeft(2, '0');
      return '$h:$min';
    }

    return {
      "Subuh": fmt(times.fajr, ihtiyat['subuh']!),
      "Syuruq": fmt(
        syuruq,
        ihtiyat['terbit']!,
        ceil: false,
      ),
      "Dzuhur": fmt(times.dhuhr, ihtiyat['dhuhur']!),
      "Ashar": fmt(times.asr, ihtiyat['ashar']!),
      "Maghrib": fmt(maghrib, ihtiyat['maghrib']!),
      "Isya": fmt(times.isha, ihtiyat['isya']!),
    };
  }

  /// Maps a serialized madhab name (e.g. `'hanafi'`) back to the adhan_dart
  /// enum, falling back to the [AppConstants] default for unknown values.
  Madhab _madhabFrom(String? name) {
    if (name == null) return AppConstants.madhab;
    return Madhab.values.firstWhere(
      (m) => m.name == name,
      orElse: () => AppConstants.madhab,
    );
  }
}
