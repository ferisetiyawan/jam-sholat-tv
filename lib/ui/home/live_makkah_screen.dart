import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/background_image.dart';
import '../../core/widgets/bottom_marquee_bar.dart';
import '../../core/widgets/side_prayer_panel.dart';

class LiveMakkahScreen extends StatefulWidget {
  final String time;
  final Map<String, String> jadwal;
  final String dateMasehi;
  final String dateHijriah;
  final String nextPrayerName;
  final String masjidName;

  /// YouTube URL of the live Makkah stream, editable via the dashboard. Falls
  /// back to [AppConstants.liveMakkahUrl] when unparseable.
  final String liveMakkahUrl;

  const LiveMakkahScreen({
    super.key,
    required this.time,
    required this.dateMasehi,
    required this.dateHijriah,
    required this.jadwal,
    required this.nextPrayerName,
    required this.masjidName,
    required this.liveMakkahUrl,
  });

  @override
  State<LiveMakkahScreen> createState() => _LiveMakkahScreenState();
}

class _LiveMakkahScreenState extends State<LiveMakkahScreen> {
  late final YoutubePlayerController _controller;

  /// The player widget is created exactly once and cached. The parent screen
  /// is rebuilt every second (the app's clock tick), but returning the same
  /// widget instance lets Flutter short-circuit and never re-lay-out the
  /// WebView platform view; the [RepaintBoundary] keeps it compositing on its
  /// own layer too.
  late final Widget _player;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: _resolveVideoId(widget.liveMakkahUrl),
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: true,
        isLive: true,
        hideControls: true,
      ),
    );
    _player = RepaintBoundary(
      child: YoutubePlayer(controller: _controller),
    );
  }

  /// Extracts the video ID from the configured YouTube URL. Accepts a full
  /// watch/share URL or a bare 11-char video ID; falls back to the bundled
  /// default when the value is unparseable.
  String _resolveVideoId(String url) {
    final String trimmed = url.trim();
    if (RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(trimmed)) return trimmed;
    final String? fromUrl = YoutubePlayer.convertUrlToId(trimmed);
    if (fromUrl != null && fromUrl.isNotEmpty) return fromUrl;
    return YoutubePlayer.convertUrlToId(AppConstants.liveMakkahUrl) ?? '';
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
                      masjidName: widget.masjidName,
                    ),

                    // Deliberately decoration-free: a rounded ClipRRect (or any
                    // opacity / shadow) around a WebView kicks Flutter off the
                    // fast native "surface" path into per-frame GPU texture
                    // compositing, which stutters live video on the TV. A plain
                    // rectangle keeps the WebView compositing natively at 30fps.
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(5, 15, 15, 15),
                        child: _player,
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
