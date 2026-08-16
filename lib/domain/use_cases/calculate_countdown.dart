import '../models/countdown_result.dart';

/// Computes the next upcoming prayer and the remaining countdown from a jadwal
/// (prayer times) map.
///
/// The `jadwal` map always keys Friday's prayer as `"Dzuhur"`; on Fridays the
/// displayed label is translated to `"Jumat"`.
class CalculateCountdown {
  /// [now] is injectable for deterministic testing; defaults to `DateTime.now()`.
  CountdownResult call(Map<String, String> jadwal, {DateTime? now}) {
    final current = now ?? DateTime.now();
    DateTime? nextTime;
    String nextName = "";

    bool isFriday = current.weekday == DateTime.friday;

    List<String> order = [
      "Subuh",
      "Syuruq",
      isFriday ? "Jumat" : "Dzuhur",
      "Ashar",
      "Maghrib",
      "Isya",
    ];

    for (String name in order) {
      String? t = jadwal[name] ?? (name == "Jumat" ? jadwal["Dzuhur"] : null);

      if (t == null || t == "--:--" || t.isEmpty) continue;

      final parts = t.split(':');
      var pTime = DateTime(
        current.year,
        current.month,
        current.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );

      if (pTime.isAfter(current)) {
        nextTime = pTime;
        nextName = name;
        break;
      }
    }

    if (nextTime == null) {
      nextName = "Subuh";
      String? t = jadwal["Subuh"];
      if (t != null && t != "--:--") {
        final parts = t.split(':');
        nextTime = DateTime(
          current.year,
          current.month,
          current.day + 1,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      }
    }

    String countdown = "00:00:00";
    if (nextTime != null) {
      final diff = nextTime.difference(current);
      String h = diff.inHours.toString().padLeft(2, '0');
      String m = (diff.inMinutes % 60).toString().padLeft(2, '0');
      String s = (diff.inSeconds % 60).toString().padLeft(2, '0');
      countdown = "$h:$m:$s";
    }

    return CountdownResult(nextName: nextName, countdown: countdown);
  }
}
