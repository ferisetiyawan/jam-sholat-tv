import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/background_image.dart';
import '../../core/widgets/bottom_marquee_bar.dart';
import '../../core/widgets/side_prayer_panel.dart';
import '../../domain/models/financial_summary.dart';

class FinancialReportScreen extends StatelessWidget {
  final String time;
  final Map<String, String> jadwal;
  final String dateMasehi;
  final String dateHijriah;
  final String nextPrayerName;
  final FinancialSummary summary;

  const FinancialReportScreen({
    super.key,
    required this.time,
    required this.dateMasehi,
    required this.dateHijriah,
    required this.jadwal,
    required this.nextPrayerName,
    required this.summary,
  });

  String formatIdr(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final String todayDate = DateFormat(
      'dd MMMM yyyy',
      'id_ID',
    ).format(DateTime.now());

    return Scaffold(
      body: Stack(
        children: [
          const BackgroundImage(),
          Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SidePrayerPanel(
                      time: time,
                      dateMasehi: dateMasehi,
                      dateHijriah: dateHijriah,
                      jadwal: jadwal,
                      nextPrayerName: nextPrayerName,
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(5, 15, 15, 15),
                        child: _buildFinancialContent(todayDate),
                      ),
                    ),
                  ],
                ),
              ),
              const BottomMarqueeBar(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialContent(String todayDate) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "LAPORAN KEUANGAN BULANAN",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        "Data terbaru: $todayDate",
                        style: TextStyle(color: Colors.white70, fontSize: 11),
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
              const Divider(color: Colors.white24, height: 20),

              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          _buildFinanceCard(
                            "SALDO AWAL",
                            summary.saldoAwal,
                            Colors.blue,
                          ),
                          const SizedBox(width: 12),
                          _buildFinanceCard(
                            "TOTAL PEMASUKAN",
                            summary.kasMasuk,
                            Colors.green,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Row(
                        children: [
                          _buildFinanceCard(
                            "TOTAL PENGELUARAN",
                            summary.kasKeluar,
                            Colors.red,
                          ),
                          const SizedBox(width: 12),
                          _buildFinanceCard(
                            "SALDO AKHIR",
                            summary.saldoAkhir,
                            Colors.amber,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              _buildDetailedRow(
                "Dana Prasarana",
                summary.saldoPrasarana,
                "Dana Operasional",
                summary.saldoNonPrasarana,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinanceCard(String title, double value, Color accentColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                color: accentColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatIdr(value),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedRow(String l1, double v1, String l2, double v2) {
    return Row(
      children: [
        Expanded(child: _buildSmallDetail(l1, v1)),
        const SizedBox(width: 12),
        Expanded(child: _buildSmallDetail(l2, v2)),
      ],
    );
  }

  Widget _buildSmallDetail(String label, double value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          Text(
            formatIdr(value),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
