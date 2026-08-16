import 'package:flutter_test/flutter_test.dart';
import 'package:jam_sholat_tv/domain/use_cases/calculate_countdown.dart';

void main() {
  const jadwal = {
    "Subuh": "04:30",
    "Syuruq": "06:00",
    "Dzuhur": "12:10",
    "Ashar": "15:30",
    "Maghrib": "18:15",
    "Isya": "19:30",
  };

  late CalculateCountdown calculator;

  setUp(() => calculator = CalculateCountdown());

  test('returns the next prayer after the current time', () {
    // Sunday 2026-08-16 10:00, between Syuruq and Dzuhur.
    final now = DateTime(2026, 8, 16, 10, 0, 0);

    final result = calculator(jadwal, now: now);

    expect(result.nextName, 'Dzuhur');
    expect(result.countdown, '02:10:00');
  });

  test('rolls over to tomorrow Subuh once all prayers have passed', () {
    // Sunday 2026-08-16 20:00, after Isya.
    final now = DateTime(2026, 8, 16, 20, 0, 0);

    final result = calculator(jadwal, now: now);

    expect(result.nextName, 'Subuh');
    expect(result.countdown, '08:30:00');
  });

  test('labels the Friday prayer as Jumat', () {
    // Friday 2026-08-21 10:00.
    final now = DateTime(2026, 8, 21, 10, 0, 0);

    final result = calculator(jadwal, now: now);

    expect(result.nextName, 'Jumat');
  });

  test('skips entries that are not set (--:--)', () {
    final sparse = {
      "Subuh": "--:--",
      "Syuruq": "--:--",
      "Dzuhur": "12:10",
      "Ashar": "15:30",
      "Maghrib": "18:15",
      "Isya": "19:30",
    };
    final now = DateTime(2026, 8, 16, 10, 0, 0);

    final result = calculator(sparse, now: now);

    expect(result.nextName, 'Dzuhur');
    expect(result.countdown, '02:10:00');
  });

  test('falls back to 00:00:00 when no schedule is available', () {
    final empty = <String, String>{};

    final result = calculator(empty);

    expect(result.nextName, 'Subuh');
    expect(result.countdown, '00:00:00');
  });
}
