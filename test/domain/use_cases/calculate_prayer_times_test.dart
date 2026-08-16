import 'package:flutter_test/flutter_test.dart';
import 'package:jam_sholat_tv/domain/use_cases/calculate_prayer_times.dart';

void main() {
  const calculator = CalculatePrayerTimes();

  /// 2026-08-16 is a Sunday.
  final now = DateTime(2026, 8, 16, 10, 0, 0);

  int toMinutes(String t) {
    final p = t.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  /// Forward distance in minutes from [a] to [b] on a 24h circle.
  int circularGap(int a, int b) => (b - a + 1440) % 1440;

  test('returns exactly the canonical keys in insertion order', () {
    final result = calculator(now: now);

    expect(result.keys.toList(), [
      'Subuh',
      'Syuruq',
      'Dzuhur',
      'Ashar',
      'Maghrib',
      'Isya',
    ]);
  });

  test('every value is a valid HH:mm string', () {
    final result = calculator(now: now);

    for (final v in result.values) {
      expect(RegExp(r'^\d{2}:\d{2}$').hasMatch(v), isTrue, reason: v);
    }
  });

  test('prayers appear in chronological order around the day', () {
    // `.toLocal()` shifts wall-clock times by the test machine's timezone, so
    // the sequence may wrap midnight (e.g. on a UTC machine). The circular
    // forward gap between consecutive prayers is timezone-invariant: positive
    // and always less than half a day.
    final result = calculator(now: now);
    final minutes = result.values.map(toMinutes).toList();

    for (var i = 0; i < minutes.length; i++) {
      final gap =
          circularGap(minutes[i], minutes[(i + 1) % minutes.length]);
      expect(gap, greaterThan(0));
      expect(gap, lessThan(720));
    }
  });

  test('is deterministic for the same instant', () {
    expect(calculator(now: now), calculator(now: now));
  });

  test('prayer times shift only slightly between consecutive days', () {
    final day1 = calculator(now: DateTime(2026, 8, 16, 10, 0));
    final day2 = calculator(now: DateTime(2026, 8, 17, 10, 0));

    for (final key in day1.keys) {
      final diff = (toMinutes(day2[key]!) - toMinutes(day1[key]!)).abs();
      expect(diff, lessThan(5), reason: '$key drift');
    }
  });

  test('method sanity: maghrib→isya and dzuhur→ashar gaps are plausible', () {
    final result = calculator(now: now);

    final ishaMaghrib = circularGap(
      toMinutes(result['Maghrib']!),
      toMinutes(result['Isya']!),
    );
    expect(ishaMaghrib, inInclusiveRange(45, 120));

    final asharDzuhur = circularGap(
      toMinutes(result['Dzuhur']!),
      toMinutes(result['Ashar']!),
    );
    expect(asharDzuhur, inInclusiveRange(90, 240));
  });
}
