import 'package:flutter/material.dart';
import '../screens/home_screen.dart';

import 'package:cached_network_image/cached_network_image.dart';

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
        Positioned.fill(
          child: Image.asset(
            'assets/images/background_masjid.jpeg',
            fit: BoxFit.cover,
          ),
        ),
        
        Container(color: Colors.black.withValues(alpha: 0.5)),

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
