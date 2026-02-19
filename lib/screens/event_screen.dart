import 'package:flutter/material.dart';

class EventScreen extends StatelessWidget {
  final String imageUrl;
  final String currentTime;

  const EventScreen({
    super.key,
    required this.imageUrl,
    required this.currentTime,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gambar Event Fullscreen
        Positioned.fill(
          child: Container(
            color: Colors.black,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover, // Fullscreen tanpa gepeng
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Text("Info Kegiatan Masjid", style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ),
        
        // Overlay Gradasi (Opsional: Agar jam lebih terbaca jika gambar terang)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.5),
                ],
                stops: const [0.8, 1.0],
              ),
            ),
          ),
        ),

        // Jam Kecil di Pojok Kanan Bawah
        Positioned(
          bottom: 30,
          right: 40,
          child: Text(
            currentTime,
            style: const TextStyle(
              fontSize: 45,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(blurRadius: 10, color: Colors.black, offset: Offset(2, 2))
              ],
            ),
          ),
        ),
      ],
    );
  }
}
