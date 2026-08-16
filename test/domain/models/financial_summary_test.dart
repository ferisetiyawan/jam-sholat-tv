import 'package:flutter_test/flutter_test.dart';
import 'package:jam_sholat_tv/domain/models/financial_summary.dart';

void main() {
  group('FinancialSummary', () {
    test('parses totalKasMasjid and weekly income from mixed value types', () {
      final summary = FinancialSummary.fromJson({
        'totalKasMasjid': '121381630.5',
        'saldoKasDate': '2026-06-03T17:00:00.000Z',
        'weeklyIncome': [
          {
            'periodeStart': '2026-04-30T17:00:00.000Z',
            'periodeEnd': '2026-05-06T17:00:00.000Z',
            'pemasukan': 2050000,
          },
          {
            'periodeStart': '2026-05-07T17:00:00.000Z',
            'periodeEnd': '2026-05-13T17:00:00.000Z',
            'pemasukan': '2050000.5',
          },
        ],
      });

      expect(summary.totalKasMasjid, 121381630.5);
      expect(summary.weeklyIncome, hasLength(2));
      expect(summary.weeklyIncome[0].pemasukan, 2050000);
      expect(summary.weeklyIncome[1].pemasukan, 2050000.5);
      expect(
        summary.weeklyIncome[0].periodeStart,
        DateTime.parse('2026-04-30T17:00:00.000Z'),
      );
      expect(
        summary.weeklyIncome[1].periodeEnd,
        DateTime.parse('2026-05-13T17:00:00.000Z'),
      );
    });

    test('falls back to zero, epoch and empty list when fields are missing', () {
      final summary = FinancialSummary.fromJson({
        'totalKasMasjid': null,
      });

      expect(summary.totalKasMasjid, 0);
      expect(summary.saldoKasDate, DateTime.fromMillisecondsSinceEpoch(0));
      expect(summary.weeklyIncome, isEmpty);
    });

    test('parses the ISO saldoKasDate field', () {
      final summary = FinancialSummary.fromJson({
        'saldoKasDate': '2026-06-03T17:00:00.000Z',
      });

      expect(summary.saldoKasDate, DateTime.parse('2026-06-03T17:00:00.000Z'));
    });

    test('ignores non-map entries in weeklyIncome', () {
      final summary = FinancialSummary.fromJson({
        'weeklyIncome': ['not-a-map', 42],
      });

      expect(summary.weeklyIncome, isEmpty);
    });

    test('offlineSample matches the example data', () {
      final summary = FinancialSummary.offlineSample();

      expect(summary.totalKasMasjid, 121381630);
      expect(
        summary.saldoKasDate,
        DateTime.parse('2026-06-03T17:00:00.000Z'),
      );
      expect(summary.weeklyIncome, hasLength(5));

      // Every week reports the same income for this sample.
      for (final week in summary.weeklyIncome) {
        expect(week.pemasukan, 2050000);
      }

      // First and last weeks bracket the reported month.
      expect(
        summary.weeklyIncome.first.periodeStart,
        DateTime.parse('2026-04-30T17:00:00.000Z'),
      );
      expect(
        summary.weeklyIncome.last.periodeEnd,
        DateTime.parse('2026-06-03T17:00:00.000Z'),
      );
    });
  });
}
