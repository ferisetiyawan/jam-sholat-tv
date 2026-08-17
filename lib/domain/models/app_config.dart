import 'dart:math' as math;

import '../../core/constants/app_constants.dart';
import 'event_image.dart';
import 'financial_summary.dart';

/// Merged runtime configuration: remote (Google Apps Script) values over the
/// [AppConstants] defaults.
///
/// This is the single typed representation of every tunable duration, text and
/// media setting the app reads. Every field falls back to its [AppConstants]
/// default when absent from the remote payload, so `AppConfig.fromJson({})`
/// yields a fully usable default config.
class AppConfig {
  /// Name of the masjid shown on the display screens. Editable at runtime
  /// through the local config server's "Identitas Masjid" dashboard; an empty
  /// saved value falls back to [AppConstants.masjidName].
  final String masjidName;

  /// Address/location shown under the masjid name on the home screen. Editable
  /// at runtime through the local config server's "Identitas Masjid"
  /// dashboard; an empty saved value falls back to [AppConstants.locationName].
  final String locationName;

  // Durations below marked "minutes" are configured and stored in minutes
  // (converted to seconds when the countdown runs); the rest stay in seconds.
  final int homeDuration;
  final int eventDuration;
  final int reportDuration;

  /// Adzan screen length, in minutes.
  final int adzanDuration;

  /// Jumat mode screen length, in minutes.
  final int jumatDuration;

  /// Shalat screen length, in minutes.
  final int shalatDuration;

  /// Isyraq screen length, in minutes.
  final int isyraqDuration;

  /// Hijri date correction in days, clamped to `[-2, 2]`.
  final int hijriCorrection;

  /// Hijri calendar used to render the displayed date: `'umum'` (location-based,
  /// local rukyat) or `'khgt'` (Kalender Hijriah Global Tunggal). When `'khgt'`,
  /// [hijriCorrection] is ignored because KHGT yields one global date for all
  /// locations. Editable at runtime through the local config server's "Kalender
  /// Hijriah" dashboard; an unknown value falls back to
  /// [AppConstants.hijriKalender].
  final String hijriKalender;

  /// Minutes between Syuruq and the Isyraq screen.
  final int waitingIsyraqDuration;

  /// Iqomah wait before Subuh, in minutes.
  final int iqomahSubuhDuration;

  /// Iqomah wait before Maghrib during Ramadhan, in minutes.
  final int iqomahMaghribRamadhanDuration;

  /// Iqomah wait for every other prayer, in minutes.
  final int iqomahDefaultDuration;

  /// Seconds the iqomah stage lasts in debug builds only (hidden from the
  /// config dashboard; never used in release builds).
  final int iqomahTestingDuration;

  final int minutesBeforeMaghrib;
  final int minutesBeforeJumat;

  /// YouTube URL of the live Makkah stream shown before Maghrib/Jumat. Editable
  /// at runtime; a bad or empty value falls back to [AppConstants.liveMakkahUrl]
  /// in the player.
  final String liveMakkahUrl;

  /// Prayer-calculation parameters, all editable at runtime through the local
  /// config server and used by [CalculatePrayerTimes].
  final double latitude;
  final double longitude;
  final double fajrAngle;
  final double ishaAngle;

  /// Whether the masjid's elevation above sea level is folded into the Syuruq
  /// and Maghrib calculation. Defaults to off; toggled from the config
  /// dashboard ("Gunakan elevasi"). When off, [elevationMeters] is stored but
  /// ignored, so picking a city never silently changes the schedule.
  final bool useElevation;

  /// Masjid elevation above sea level in meters (clamped to `>= 0`). Filled
  /// automatically when a city is picked from the dashboard's "Pilih Kota"
  /// list. Only affects the calculation when [useElevation] is enabled.
  final double elevationMeters;

  /// Prayer-calculation method, one of [AppConstants.calculationMethodNames]:
  /// `'kemenag'` (Subuh 20°, Isya 18°), `'muhammadiyah'` (MTT PP Muhammadiyah,
  /// 18°/18°) or `'kustom'` (uses the stored [fajrAngle]/[ishaAngle]). For the
  /// two presets the angles in effect come from [effectiveFajrAngle] /
  /// [effectiveIshaAngle] and cannot be changed at runtime; an unknown value
  /// falls back to [AppConstants.calculationMethod].
  final String calculationMethod;

  /// Serialized madhab name (one of [AppConstants.madhabNames], e.g.
  /// `'shafi'`/`'hanafi'`). Kept as a String so `domain/` stays free of the
  /// adhan_dart import; the calculator maps it back to the enum. Only affects
  /// the Ashar time.
  final String madhab;

  /// Fajr angle in effect, derived from [calculationMethod]: the two presets
  /// pin the official angle (so a stale saved angle can never drift the
  /// schedule) while `'kustom'` returns the stored [fajrAngle].
  double get effectiveFajrAngle {
    switch (calculationMethod) {
      case 'kemenag':
        return AppConstants.fajrAngle;
      case 'muhammadiyah':
        return AppConstants.muhammadiyahFajrAngle;
      default:
        return fajrAngle;
    }
  }

  /// Isya angle in effect; see [effectiveFajrAngle].
  double get effectiveIshaAngle {
    switch (calculationMethod) {
      case 'kemenag':
        return AppConstants.ishaAngle;
      case 'muhammadiyah':
        return AppConstants.muhammadiyahIshaAngle;
      default:
        return ishaAngle;
    }
  }

  /// Dip of the astronomical horizon (degrees) seen from [elevationMeters]
  /// above sea level, or `0.0` at/under sea level.
  ///
  /// Rising from sea level, the horizon drops by this angle — at 100 m it is
  /// ~0.32°, worth roughly a minute of time. The elevation correction re-uses
  /// it on the *rising/setting* edges only (Syuruq and Maghrib), because
  /// Kemenag and Muhammadiyah both define Subuh/Isya as fixed depression angles
  /// measured from the (sea-level) horizon — the dip is not applied to them.
  static double horizonDip(double elevationMeters) {
    if (elevationMeters <= 0) return 0.0;
    const double earthRadiusMeters = 6371000.0;
    final double dipRadians =
        math.acos(earthRadiusMeters / (earthRadiusMeters + elevationMeters));
    return dipRadians * 180.0 / math.pi;
  }

  /// Per-prayer ihtiyat (minutes) keyed by the Kemenag names. Always carries
  /// all seven keys (`imsak, subuh, terbit, dhuhur, ashar, maghrib, isya`);
  /// `terbit` may be negative.
  final Map<String, int> ihtiyat;
  final String marqueeText;
  final String backgroundImage;
  final List<EventImage> eventImages;

  /// Whether the financial report is shown during the home idle cycle.
  final bool enableFinancialReport;

  /// The monthly kas report rendered on the financial screen. Defaults to the
  /// offline sample; editable at runtime through the local config server.
  final FinancialSummary financialSummary;

  /// Device role: `'standalone'` (default), `'master'`, or `'follower'`.
  /// - `master`: exposes `/api/config/public` so followers can sync.
  /// - `follower`: polls `masterUrl` every 30 s and applies the config.
  final String deviceRole;

  /// The base URL of the master device (e.g. `http://192.168.10.5:8080`).
  /// Only used when [deviceRole] is `'follower'`.
  final String masterUrl;

  const AppConfig({
    required this.masjidName,
    required this.locationName,
    required this.homeDuration,
    required this.eventDuration,
    required this.reportDuration,
    required this.adzanDuration,
    required this.jumatDuration,
    required this.shalatDuration,
    required this.isyraqDuration,
    required this.hijriCorrection,
    required this.hijriKalender,
    required this.waitingIsyraqDuration,
    required this.iqomahSubuhDuration,
    required this.iqomahMaghribRamadhanDuration,
    required this.iqomahDefaultDuration,
    required this.iqomahTestingDuration,
    required this.minutesBeforeMaghrib,
    required this.minutesBeforeJumat,
    required this.liveMakkahUrl,
    required this.latitude,
    required this.longitude,
    required this.fajrAngle,
    required this.ishaAngle,
    required this.useElevation,
    required this.elevationMeters,
    required this.calculationMethod,
    required this.madhab,
    required this.ihtiyat,
    required this.marqueeText,
    required this.backgroundImage,
    required this.eventImages,
    required this.enableFinancialReport,
    required this.financialSummary,
    required this.deviceRole,
    required this.masterUrl,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value, int fallback) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    bool parseBool(dynamic value, bool fallback) {
      if (value is bool) return value;
      final String? raw = value?.toString().toLowerCase();
      return raw == null ? fallback : raw == 'true';
    }

    double parseDouble(dynamic value, double fallback) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? fallback;
    }

    String parseMadhab(dynamic value) {
      final String raw = value?.toString().toLowerCase() ?? '';
      return AppConstants.madhabNames.contains(raw)
          ? raw
          : AppConstants.madhab.name;
    }

    String parseKalender(dynamic value) {
      final String raw = value?.toString().toLowerCase() ?? '';
      return AppConstants.hijriKalenderNames.contains(raw)
          ? raw
          : AppConstants.hijriKalender;
    }

    String parseCalculationMethod(dynamic value) {
      final String raw = value?.toString().toLowerCase() ?? '';
      return AppConstants.calculationMethodNames.contains(raw)
          ? raw
          : AppConstants.calculationMethod;
    }

    String parseName(dynamic value, String fallback) {
      final String raw = value?.toString().trim() ?? '';
      return raw.isEmpty ? fallback : raw;
    }

    Map<String, int> parseIhtiyat(dynamic value) {
      // Start from the full Kemenag default map so every lookup in the
      // calculator is always non-null, then overlay saved per-key values.
      final Map<String, int> result = Map<String, int>.from(
        AppConstants.ihtiyat,
      );
      if (value is Map) {
        for (final MapEntry<dynamic, dynamic> entry in value.entries) {
          final int? parsed = entry.value is num
              ? (entry.value as num).toInt()
              : int.tryParse(entry.value.toString());
          if (parsed != null) {
            result[entry.key.toString()] = parsed;
          }
        }
      }
      return result;
    }

    FinancialSummary parseFinancialSummary(dynamic value) {
      if (value is Map<String, dynamic>) {
        return FinancialSummary.fromJson(value);
      }
      // Handles non-generic maps (e.g. a Map<dynamic, dynamic>); the editor
      // always sends the full object, so a missing key falls back to the
      // offline sample like every other unset field.
      if (value is Map) {
        return FinancialSummary.fromJson(Map<String, dynamic>.from(value));
      }
      return FinancialSummary.offlineSample();
    }

    final rawImages = json['eventImages'];
    final List<EventImage> images = rawImages is List && rawImages.isNotEmpty
        ? rawImages
            .map((item) => EventImage.fromJson(item as Map<String, dynamic>))
            .toList()
        : const [];

    return AppConfig(
      masjidName: parseName(json['masjidName'], AppConstants.masjidName),
      locationName: parseName(json['locationName'], AppConstants.locationName),
      homeDuration: parseInt(json['homeDuration'], AppConstants.homeDuration),
      eventDuration: parseInt(json['eventDuration'], AppConstants.eventDuration),
      reportDuration: parseInt(json['reportDuration'], AppConstants.reportDuration),
      adzanDuration: parseInt(json['adzanDuration'], AppConstants.adzanDuration),
      jumatDuration: parseInt(json['jumatDuration'], AppConstants.jumatDuration),
      shalatDuration: parseInt(json['shalatDuration'], AppConstants.shalatDuration),
      isyraqDuration: parseInt(json['isyraqDuration'], AppConstants.isyraqDuration),
      hijriCorrection: parseInt(
        json['hijriCorrection'],
        AppConstants.hijriCorrection,
      ).clamp(-2, 2),
      hijriKalender: parseKalender(json['hijriKalender']),
      waitingIsyraqDuration: parseInt(
        json['waitingIsyraqDuration'],
        AppConstants.waitingIsyraqDuration,
      ),
      iqomahSubuhDuration: parseInt(
        json['iqomahSubuhDuration'],
        AppConstants.iqomahSubuhDuration,
      ),
      iqomahMaghribRamadhanDuration: parseInt(
        json['iqomahMaghribRamadhanDuration'],
        AppConstants.iqomahMaghribRamadhanDuration,
      ),
      iqomahDefaultDuration: parseInt(
        json['iqomahDefaultDuration'],
        AppConstants.iqomahDefaultDuration,
      ),
      iqomahTestingDuration: parseInt(
        json['iqomahTestingDuration'],
        AppConstants.iqomahTestingDuration,
      ),
      minutesBeforeMaghrib: parseInt(
        json['minutesBeforeMaghrib'],
        AppConstants.minutesBeforeMaghrib,
      ),
      minutesBeforeJumat: parseInt(
        json['minutesBeforeJumat'],
        AppConstants.minutesBeforeJumat,
      ),
      liveMakkahUrl:
          json['liveMakkahUrl']?.toString() ?? AppConstants.liveMakkahUrl,
      latitude: parseDouble(json['latitude'], AppConstants.latitude)
          .clamp(-90.0, 90.0)
          .toDouble(),
      longitude: parseDouble(
        json['longitude'],
        AppConstants.longitude,
      ).clamp(-180.0, 180.0).toDouble(),
      fajrAngle: parseDouble(json['fajrAngle'], AppConstants.fajrAngle),
      ishaAngle: parseDouble(json['ishaAngle'], AppConstants.ishaAngle),
      useElevation: parseBool(json['useElevation'], AppConstants.useElevation),
      elevationMeters: parseDouble(
        json['elevationMeters'],
        AppConstants.elevationMeters,
      )
          .clamp(0.0, double.infinity)
          .toDouble(),
      calculationMethod: parseCalculationMethod(json['calculationMethod']),
      madhab: parseMadhab(json['madhab']),
      ihtiyat: parseIhtiyat(json['ihtiyat']),
      marqueeText: json['marqueeText']?.toString() ?? AppConstants.marqueeText,
      backgroundImage:
          json['backgroundImage']?.toString() ?? AppConstants.backgroundImage,
      eventImages: images,
      enableFinancialReport: parseBool(
        json['enableFinancialReport'],
        AppConstants.enableFinancialReport,
      ),
      financialSummary: parseFinancialSummary(json['financialSummary']),
      deviceRole: () {
        const valid = ['standalone', 'master', 'follower'];
        final v = json['deviceRole']?.toString() ?? 'standalone';
        return valid.contains(v) ? v : 'standalone';
      }(),
      masterUrl: json['masterUrl']?.toString() ?? '',
    );
  }

  /// A config populated entirely from [AppConstants] defaults.
  factory AppConfig.defaults() => AppConfig.fromJson(const {});

  Map<String, dynamic> toJson() {
    return {
      'masjidName': masjidName,
      'locationName': locationName,
      'homeDuration': homeDuration,
      'eventDuration': eventDuration,
      'reportDuration': reportDuration,
      'adzanDuration': adzanDuration,
      'jumatDuration': jumatDuration,
      'shalatDuration': shalatDuration,
      'isyraqDuration': isyraqDuration,
      'hijriCorrection': hijriCorrection,
      'hijriKalender': hijriKalender,
      'waitingIsyraqDuration': waitingIsyraqDuration,
      'iqomahSubuhDuration': iqomahSubuhDuration,
      'iqomahMaghribRamadhanDuration': iqomahMaghribRamadhanDuration,
      'iqomahDefaultDuration': iqomahDefaultDuration,
      'iqomahTestingDuration': iqomahTestingDuration,
      'minutesBeforeMaghrib': minutesBeforeMaghrib,
      'minutesBeforeJumat': minutesBeforeJumat,
      'liveMakkahUrl': liveMakkahUrl,
      'latitude': latitude,
      'longitude': longitude,
      'fajrAngle': fajrAngle,
      'ishaAngle': ishaAngle,
      'useElevation': useElevation,
      'elevationMeters': elevationMeters,
      'calculationMethod': calculationMethod,
      'madhab': madhab,
      'ihtiyat': ihtiyat,
      'marqueeText': marqueeText,
      'backgroundImage': backgroundImage,
      'eventImages': eventImages.map((e) => e.toJson()).toList(),
      'enableFinancialReport': enableFinancialReport,
      'financialSummary': financialSummary.toJson(),
      'deviceRole': deviceRole,
      'masterUrl': masterUrl,
    };
  }
}
