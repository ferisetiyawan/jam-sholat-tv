import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../core/widgets/background_image.dart';
import '../../core/widgets/bottom_marquee_bar.dart';
import '../../core/widgets/side_prayer_panel.dart';

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
          const BackgroundImage(),

          Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SidePrayerPanel(
                      time: widget.time,
                      dateMasehi: widget.dateMasehi,
                      dateHijriah: widget.dateHijriah,
                      jadwal: widget.jadwal,
                      nextPrayerName: widget.nextPrayerName,
                    ),

                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(5, 15, 15, 15),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 30,
                              color: Colors.black.withValues(alpha: 0.5),
                            ),
                          ],
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

              const BottomMarqueeBar(),
            ],
          ),
        ],
      ),
    );
  }
}
