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
  final int homeDuration;
  final int eventDuration;
  final int reportDuration;
  final int adzanDuration;
  final int jumatDuration;
  final int shalatDuration;
  final int isyraqDuration;

  /// Hijri date correction in days, clamped to `[-2, 2]`.
  final int hijriCorrection;
  final int waitingIsyraqDuration;
  final int iqomahSubuhDuration;
  final int iqomahMaghribRamadhanDuration;
  final int iqomahDefaultDuration;
  final int iqomahTestingDuration;

  final int minutesBeforeMaghrib;
  final int minutesBeforeJumat;

  /// YouTube URL of the live Makkah stream shown before Maghrib/Jumat. Editable
  /// at runtime; a bad or empty value falls back to [AppConstants.liveMakkahUrl]
  /// in the player.
  final String liveMakkahUrl;

  /// Prayer-calculation parameters (Kemenag method), all editable at runtime
  /// through the local config server and used by [CalculatePrayerTimes].
  final double latitude;
  final double longitude;
  final double fajrAngle;
  final double ishaAngle;

  /// Serialized madhab name (one of [AppConstants.madhabNames], e.g.
  /// `'shafi'`/`'hanafi'`). Kept as a String so `domain/` stays free of the
  /// adhan_dart import; the calculator maps it back to the enum.
  final String madhab;

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

  const AppConfig({
    required this.homeDuration,
    required this.eventDuration,
    required this.reportDuration,
    required this.adzanDuration,
    required this.jumatDuration,
    required this.shalatDuration,
    required this.isyraqDuration,
    required this.hijriCorrection,
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
    required this.madhab,
    required this.ihtiyat,
    required this.marqueeText,
    required this.backgroundImage,
    required this.eventImages,
    required this.enableFinancialReport,
    required this.financialSummary,
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
    );
  }

  /// A config populated entirely from [AppConstants] defaults.
  factory AppConfig.defaults() => AppConfig.fromJson(const {});

  Map<String, dynamic> toJson() {
    return {
      'homeDuration': homeDuration,
      'eventDuration': eventDuration,
      'reportDuration': reportDuration,
      'adzanDuration': adzanDuration,
      'jumatDuration': jumatDuration,
      'shalatDuration': shalatDuration,
      'isyraqDuration': isyraqDuration,
      'hijriCorrection': hijriCorrection,
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
      'madhab': madhab,
      'ihtiyat': ihtiyat,
      'marqueeText': marqueeText,
      'backgroundImage': backgroundImage,
      'eventImages': eventImages.map((e) => e.toJson()).toList(),
      'enableFinancialReport': enableFinancialReport,
      'financialSummary': financialSummary.toJson(),
    };
  }
}
