/// Monthly masjid treasury (kas) summary rendered on the financial report.
///
/// Amounts are normalized to `double`; missing/unparseable values fall back to
/// zero so the report screen never has to null-check individual fields.
class FinancialSummary {
  final double saldoAwal;
  final double kasMasuk;
  final double kasKeluar;
  final double saldoAkhir;
  final double saldoPrasarana;
  final double saldoNonPrasarana;

  const FinancialSummary({
    required this.saldoAwal,
    required this.kasMasuk,
    required this.kasKeluar,
    required this.saldoAkhir,
    required this.saldoPrasarana,
    required this.saldoNonPrasarana,
  });

  factory FinancialSummary.fromJson(Map<String, dynamic> json) {
    double toAmount(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return FinancialSummary(
      saldoAwal: toAmount(json['saldoAwal']),
      kasMasuk: toAmount(json['kasmasuk']),
      kasKeluar: toAmount(json['kasKeluar']),
      saldoAkhir: toAmount(json['saldoAkhir']),
      saldoPrasarana: toAmount(json['saldoPrasarana']),
      saldoNonPrasarana: toAmount(json['saldoNonPrasarana']),
    );
  }
}
