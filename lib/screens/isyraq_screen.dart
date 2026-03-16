import 'dart:ui';

import 'package:flutter/material.dart';

import '../widgets/background_image.dart';

class IsyraqScreen extends StatelessWidget {
  const IsyraqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          const BackgroundImage(),

          Center(
            child: SizedBox(
              width: screenSize.width * 0.9,
              height: screenSize.height * 0.85,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenSize.width * 0.04,
                      vertical: screenSize.height * 0.02,
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
                      children: [
                        Expanded(
                          flex: 15,
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: _buildBadge(),
                            ),
                          ),
                        ),

                        Expanded(
                          flex: 40,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: const Text(
                                  "WAKTU ISYRAQ TELAH TIBA",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        Expanded(
                          flex: 20,
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenSize.width * 0.05,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "Mari tunaikan shalat sunnah dua rakaat untuk meraih\nkeutamaan pahala sempurna di awal hari.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        Expanded(
                          flex: 10,
                          child: Center(
                            child: Container(
                              width: screenSize.width * 0.35,
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.orangeAccent.withValues(alpha: 0.5),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const Expanded(flex: 15, child: SizedBox()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wb_sunny_rounded, size: 20, color: Colors.orangeAccent),
          SizedBox(width: 12),
          Text(
            "PENGINGAT WAKTU ISYRAQ",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
