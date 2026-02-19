import 'package:flutter/material.dart';

class AdzanScreen extends StatelessWidget {
  final String namaSholat;

  const AdzanScreen({super.key, required this.namaSholat});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.mosque, size: 100, color: Colors.greenAccent),
          const SizedBox(height: 30),
          const Text(
            "WAKTU ADZAN BERKUMANDANG",
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.w300, letterSpacing: 10),
          ),
          const SizedBox(height: 10),
          Text(
            namaSholat.toUpperCase(),
            style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 50),
          const Text(
            "Waktunya Berhenti Sejenak dari Aktivitas Dunia",
            style: TextStyle(fontSize: 24, fontStyle: FontStyle.italic, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
