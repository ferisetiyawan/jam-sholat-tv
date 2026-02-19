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
    String minutes = (countdown ~/ 60).toString().padLeft(2, '0');
    String seconds = (countdown % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: Colors.transparent, // Agar background wrapper kelihatan
      body: Center(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Sesuai isi konten
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("MENUJU IQOMAH", style: TextStyle(fontSize: 35, fontWeight: FontWeight.w300, letterSpacing: 8)),
                Text(namaSholat.toUpperCase(), style: const TextStyle(fontSize: 25, color: Colors.white70)),
                
                // Menggunakan FittedBox agar teks jam tidak overflow
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "$minutes:$seconds",
                      style: const TextStyle(
                        fontSize: 250, // Ukuran target
                        fontWeight: FontWeight.w900, 
                        color: Colors.greenAccent, 
                        fontFeatures: [FontFeature.tabularFigures()],
                        height: 1.1, // Mengurangi spasi vertikal teks
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