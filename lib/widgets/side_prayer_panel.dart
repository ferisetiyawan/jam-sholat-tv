import 'dart:ui';

import 'package:flutter/material.dart';

class SidePrayerPanel extends StatelessWidget {
  final String time;
  final String dateMasehi;
  final String dateHijriah;
  final Map<String, String> jadwal;
  final String nextPrayerName;

  const SidePrayerPanel({
    super.key,
    required this.time,
    required this.dateMasehi,
    required this.dateHijriah,
    required this.jadwal,
    required this.nextPrayerName,
  });

  @override
  Widget build(BuildContext context) {
    final isFriday = DateTime.now().weekday == DateTime.friday;

    return Container(
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
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  "Masjid Al Hijrah CGE",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Text(
                      time,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
                FittedBox(
                  child: Column(
                    children: [
                      Text(
                        dateHijriah,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        dateMasehi,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  flex: 10,
                  child: Column(
                    children: jadwal.entries.map((e) {
                      String label = e.key;
                      if (isFriday && label == "Dzuhur") {
                        label = "Jumat";
                      }
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: _buildPrayerItem(label, e.value),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerItem(String label, String time) {
    bool isNext = label == nextPrayerName;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: isNext
            ? Colors.amber.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.08),
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
              Icon(
                Icons.access_time_filled,
                color: isNext ? Colors.amber : Colors.white38,
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isNext ? Colors.white : Colors.white38,
                  fontSize: 14,
                  fontWeight: isNext ? FontWeight.w900 : FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            time,
            style: TextStyle(
              color: isNext ? Colors.white : Colors.white38,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
