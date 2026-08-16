# Data Sources

The app is **fully offline**: the prayer schedule is computed entirely on-device, and every runtime duration/config value is a fixed local `AppConstants` constant. There is no local database and no persistence layer.

## 1. Prayer schedules (computed locally — no network)

Prayer times are **calculated on-device** with the `adhan_dart` package using the **Kemenag (Indonesian) method**, so this feature needs no internet connection and no bundled schedule data.

The method parameters are constants in `AppConstants` (`lib/core/constants/app_constants.dart`):

| Constant | Value |
| --- | --- |
| `latitude` / `longitude` | Depok: `-6.40` / `106.82` (fine-tune to the masjid's exact position) |
| `fajrAngle` | `20.0` |
| `ishaAngle` | `18.0` |
| `madhab` | `Madhab.shafi` |
| `ihtiyat` | `{'imsak': 2, 'subuh': 2, 'terbit': -3, 'dhuhur': 3, 'ashar': 2, 'maghrib': 3, 'isya': 2}` |

`CalculatePrayerTimes` (`lib/domain/use_cases/calculate_prayer_times.dart`) is the pure use case behind `PrayerRepository`:

1. Build `CalculationMethodParameters.other()` and set `fajrAngle` / `ishaAngle` / `madhab` from the constants.
2. Call `PrayerTimes(coordinates:, date: DateTime.utc(y, m, d), calculationParameters:, precision: true)`.
3. Apply the Kemenag **ihtiyat** rule to each raw time: shift by the per-prayer minutes, then round leftover seconds **up** to the next minute (ceil) for the five salat times and **down** (floor, drop seconds) for terbit/Syuruq. (Imsak = fajr − 10 min, but the app's contract has no imsak slot, so it is not emitted.)
4. Return the canonical map — `{ "Subuh", "Syuruq", "Dzuhur", "Ashar", "Maghrib", "Isya" }` with `HH:mm` values, where the package's `sunrise` becomes the app's **`Syuruq`** key.

Times are computed in UTC and read with `.toLocal()`, so they land on the device wall clock (WIB/WITA/WIT). The jadwal is recomputed at launch (`AppProvider.loadInitialData`) and again at every midnight (`_handleMidnightSync`).

## 2. Config — fixed local constants (no fetch)

The remote Google Apps Script config endpoint was **removed**. All durations, `hijriCorrection`, marquee text, and the background image now come from `AppConstants` (`lib/core/constants/app_constants.dart`) via `AppConfig.defaults()` and are served by `ConfigProvider`:

```
homeDuration, eventDuration, reportDuration, adzanDuration, jumatDuration,
shalatDuration, isyraqDuration, hijriCorrection (clamped to [-2, 2]),
waitingIsyraqDuration, iqomahSubuhDuration, iqomahMaghribRamadhanDuration,
iqomahDefaultDuration, minutesBeforeMaghrib, minutesBeforeJumat,
marqueeText, backgroundImage
```

`eventImages` is always empty, so the event screen / announcement feature never activates; the marquee and background render the bundled defaults.

## 3. Financial report — dormant (no fetch)

The financial summary endpoint is **no longer called**. `FinancialService` / `FinancialRepository` / `FinancialSummary` / `FinancialReportScreen` are retained in the codebase but dormant: `AppProvider.updateFinancialReport()` has no call sites, so `financialSummary` stays null and report mode never activates. The keys it would consume: `saldoAwal`, `kasmasuk`, `kasKeluar`, `saldoAkhir`, `saldoPrasarana`, `saldoNonPrasarana` (amounts formatted as IDR).

## 4. Live Makkah stream

`LiveMakkahScreen` hardcodes the YouTube video id `Cm1v4bteXbI` (muted, autoplay, live) via `youtube_player_flutter`. Shown when `isSpecialLiveMode` = within `minutesBeforeMaghrib`/`minutesBeforeJumat` (default 30) before the prayer **and** online.

## 5. Audio

`AudioService` is a single static `AudioPlayer` playing the bundled `assets/sounds/beep_adzan.wav` and `beep_iqomah.wav`. Adzan beep at: adzan start, shalat start, isyraq start. Iqomah beep at ≤10s remaining in iqomah.
