import 'dart:async';
import 'package:flutter/material.dart';

class AdzanScreen extends StatefulWidget {
  final String namaSholat; // Contoh: "MAGHRIB"
  final VoidCallback onFinished; // Fungsi untuk pindah ke Iqomah setelah selesai

  const AdzanScreen({
    super.key, 
    required this.namaSholat, 
    required this.onFinished
  });

  @override
  State<AdzanScreen> createState() => _AdzanScreenState();
}

class _AdzanScreenState extends State<AdzanScreen> {
  double _progress = 0.0;
  late Timer _timer;
  final int _durasiAdzanDetik = 180; // Kita set durasi adzan 3 menit (180 detik)

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_progress < 1.0) {
          _progress += 1 / _durasiAdzanDetik;
        } else {
          _timer.cancel();
          widget.onFinished(); // Pindah ke layar Iqomah
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Background gelap seperti desain
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg_adzan.jpg'), // Sesuaikan dengan file gambar Anda
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.7), BlendMode.darken),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.volume_up, color: Colors.green, size: 80),
              const SizedBox(height: 30),
              const Text(
                "ADZAN SEDANG BERKUMANDANG",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 40),
              // Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 100),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 15,
                    backgroundColor: Colors.grey[800],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "Mari menjawab adzan dan menghentikan aktivitas sejenak",
                style: TextStyle(color: Colors.white70, fontSize: 24),
              ),
              const SizedBox(height: 60),
              const Text("WAKTU SHOLAT", style: TextStyle(color: Colors.white54, fontSize: 18)),
              Text(
                widget.namaSholat.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
