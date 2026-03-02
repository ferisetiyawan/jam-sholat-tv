import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../widgets/background_image.dart';
import '../widgets/bottom_marquee_bar.dart';
import '../widgets/side_prayer_panel.dart';

class FinancialReportScreen extends StatelessWidget {
  final String time;
  final Map<String, String> jadwal;
  final String dateMasehi;
  final String dateHijriah;
  final String nextPrayerName;
  final Map<String, dynamic> data;

  const FinancialReportScreen({
    super.key,
    required this.time,
    required this.dateMasehi,
    required this.dateHijriah,
    required this.jadwal,
    required this.nextPrayerName,
    required this.data,
  });

  String formatIdr(dynamic amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(amount ?? 0);
  }

  @override
  Widget build(BuildContext context) {
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
                    // --- LEFT: TIME, DATE, PRAYER SCHEDULE (IDENTIK) ---
                    SidePrayerPanel(
                      time: time,
                      dateMasehi: dateMasehi,
                      dateHijriah: dateHijriah,
                      jadwal: jadwal,
                      nextPrayerName: nextPrayerName,
                    ),

                    // --- RIGHT: FINANCIAL REPORT ---
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(5, 15, 15, 15),
                        child: _buildFinancialContent(),
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

  Widget _buildFinancialContent() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: Colors.amber,
                    size: 30,
                  ),
                  SizedBox(width: 15),
                  Text(
                    "LAPORAN KEUANGAN BULANAN",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 40),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 2.8,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                  children: [
                    _buildFinanceCard(
                      "SALDO AWAL",
                      data['saldoAwal'],
                      Colors.blue,
                    ),
                    _buildFinanceCard(
                      "TOTAL PEMASUKAN",
                      data['kasmasuk'],
                      Colors.green,
                    ),
                    _buildFinanceCard(
                      "TOTAL PENGELUARAN",
                      data['kasKeluar'],
                      Colors.red,
                    ),
                    _buildFinanceCard(
                      "SALDO AKHIR",
                      data['saldoAkhir'],
                      Colors.amber,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              _buildDetailedRow(
                "Dana Prasarana",
                data['saldoPrasarana'],
                "Dana Operasional",
                data['saldoNonPrasarana'],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinanceCard(String title, dynamic value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: accentColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            child: Text(
              formatIdr(value),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedRow(String l1, dynamic v1, String l2, dynamic v2) {
    return Row(
      children: [
        Expanded(child: _buildSmallDetail(l1, v1)),
        const SizedBox(width: 15),
        Expanded(child: _buildSmallDetail(l2, v2)),
      ],
    );
  }

  Widget _buildSmallDetail(String label, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          Text(
            formatIdr(value),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
