import 'package:flutter/material.dart';

import '../../core/widgets/background_image.dart';
import '../../core/widgets/bottom_marquee_bar.dart';
import '../../core/widgets/side_prayer_panel.dart';
import '../../domain/models/financial_summary.dart';
import 'financial_report_card.dart';

/// Full-screen view of the masjid treasury report.
///
/// Wraps the self-scaling [FinancialReportCard] in the home-mode chrome
/// (background, sidebar prayer panel, marquee). The card itself is standalone
/// so it can scale to any panel size without overflowing.
class FinancialReportScreen extends StatelessWidget {
  final String time;
  final Map<String, String> jadwal;
  final String dateMasehi;
  final String dateHijriah;
  final String nextPrayerName;
  final String masjidName;
  final FinancialSummary summary;

  const FinancialReportScreen({
    super.key,
    required this.time,
    required this.dateMasehi,
    required this.dateHijriah,
    required this.jadwal,
    required this.nextPrayerName,
    required this.masjidName,
    required this.summary,
  });

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
                    SidePrayerPanel(
                      time: time,
                      dateMasehi: dateMasehi,
                      dateHijriah: dateHijriah,
                      jadwal: jadwal,
                      nextPrayerName: nextPrayerName,
                      masjidName: masjidName,
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(5, 15, 15, 15),
                        child: FinancialReportCard(summary: summary),
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
}
