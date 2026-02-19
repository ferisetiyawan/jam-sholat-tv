import 'dart:ui';
import 'package:flutter/material.dart';

class IqomahScreen extends StatelessWidget {
  final String namaSholat;
  final int countdown;

  const IqomahScreen({
    super.key, 
    required this.namaSholat, 
    required this.countdown
  });

  @override
  Widget build(BuildContext context) {
    // Format detik ke MM:SS
    String minutes = (countdown ~/ 60).toString().padLeft(2, '0');
    String seconds = (countdown % 60).toString().padLeft(2, '0');

    return Center(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("MENUJU IQOMAH", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w300, letterSpacing: 8)),
              Text(namaSholat.toUpperCase(), style: const TextStyle(fontSize: 30, color: Colors.white70)),
              const SizedBox(height: 20),
              Text(
                "$minutes:$seconds",
                style: const TextStyle(
                  fontSize: 200, 
                  fontWeight: FontWeight.w900, 
                  color: Colors.greenAccent, 
                  fontFeatures: [FontFeature.tabularFigures()]
                ),
              ),
              const SizedBox(height: 20),
              const Text("LURUSKAN DAN RAPATKAN SHAF", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: 2)),
            ],
          ),
        ),
      ),
    );
  }
}
