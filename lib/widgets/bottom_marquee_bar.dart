import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:provider/provider.dart';

import '../providers/config_provider.dart';

class BottomMarqueeBar extends StatelessWidget {
  final String? text;
  final double fontSize;
  final double velocity;

  const BottomMarqueeBar({
    super.key,
    this.text,
    this.fontSize = 22,
    this.velocity = 45.0,
  });

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();
    final String showMarqueeText = text ?? config.marqueeText;

    return Container(
      height: 35,
      width: double.infinity,
      color: Colors.black.withValues(alpha: 0.5),
      child: Marquee(
        text: showMarqueeText,
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        velocity: velocity,
      ),
    );
  }
}
