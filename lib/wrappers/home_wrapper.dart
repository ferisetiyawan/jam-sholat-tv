import 'package:flutter/material.dart';
import '../screens/home_screen.dart';

import 'package:cached_network_image/cached_network_image.dart';

class HomeWrapper extends StatelessWidget {
  final String time;
  final Map<String, String> jadwal;
  final Widget Function(String, String) prayerItemBuilder;

  const HomeWrapper({
    super.key,
    required this.time,
    required this.jadwal,
    required this.prayerItemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // BACKGROUND IMAGE DENGAN FALLBACK
        Positioned.fill(
          child: CachedNetworkImage(
            imageUrl: 'https://i.ibb.co.com/mPvfRZ7/Whats-App-Image-2026-02-19-at-4-29-11-PM.jpg',
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.black),
            errorWidget: (context, url, error) => Image.asset(
              'assets/background_masjid.jpeg',
              fit: BoxFit.cover,
            ),
          ),
        ),

        // OVERLAY GELAP
        Container(color: Colors.black.withOpacity(0.5)),

        // KONTEN UTAMA
        HomeScreen(
          time: time,
          jadwal: jadwal,
          prayerItemBuilder: prayerItemBuilder,
        ),
      ],
    );
  }
}
