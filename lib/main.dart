import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WakelockPlus.enable(); // Mencegah TV sleep
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: HomeScreen(),
  ));
}
