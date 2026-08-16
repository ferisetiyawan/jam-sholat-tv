import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jam_sholat_tv/domain/models/financial_summary.dart';
import 'package:jam_sholat_tv/ui/home/financial_report_card.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('renders all sections without overflow on a small panel',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              height: 220,
              child: FinancialReportCard(
                summary: FinancialSummary.offlineSample(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('LAPORAN KEUANGAN'), findsOneWidget);
    expect(find.text('SALDO KAS AKHIR'), findsOneWidget);
    expect(find.text('Total Kas Masjid'), findsOneWidget);
    expect(find.text('PEMASUKAN PEKAN INI'), findsOneWidget);
    expect(find.text('1 Mei 2026 - 7 Mei 2026'), findsOneWidget);
    expect(find.text('29 Mei 2026 - 4 Juni 2026'), findsOneWidget);
    expect(find.text('Rp2.050.000'), findsNWidgets(5));
    expect(find.text('Rp121.381.630'), findsOneWidget);
  });

  testWidgets('no overflow on a very small panel', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 180,
              child: FinancialReportCard(
                summary: FinancialSummary.offlineSample(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('becomes scrollable when the panel is too short',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              height: 220,
              child: FinancialReportCard(
                summary: FinancialSummary.offlineSample(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Scroll down; the last week row should become visible and nothing
    // should throw (no overflow, no overlap).
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      find.text('29 Mei 2026 - 4 Juni 2026'),
      findsOneWidget,
    );
  });

  testWidgets('no overflow on a large panel', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 1000,
              height: 700,
              child: FinancialReportCard(
                summary: FinancialSummary.offlineSample(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('LAPORAN KEUANGAN'), findsOneWidget);
    expect(find.text('29 Mei 2026 - 4 Juni 2026'), findsOneWidget);
  });
}
