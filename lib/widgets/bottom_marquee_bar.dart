import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

class BottomMarqueeBar extends StatelessWidget {
  final String text;
  final double fontSize;
  final double velocity;
  final Color backgroundColor;

  const BottomMarqueeBar({
    super.key,
    this.text =
        'Selamat Datang di Masjid Al Hijrah CGE - Jagalah Kebersihan dan Matikan Handphone saat Sholat - ',
    this.fontSize = 22,
    this.velocity = 45.0,
    this.backgroundColor = Colors.black87,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: double.infinity,
      color: backgroundColor,
      child: Marquee(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        velocity: velocity,
        blankSpace: 100.0,
        pauseAfterRound: const Duration(seconds: 1),
        startPadding: 10.0,
        accelerationDuration: const Duration(seconds: 1),
        accelerationCurve: Curves.linear,
        decelerationDuration: const Duration(milliseconds: 500),
        decelerationCurve: Curves.easeOut,
      ),
    );
  }
}
