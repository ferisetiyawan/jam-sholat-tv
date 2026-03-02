import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../widgets/background_image.dart';

class HomeWrapper extends StatelessWidget {
  final String time;
  final Map<String, String> jadwal;
  final String dateMasehi;
  final String dateHijriah;
  final Widget Function(String, String) prayerItemBuilder;

  const HomeWrapper({
    super.key,
    required this.time,
    required this.dateMasehi,
    required this.dateHijriah,
    required this.jadwal,
    required this.prayerItemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const BackgroundImage(),

        HomeScreen(
          time: time,
          jadwal: jadwal,
          dateMasehi: dateMasehi,
          dateHijriah: dateHijriah,
          prayerItemBuilder: prayerItemBuilder,
        ),
      ],
    );
  }
}
