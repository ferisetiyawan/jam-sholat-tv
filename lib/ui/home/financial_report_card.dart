import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/financial_summary.dart';

/// The ledger panel of the financial report.
///
/// Standalone (no surrounding home-mode chrome) so it can be laid out and
/// tested in isolation. The report is flexible by construction:
///
/// - Rows stretch to fill the panel width, so on a wide TV the ledger spans
///   the whole panel (label left, amount right).
/// - Labels and amounts are wrapped in `FittedBox` (`scaleDown`), so on a
///   narrow panel they shrink to fit instead of overflowing.
/// - Vertically the content is centered when it fits, and becomes scrollable
///   instead of overflowing when the panel is shorter than the content.
class FinancialReportCard extends StatelessWidget {
  final FinancialSummary summary;

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

  /// Renders [text] at its natural size, shrinking down to fit its row when
  /// there is not enough horizontal space.
  Widget _shrinkText(
    String text,
    TextStyle style, {
    Alignment alignment = Alignment.centerLeft,
  }) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Text(text, style: style),
    );
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Center vertically when the content fits; scroll (never
              // overflow) when the panel is shorter than the content.
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _shrinkText(
                                  "LAPORAN KEUANGAN",
                                  const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                _shrinkText(
                                  "Saldo kas & pemasukan pekan ini",
                                  const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
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
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String? trailing}) {
    return Row(
      children: [
        Expanded(
          child: _shrinkText(
            title,
            const TextStyle(
              color: Colors.amber,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          _shrinkText(
            trailing,
            const TextStyle(color: Colors.white70, fontSize: 12),
            alignment: Alignment.centerRight,
          ),
        ],
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
      child: _buildRow(periode, week.pemasukan),
    );
  }

  Widget _buildRow(String label, double amount, {bool emphasized = false}) {
    final Color labelColor =
        emphasized ? Colors.white : Colors.white.withValues(alpha: 0.85);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: _shrinkText(
              label,
              TextStyle(
                color: labelColor,
                fontSize: emphasized ? 15 : 13,
                fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _shrinkText(
            formatIdr(amount),
            TextStyle(
              color: Colors.white,
              fontSize: emphasized ? 17 : 15,
              fontWeight: FontWeight.w900,
            ),
            alignment: Alignment.centerRight,
          ),
        ],
      ),
    );
  }
}
