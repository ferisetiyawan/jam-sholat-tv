import 'package:hijriyah_indonesia/hijriyah_indonesia.dart';
import 'package:hijriyah_khgt/hijriyah_khgt.dart' as khgt;
import 'package:intl/intl.dart';

class DateFormatter {
  /// Returns the date in both calendars.
  ///
  /// [correction] shifts the Hijri date by ±N days (the "Koreksi Hijriah"
  /// dashboard setting) and only applies to the location-based [kalender]
  /// `'umum'`. When [kalender] is `'khgt'` (Kalender Hijriah Global Tunggal),
  /// the date is computed from the global unified calendar, which yields the
  /// same date for every location — so the correction is not applied.
  /// [now] defaults to the current time and is injectable for tests.
  static Map<String, String> getFullDate(
    int correction, {
    String kalender = 'umum',
    DateTime? now,
  }) {
    final date = now ?? DateTime.now();

    // Gregorian (Masehi)
    String masehi = DateFormat('d MMMM yyyy', 'id_ID').format(date);

    // Hijriah
    final String hijriah;
    if (kalender == 'khgt') {
      final hijri = khgt.Hijriyah.fromDate(date);
      hijriah = '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} H';
    } else {
      final adjustedDate = date.add(Duration(days: correction));
      final hijri = Hijriyah.fromDate(adjustedDate);
      hijriah = '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} H';
    }

    return {'masehi': masehi, 'hijriah': hijriah};
  }
}
