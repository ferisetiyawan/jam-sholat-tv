import 'dart:async';
import 'package:flutter/material.dart';

class IqomahScreen extends StatefulWidget {
  final String namaSholat;
  final VoidCallback onFinished; // Fungsi untuk kembali ke layar utama setelah iqomah

  const IqomahScreen({
    super.key, 
    required this.namaSholat, 
    required this.onFinished
  });

  @override
  State<IqomahScreen> createState() => _IqomahScreenState();
}

class _IqomahScreenState extends State<IqomahScreen> {
  late int _secondsRemaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Logika durasi: Subuh 15 menit (900 detik), lainnya 10 menit (600 detik)
    if (widget.namaSholat.toLowerCase() == 'subuh') {
      _secondsRemaining = 15 * 60;
    } else {
      _secondsRemaining = 10 * 60;
    }
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        widget.onFinished(); // Kembali ke jadwal utama
      }
    });
  }

  // Fungsi untuk memformat detik menjadi MM:SS
  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg_iqomah.jpg'), // Gambar masjid gelap (Screen 2)
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.darken),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
               padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
               decoration: BoxDecoration(
                 color: Colors.green,
                 borderRadius: BorderRadius.all(Radius.circular(20))
               ),
               child: Text("PANGGILAN SHALAT", style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
            const SizedBox(height: 20),
            Text(
              "Menuju Iqomah Shalat ${widget.namaSholat}",
              style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            // Tampilan Counter Besar
            Text(
              _formatTime(_secondsRemaining),
              style: const TextStyle(
                color: Color(0xFF00FF88), // Warna hijau neon sesuai desain
                fontSize: 200,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.greenAccent, blurRadius: 20)],
              ),
            ),
            const SizedBox(height: 20),
            const Text("MASJID AL HIJRAH", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const Text("CIMANGGIS GOLF ESTATE", style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 50),
            // Footer Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFooterIcon(Icons.format_align_center, "LURUSKAN & RAPATKAN SHAF"),
                _buildFooterIcon(Icons.phonelink_ring_sharp, "MATIKAN/HENINGKAN HANDPHONE"),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFooterIcon(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 40),
        const SizedBox(height: 10),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
