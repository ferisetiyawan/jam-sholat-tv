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
                      horizontal: screenSize.width * 0.05,
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Badge Pengingat
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: Colors.orangeAccent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Text(
                            "WAKTU ISYRAQ",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Teks Arab Utama
                        const Text(
                          "أَفْضَلُ الصَّلَاةِ بَعْدَ الْفَرِيْضَةِ صَلَاةُ الضُّحَى",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 45,
                            fontFamily: 'Amiri',
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Teks Indonesia
                        const Text(
                          "\"Telah masuk waktu Isyraq (Awal Dhuha).\nMari tunaikan shalat sunnah Isyraq untuk meraih pahala sempurna.\"",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontStyle: FontStyle.italic,
                            color: Colors.white70,
                            height: 1.3,
                          ),
                        ),
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
}
