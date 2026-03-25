import 'package:hijriyah_indonesia/hijriyah_indonesia.dart';
import 'package:intl/intl.dart';

class DateFormatter {
  static Map<String, String> getFullDate(int correction) {
    final now = DateTime.now();

    // Gregorian (Masehi)
    String masehi = DateFormat('d MMMM yyyy', 'id_ID').format(now);

    // Hijriah
    final adjustedDate = now.add(Duration(days: correction));
    var hijri = Hijriyah.fromDate(adjustedDate);

    String hijriah = "${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} H";

    return {"masehi": masehi, "hijriah": hijriah};
  }
}
