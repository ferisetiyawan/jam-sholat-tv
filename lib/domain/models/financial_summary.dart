/// One week of income within the reporting month.
///
/// `periodeStart` / `periodeEnd` are ISO 8601 UTC dates (the screen renders
/// them `.toLocal()`); `pemasukan` is the week's income.
class WeeklyIncome {
  final DateTime periodeStart;
  final DateTime periodeEnd;
  final double pemasukan;

  const WeeklyIncome({
    required this.periodeStart,
    required this.periodeEnd,
    required this.pemasukan,
  });

  factory WeeklyIncome.fromJson(Map<String, dynamic> json) {
    double toAmount(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    DateTime toDate(dynamic value) {
      return DateTime.tryParse(value?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }

    return WeeklyIncome(
      periodeStart: toDate(json['periodeStart']),
      periodeEnd: toDate(json['periodeEnd']),
      pemasukan: toAmount(json['pemasukan']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'periodeStart': periodeStart.toUtc().toIso8601String(),
      'periodeEnd': periodeEnd.toUtc().toIso8601String(),
      'pemasukan': pemasukan,
    };
  }
}

/// Masjid treasury (kas) report rendered on the financial screen.
///
/// Holds the total kas balance, the date it was recorded, and the month's
/// weekly income breakdown. Amounts are normalized to `double`; missing or
/// unparseable values fall back to zero, dates to epoch, and the income list
/// to empty, so the screen never has to null-check individual fields.
class FinancialSummary {
  final double totalKasMasjid;
  final DateTime saldoKasDate;
  final List<WeeklyIncome> weeklyIncome;

  const FinancialSummary({
    required this.totalKasMasjid,
    required this.saldoKasDate,
    required this.weeklyIncome,
  });

  factory FinancialSummary.fromJson(Map<String, dynamic> json) {
    double toAmount(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    DateTime toDate(dynamic value) {
      return DateTime.tryParse(value?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }

    List<WeeklyIncome> toWeeks(dynamic value) {
      if (value is! List) return const [];
      return value
          .whereType<Map<String, dynamic>>()
          .map(WeeklyIncome.fromJson)
          .toList();
    }

    return FinancialSummary(
      totalKasMasjid: toAmount(json['totalKasMasjid']),
      saldoKasDate: toDate(json['saldoKasDate']),
      weeklyIncome: toWeeks(json['weeklyIncome']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalKasMasjid': totalKasMasjid,
      'saldoKasDate': saldoKasDate.toUtc().toIso8601String(),
      'weeklyIncome': weeklyIncome.map((w) => w.toJson()).toList(),
    };
  }

  /// Offline sample data shown on the masjid TV (no network).
  ///
  /// The initial/default report; the masjid can replace it at runtime through
  /// the local config server's web editor (saved under `financialSummary`).
  static FinancialSummary offlineSample() =>
      FinancialSummary.fromJson({
        'saldoKasDate': DateTime.now().toUtc().toIso8601String(),
        'totalKasMasjid': 0,
        'weeklyIncome': <Map<String, dynamic>>[],
      });
}
