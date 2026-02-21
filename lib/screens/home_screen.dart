import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

class HomeScreen extends StatelessWidget {
  final String time;
  final Map<String, String> jadwal;
  final Widget Function(String, String) prayerItemBuilder;

  const HomeScreen({
    super.key, 
    required this.time, 
    required this.jadwal,
    required this.prayerItemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // Logika cek waktu (jika tahun < 2024 berarti jam TV belum sinkron)
    bool isTimeValid = DateTime.now().year >= 2024;

    return Stack(
      children: [
        // --- LAYER 1: KONTEN UTAMA ---
        Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(time, style: const TextStyle(fontSize: 110, fontWeight: FontWeight.w900, letterSpacing: -5)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Text("MASJID AL HIJRAH CGE", style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold)),
                      Text("Cimanggis Golf Estate", style: TextStyle(fontSize: 24, color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Grid Jadwal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    height: 165, 
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: jadwal.entries.map((e) => prayerItemBuilder(e.key, e.value)).toList(),
                    ),
                  ),
                ),
              ),
            ),
            // Running Text
            Container(
              height: 35, width: double.infinity, color: Colors.black.withOpacity(0.8),
              child: Marquee(
                text: 'Selamat Datang di Masjid Al Hijrah CGE - Jagalah Kebersihan dan Matikan Handphone saat Sholat - ',
                style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                velocity: 45.0,
              ),
            ),
          ],
        ),

        // --- LAYER 2: OVERLAY PERINGATAN (Hanya muncul jika jam salah) ---
        if (!isTimeValid)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.85), // Gelapkan background
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 100),
                      const SizedBox(height: 20),
                      const Text(
                        "JAM TV BELUM DIATUR!",
                        style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Tahun terdeteksi: ${DateTime.now().year}\nJadwal sholat tidak akan muncul sebelum jam TV sinkron.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
