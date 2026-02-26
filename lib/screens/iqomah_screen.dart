import 'dart:ui';
import 'package:flutter/material.dart';

class IqomahScreen extends StatelessWidget {
  final String prayerName;
  final int countdown;

  const IqomahScreen({
    super.key, 
    required this.prayerName, 
    required this.countdown
  });

  @override
  Widget build(BuildContext context) {
    String minutes = (countdown ~/ 60).toString().padLeft(2, '0');
    String seconds = (countdown % 60).toString().padLeft(2, '0');

    Color timerColor = (countdown <= 10) ? Colors.redAccent : Colors.greenAccent;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "MENUJU IQOMAH", 
                  style: TextStyle(fontSize: 35, fontWeight: FontWeight.w300, letterSpacing: 8)
                ),
                Text(
                  prayerName.toUpperCase(), 
                  style: const TextStyle(fontSize: 25, color: Colors.white70)
                ),
                
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "$minutes:$seconds",
                      style: TextStyle(
                        fontSize: 250, 
                        fontWeight: FontWeight.w900, 
                        color: timerColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
                
                const Text(
                  "LURUSKAN DAN RAPATKAN SHAF", 
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 2)
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
