import 'package:flutter/material.dart';

class PrayerCard extends StatelessWidget {
  final String label;
  final String time;
  final bool isNext;
  final String countdown;

  const PrayerCard({
    super.key,
    required this.label,
    required this.time,
    this.isNext = false,
    this.countdown = "",
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          color: isNext
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isNext
                    ? Colors.white
                    : const Color.fromARGB(150, 0, 0, 0),
              ),
            ),
            Text(
              time,
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: isNext
                    ? Colors.white
                    : const Color.fromARGB(150, 0, 0, 0),
              ),
            ),
            if (isNext)
              Text(
                "-$countdown",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
