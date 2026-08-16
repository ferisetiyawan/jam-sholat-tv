import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import 'main_controller.dart';
import 'providers/app_provider.dart';
import 'providers/config_provider.dart';

/// Root widget: wires up the providers and hosts [MainController].
class MasjidApp extends StatelessWidget {
  const MasjidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConfigProvider()),

        ChangeNotifierProxyProvider<ConfigProvider, AppProvider>(
          create: (_) => AppProvider()..init(),
          update: (_, config, app) => app!..updateConfig(config),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const MainController(),
      ),
    );
  }
}
