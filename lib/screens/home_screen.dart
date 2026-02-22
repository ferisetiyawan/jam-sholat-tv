import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

class HomeScreen extends StatelessWidget {
  final String time;
  final Map<String, String> jadwal;
  final String dateMasehi;
  final String dateHijriah;
  final Widget Function(String, String) prayerItemBuilder;

  const HomeScreen({
    super.key, 
    required this.time, 
    required this.dateMasehi,
    required this.dateHijriah,
    required this.jadwal,
    required this.prayerItemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    bool isTimeValid = DateTime.now().year >= 2025;

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
                crossAxisAlignment: CrossAxisAlignment.start, // Agar rata atas
                children: [
                  // --- BAGIAN KIRI: JAM & TANGGAL ---
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        time, 
                        style: const TextStyle(
                          fontSize: 110,
                          fontWeight: FontWeight.w900, 
                          letterSpacing: -5,
                          height: 1.0, // Mengurangi spasi bawah bawaan font
                        )
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dateHijriah,
                        style: const TextStyle(
                          fontSize: 26, 
                          color: Colors.amber, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      Text(
                        dateMasehi,
                        style: const TextStyle(
                          fontSize: 22, 
                          color: Colors.white70,
                          fontWeight: FontWeight.w500
                        ),
                      ),
                    ],
                  ),
                  
                  // --- BAGIAN KANAN: NAMA MASJID ---
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
                borderRadius: BorderRadius.circular(8),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    height: 110, 
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
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
              height: 35, width: double.infinity, color: Colors.black.withValues(alpha: 0.8),
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
            color: Colors.black.withValues(alpha: 0.85),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.8),
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
