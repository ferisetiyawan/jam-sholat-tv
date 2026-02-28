import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

// Constants & Enums
import 'core/constants/app_constants.dart';
import 'core/constants/app_enum.dart';
// Theme
import 'core/theme/app_theme.dart';
// Providers
import 'providers/app_provider.dart';
// Screens
import 'screens/adzan_screen.dart';
import 'screens/event_screen.dart';
import 'screens/iqomah_screen.dart';
import 'screens/jumat_screen.dart';
import 'screens/live_makkah_screen.dart';
// Widgets
import 'widgets/prayer_card.dart';
// Wrappers
import 'wrappers/home_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force Landscape Orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Fullscreen mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Initialize Intl for Indonesian locale
  await initializeDateFormatting('id_ID', null);

  // Keep screen on
  WakelockPlus.enable();

  runApp(
    // Provider will manage state and notify widgets to rebuild on changes
    ChangeNotifierProvider(
      create: (_) => AppProvider()..init(),
      child: const MasjidApp(),
    ),
  );
}

class MasjidApp extends StatelessWidget {
  const MasjidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainController(),
    );
  }
}

class MainController extends StatelessWidget {
  const MainController({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to AppProvider for changes and rebuild when it updates
    final app = context.watch<AppProvider>();

    // Navigate screen based on AppStatus
    final Widget screen = switch (app.status) {
      AppStatus.adzan => AdzanScreen(prayerName: app.currentPrayerName),
      AppStatus.iqomah => IqomahScreen(
        prayerName: app.currentPrayerName,
        countdown: app.iqomahCounter,
      ),
      AppStatus.jumatMode => const JumatScreen(),
      AppStatus.home when app.isSpecialLiveMode => LiveMakkahScreen(
        time: app.timeString,
        dateMasehi: app.dateMasehi,
        dateHijriah: app.dateHijriah,
        jadwal: app.jadwal,
        nextPrayerName: app.nextPrayerName,
      ),
      AppStatus.home when app.isEventMode => EventScreen(
        images: AppConstants.eventImages,
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
    return FloatingActionButton(
      backgroundColor: Colors.red.withValues(alpha: 0.5),
      onPressed: () => context.read<AppProvider>().enableFakeTime(),
      child: const Icon(Icons.fast_forward),
    );
  }
}
