import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class LiveMakkahScreen extends StatefulWidget {
  final String time;
  final Map<String, String> jadwal;
  final String dateMasehi;
  final String dateHijriah;
  final String nextPrayerName;

  const LiveMakkahScreen({
    super.key,
    required this.time,
    required this.dateMasehi,
    required this.dateHijriah,
    required this.jadwal,
    required this.nextPrayerName,
  });

  @override
  State<LiveMakkahScreen> createState() => _LiveMakkahScreenState();
}

class _LiveMakkahScreenState extends State<LiveMakkahScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: 'Cm1v4bteXbI',
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: true,
        isLive: true,
        hideControls: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch, 
          children: [
            
            // 1. KOTAK KIRI (JAM & JADWAL)
            Expanded(
              flex: 3,
              child: _buildGlassBox(
                child: Column(
                  children: [
                    const Text(
                      "Masjid Al Hijrah CGE",
                      style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Expanded(
                      flex: 4,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Text(
                          widget.time,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, height: 1.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    FittedBox(
                      child: Column(
                        children: [
                          Text(widget.dateHijriah, style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.w600)),
                          Text(widget.dateMasehi, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Expanded(
                      flex: 10,
                      child: Column(
                        children: widget.jadwal.entries.map((e) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: _buildPrayerItem(e.key, e.value),
                          ),
                        )).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 20),

            // 2. KOTAK KANAN (VIDEO PLAYER)
            Expanded(
              flex: 7,
              child: _buildGlassBox(
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: YoutubePlayer(
                      controller: _controller,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassBox({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2), 
              width: 1.5
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildPrayerItem(String label, String time) {
    bool isNext = label == widget.nextPrayerName;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: isNext ? Colors.amber.withOpacity(0.3) : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNext ? Colors.amber : Colors.white.withOpacity(0.1),
          width: isNext ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.access_time_filled, color: isNext ? Colors.amber : Colors.white38, size: 18),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 14,
                  fontWeight: isNext ? FontWeight.w900 : FontWeight.bold
                ),
              ),
            ],
          ),
          Text(
            time,
            style: TextStyle(
              color: isNext ? Colors.white : Colors.amber,
              fontSize: 14,
              fontWeight: FontWeight.w900
            ),
          ),
        ],
      ),
    );
  }
}
