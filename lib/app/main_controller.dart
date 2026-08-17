import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_enum.dart';
import '../core/widgets/prayer_card.dart';
import '../ui/home/event_screen.dart';
import '../ui/home/financial_report_screen.dart';
import '../ui/home/home_wrapper.dart';
import '../ui/home/live_makkah_screen.dart';
import '../ui/prayer/adzan_screen.dart';
import '../ui/prayer/iqomah_screen.dart';
import '../ui/prayer/isyraq_screen.dart';
import '../ui/prayer/jumat_screen.dart';
import '../ui/prayer/shalat_screen.dart';
import '../ui/settings/config_menu_screen.dart';
import 'providers/app_provider.dart';
import 'providers/config_provider.dart';

/// Watches [AppProvider] and swaps the full-screen widget based on the current
/// [AppStatus].
class MainController extends StatelessWidget {
  const MainController({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to AppProvider for changes and rebuild when it updates
    final app = context.watch<AppProvider>();
    final config = context.watch<ConfigProvider>();

    // Navigate screen based on AppStatus
    final Widget screen = switch (app.status) {
      AppStatus.adzan => AdzanScreen(prayerName: app.currentPrayerName),
      AppStatus.iqomah => IqomahScreen(
        prayerName: app.currentPrayerName,
        countdown: app.iqomahCounter,
      ),
      AppStatus.isyraq => const IsyraqScreen(),
      AppStatus.jumatMode => const JumatScreen(),
      AppStatus.shalat => ShalatScreen(prayerName: app.currentPrayerName),
      AppStatus.home when app.isSpecialLiveMode => LiveMakkahScreen(
        time: app.timeString,
        dateMasehi: app.dateMasehi,
        dateHijriah: app.dateHijriah,
        jadwal: app.jadwal,
        nextPrayerName: app.nextPrayerName,
        liveMakkahUrl: config.liveMakkahUrl,
      ),
      AppStatus.home when app.isReportMode && app.financialSummary != null =>
        FinancialReportScreen(
          time: app.timeString,
          dateMasehi: app.dateMasehi,
          dateHijriah: app.dateHijriah,
          jadwal: app.jadwal,
          nextPrayerName: app.nextPrayerName,
          summary: app.financialSummary!,
        ),
      AppStatus.home when app.isEventMode && config.eventImages.isNotEmpty =>
        EventScreen(
          images: config.eventImages,
          currentIndex: app.currentEventIndex,
          currentTime: app.timeString,
        ),
      // Default to Home (Status Home & IsEventMode = false)
      _ => HomeWrapper(
        time: app.timeString,
        dateMasehi: app.dateMasehi,
        dateHijriah: app.dateHijriah,
        jadwal: app.jadwal,
        prayerItemBuilder: (label, time) => PrayerCard(
          label: label,
          time: time,
          isNext: label == app.nextPrayerName,
          countdown: app.countdownString,
        ),
      ),
    };

    return Scaffold(
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            child: screen,
          ),
          if (!app.hasInternet)
            Positioned(
              top: 3,
              left: 3,
              child: Container(
                padding: EdgeInsets.all(5),
                color: Colors.red,
                child: Icon(Icons.wifi_off, color: Colors.white, size: 12),
              ),
            ),
        ],
      ),
      floatingActionButton: _buildDebugFab(context),
    );
  }

  // Simulation Button
  Widget? _buildDebugFab(BuildContext context) {
    if (!kDebugMode) return null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: "btnSyuruq",
          backgroundColor: Colors.orange.withValues(alpha: 0.6),
          onPressed: () => context.read<AppProvider>().enableFakeSyuruqTime(),
          child: const Icon(Icons.wb_sunny),
        ),

        const SizedBox(height: 10),

        FloatingActionButton(
          heroTag: "btnMaghrib",
          backgroundColor: Colors.red.withValues(alpha: 0.5),
          onPressed: () => context.read<AppProvider>().enableFakeTime(),
          child: const Icon(Icons.fast_forward),
        ),

        const SizedBox(height: 10),

        // Dev-only shortcut for the config server QR menu — same screen the
        // TV remote's long-press OK / Menu opens (simulates the remote).
        FloatingActionButton(
          heroTag: "btnConfigQr",
          backgroundColor: Colors.lightBlue.withValues(alpha: 0.6),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ConfigMenuScreen(),
            ),
          ),
          child: const Icon(Icons.qr_code),
        ),
      ],
    );
  }
}
