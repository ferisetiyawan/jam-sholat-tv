import 'package:flutter_test/flutter_test.dart';
import 'package:jam_sholat_tv/domain/models/financial_summary.dart';

void main() {
  group('FinancialSummary', () {
    test('parses amounts from int, double and string values', () {
      final summary = FinancialSummary.fromJson({
        'saldoAwal': 1000000,
        'kasmasuk': '250000.5',
        'kasKeluar': 150000,
        'saldoAkhir': 1100000.5,
        'saldoPrasarana': 50000,
        'saldoNonPrasarana': 0,
      });

      expect(summary.saldoAwal, 1000000);
      expect(summary.kasMasuk, 250000.5);
      expect(summary.kasKeluar, 150000);
      expect(summary.saldoAkhir, 1100000.5);
      expect(summary.saldoPrasarana, 50000);
      expect(summary.saldoNonPrasarana, 0);
    });

    test('falls back to zero for missing or unparseable fields', () {
      final summary = FinancialSummary.fromJson({
        'saldoAwal': null,
        'kasKeluar': 'not-a-number',
      });

      expect(summary.saldoAwal, 0);
      expect(summary.kasKeluar, 0);
      expect(summary.kasMasuk, 0);
      expect(summary.saldoAkhir, 0);
    });
  });
}
