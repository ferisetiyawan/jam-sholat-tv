import 'dart:ui';

import 'package:flutter/material.dart';

import '../widgets/background_image.dart';

class ShalatScreen extends StatelessWidget {
  final String prayerName;

  const ShalatScreen({super.key, required this.prayerName});

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
                      children: [
                        // 1. JUDUL: SHALAT BERLANGSUNG (20%)
                        Expanded(flex: 20, child: Center(child: _buildBadge())),

                        // 2. TULISAN ARAB (30%) - Dibuat Jauh Lebih Besar
                        // Kita buang FittedBox luar agar dia bisa wrap,
                        // lalu kita kunci ukurannya di dalam.
                        Expanded(
                          flex: 35, // Ditambah sedikit flex-nya
                          child: Center(
                            child: SingleChildScrollView(
                              // Pengaman ekstra agar tidak overflow
                              child: Text(
                                "سَوُّوا صُفُوفَكُمْ، فَإِنَّ تَسْوِيَةَ الصَّفِّ مِنْ تَمَامِ الصَّلَاةِ",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize:
                                      screenSize.height *
                                      0.07, // Ukuran font dinamis berdasarkan tinggi layar
                                  fontFamily:
                                      'Amiri', // Gunakan font Arab jika ada
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 3. TULISAN LATIN / ARTI (20%)
                        Expanded(
                          flex:
                              15, // Dikurangi flex-nya agar Arab lebih dominan
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "\"Luruskan shaf kalian, sesungguhnya meluruskan shaf termasuk kesempurnaan shalat\"",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 4. GARIS PEMISAH (10%)
                        Expanded(
                          flex: 10,
                          child: Center(
                            child: Container(
                              width: screenSize.width * 0.2,
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.greenAccent.withValues(alpha: 0.3),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 5. KETERANGAN SHALAT (15%) - Kunci Anti-Overlap
                        Expanded(
                          flex: 20, // Ditambah flex agar area box shalat aman
                          child: Align(
                            alignment: Alignment
                                .topCenter, // Taruh agak atas agar tidak mepet bawah
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: _buildPrayerInfo(),
                            ),
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

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: Colors.greenAccent),
          SizedBox(width: 10),
          Text(
            "SHALAT BERLANGSUNG",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "SHALAT",
            style: TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            prayerName.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }
}
