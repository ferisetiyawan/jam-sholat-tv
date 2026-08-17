import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'app/masjid_app.dart';
import 'app/providers/config_provider.dart';
import 'services/follower_sync_service.dart';
import 'services/local_server_service.dart';

Future<void> main() async {
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

  // Load settings saved through the local config server (over AppConstants
  // defaults), then start the server so the TV can be configured from any
  // browser on the same Wi-Fi. Neither failure should block the prayer TV.
  final ConfigProvider configProvider = ConfigProvider();
  try {
    await configProvider.load();
  } catch (_) {
    // Fall back to AppConstants defaults.
  }
  await LocalServerService(configProvider: configProvider).start();

  // If this device is a follower, start polling the master for config.
  if (configProvider.isFollower) {
    FollowerSyncService(configProvider: configProvider).start();
  }

  runApp(MasjidApp(configProvider: configProvider));
}
