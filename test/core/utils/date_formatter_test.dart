import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jam_sholat_tv/core/utils/date_formatter.dart';

void main() {
  setUpAll(() async {
    // main.dart initializes this locale at startup; tests need the same data.
    await initializeDateFormatting('id_ID', null);
  });

  group('DateFormatter.getFullDate', () {
    test('renders the Gregorian date in Indonesian', () {
      final dates = DateFormatter.getFullDate(
        0,
        now: DateTime(2026, 8, 17),
      );

      expect(dates['masehi'], '17 Agustus 2026');
    });

    test('umum calendar applies the hijri correction', () {
      final uncorrected = DateFormatter.getFullDate(
        0,
        now: DateTime(2026, 8, 17),
      );
      final corrected = DateFormatter.getFullDate(
        -1,
        now: DateTime(2026, 8, 17),
      );

      expect(uncorrected['masehi'], corrected['masehi']);
      expect(uncorrected['hijriah'], isNot(corrected['hijriah']));
    });

    test('khgt calendar ignores the hijri correction', () {
      final khgtZero = DateFormatter.getFullDate(
        0,
        kalender: 'khgt',
        now: DateTime(2026, 8, 17),
      );
      final khgtShifted = DateFormatter.getFullDate(
        -1,
        kalender: 'khgt',
        now: DateTime(2026, 8, 17),
      );

      expect(khgtZero['hijriah'], khgtShifted['hijriah']);
      expect(khgtZero['hijriah'], matches(r'^\d+ \w+( \w+)* \d{4} H$'));
    });
  });
}
