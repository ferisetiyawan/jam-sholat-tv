import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:marquee/marquee.dart';

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
      body: Stack(
        children: [
          // --- LAYER 1: BACKGROUND IMAGE ---
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background_masjid.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // --- LAYER 2: MAIN CONTENT ---
          Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- LEFT: TIME, DATE, PRAYER SCHEDULE ---
                    Container(
                      width: MediaQuery.of(context).size.width * 0.33,
                      padding: const EdgeInsets.all(15),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  "Masjid Al Hijrah CGE",
                                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    child: Text(
                                      widget.time,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, height: 1.0),
                                    ),
                                  ),
                                ),
                                FittedBox(
                                  child: Column(
                                    children: [
                                      Text(widget.dateHijriah, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                                      Text(widget.dateMasehi, style: TextStyle(color: Colors.white, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
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
                      ),
                    ),

                    // --- RIGHT: VIDEO ---
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(5, 15, 15, 15),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [BoxShadow(blurRadius: 30, color: Colors.black.withValues(alpha: 0.5))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: YoutubePlayer(controller: _controller),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- LAYER 3: RUNNING TEXT ---
              Container(
                height: 40,
                width: double.infinity,
                color: Colors.black.withValues(alpha: 0.8),
                child: Marquee(
                  text: 'Selamat Datang di Masjid Al Hijrah CGE - Jagalah Kebersihan dan Matikan Handphone saat Sholat - ',
                  style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                  velocity: 45.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerItem(String label, String time) {
    bool isNext = label == widget.nextPrayerName;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: isNext ? Colors.amber.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNext ? Colors.amber : Colors.white.withValues(alpha: 0.1),
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
                  color: isNext ? Colors.white : Colors.white38,
                  fontSize: 14,
                  fontWeight: isNext ? FontWeight.w900 : FontWeight.bold
                ),
              ),
            ],
          ),
          Text(
            time,
            style: TextStyle(
              color: isNext ? Colors.white : Colors.white38,
              fontSize: 14,
              fontWeight: FontWeight.w900
            ),
          ),
        ],
      ),
    );
  }
}
