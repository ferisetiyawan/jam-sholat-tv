import 'dart:ui';

import 'package:flutter/material.dart';

import '../widgets/background_image.dart';

class IqomahScreen extends StatelessWidget {
  final String prayerName;
  final int countdown;

  const IqomahScreen({
    super.key,
    required this.prayerName,
    required this.countdown,
  });

  @override
  Widget build(BuildContext context) {
    String minutes = (countdown ~/ 60).toString().padLeft(2, '0');
    String seconds = (countdown % 60).toString().padLeft(2, '0');

    Color timerColor = (countdown <= 10)
        ? Colors.redAccent
        : Colors.greenAccent;

    return Scaffold(
      body: Stack(
        children: [
          const BackgroundImage(),

          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 30,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "MENUJU IQOMAH",
                        style: TextStyle(
                          fontSize: 35,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          letterSpacing: 8,
                        ),
                      ),

                      Text(
                        prayerName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 25,
                          color: Colors.white70,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "$minutes:$seconds",
                            style: TextStyle(
                              fontSize: 250,
                              fontWeight: FontWeight.w900,
                              color: timerColor,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          "LURUSKAN DAN RAPATKAN SHAF",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
