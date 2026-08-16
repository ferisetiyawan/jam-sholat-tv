import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/financial_summary.dart';

/// The ledger panel of the financial report.
///
/// Standalone (no surrounding home-mode chrome) so it can be laid out and
/// tested in isolation. The report is drawn at a fixed logical size
/// ([_designWidth] wide) and wrapped in a `FittedBox` with `BoxFit.contain`,
/// so it scales to fit — down on a short display, up to fill a large one —
/// without ever overflowing. Rows use `spaceBetween` instead of flex children
/// because `FittedBox` lays its child out with unbounded constraints.
class FinancialReportCard extends StatelessWidget {
  final FinancialSummary summary;

  /// Logical design width the report is laid out at before scaling.
  static const double _designWidth = 520;

  const FinancialReportCard({super.key, required this.summary});

  String formatIdr(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(amount);
  }

  String formatDate(DateTime date) {
    return DateFormat('d MMMM yyyy', 'id_ID').format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white10),
          ),
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.center,
            child: SizedBox(
              width: _designWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "LAPORAN KEUANGAN",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            "Saldo kas & pemasukan pekan ini",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.amber,
                        size: 30,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white24, height: 14),

                  // --- Saldo Kas Akhir ---
                  _buildSectionHeader(
                    "SALDO KAS AKHIR",
                    trailing: formatDate(summary.saldoKasDate),
                  ),
                  const SizedBox(height: 5),
                  _buildTotalRow(),
                  const SizedBox(height: 10),
                  const Divider(color: Colors.white24, height: 14),

                  // --- Pemasukan Pekan Ini ---
                  _buildSectionHeader("PEMASUKAN PEKAN INI"),
                  const SizedBox(height: 6),
                  ...summary.weeklyIncome.map(_buildWeekRow),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.amber,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
      ],
    );
  }

  Widget _buildTotalRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
      ),
      child: _buildRow("Total Kas Masjid", summary.totalKasMasjid,
          emphasized: true),
    );
  }

  Widget _buildWeekRow(WeeklyIncome week) {
    final String periode =
        "${formatDate(week.periodeStart)} - ${formatDate(week.periodeEnd)}";
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            periode,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
          Text(
            formatIdr(week.pemasukan),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, double amount, {bool emphasized = false}) {
    final Color textColor =
        emphasized ? Colors.white : Colors.white.withValues(alpha: 0.85);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: emphasized ? 15 : 14,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
          Text(
            formatIdr(amount),
            style: TextStyle(
              color: Colors.white,
              fontSize: emphasized ? 17 : 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
