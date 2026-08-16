import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import 'main_controller.dart';
import 'providers/app_provider.dart';
import 'providers/config_provider.dart';
import 'remote_key_handler.dart';

/// Root widget: wires up the providers and hosts [MainController].
///
/// The [configProvider] is injected from `main.dart` so persisted overrides
/// are loaded before the tree builds and the local config server can hot-apply
/// changes into it. The navigator key is shared with [RemoteKeyDetector],
/// which toggles the config menu (QR) via the TV remote.
class MasjidApp extends StatelessWidget {
  MasjidApp({super.key, this.configProvider})
      : _navigatorKey = GlobalKey<NavigatorState>();

  final ConfigProvider? configProvider;
  final GlobalKey<NavigatorState> _navigatorKey;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => configProvider ?? ConfigProvider(),
        ),

        ChangeNotifierProxyProvider<ConfigProvider, AppProvider>(
          create: (_) => AppProvider()..init(),
          update: (_, config, app) => app!..updateConfig(config),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        navigatorKey: _navigatorKey,
        builder: (context, child) => RemoteKeyDetector(
          navigatorKey: _navigatorKey,
          child: child ?? const SizedBox.shrink(),
        ),
        home: const MainController(),
      ),
    );
  }
}
