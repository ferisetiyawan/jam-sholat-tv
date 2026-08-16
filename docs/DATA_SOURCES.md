# Data Sources

The app is **offline-first**: the prayer schedule is computed entirely on-device, and everything else runs from a SharedPreferences cache with network calls only as fallback/refresh. There is no local database — SharedPreferences holds only the config cache.

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

## 2. Remote config + event images (Google Apps Script)

```
GET https://script.google.com/macros/s/AKfycbw4Gp-TV5gmqsBWfFmHYPW5d7_1nBRiAmfEbTBOxWEqzHDnOzUkxhASZ2Bq8m6VgnEZdg/exec?action=config
```

Returns `{ "data": { ... } }` with any subset of the config keys (all optional, missing → `AppConstants` defaults):

```
homeDuration, eventDuration, reportDuration, adzanDuration, jumatDuration,
shalatDuration, isyraqDuration, hijriCorrection (clamped to [-2, 2]),
waitingIsyraqDuration, iqomahSubuhDuration, iqomahMaghribRamadhanDuration,
iqomahDefaultDuration, minutesBeforeMaghrib, minutesBeforeJumat,
eventImages: [{ type: "IMAGE|SVG", url: "..." }],
backgroundImage, marqueeText
```

**Event image sync** (`ConfigRemoteService._syncAssets`): remote `url`s starting with `http` are downloaded to the app documents dir as `event_<url.hashCode>.<ext>` (ext from `type`). Files with the `event_` prefix not in the current list are deleted. The in-memory `url` is rewritten to the local file path, so `EventScreen` prefers the local file and only falls back to network/asset rendering (see `_buildSmartImage` — it handles asset paths, local files, network, and SVG/bitmap).

**Cache** — the merged config is stored in SharedPreferences under `local_config_cache`; failures fall back to it, then to defaults.

## 3. Financial report (Google Apps Script)

```
GET https://script.google.com/macros/s/AKfycbxjhZLpG3gFOljisTYxaeM81jzkP1NILR61jsHbiQGHqOvL_1cQu6ZkPqGts-tY3DwWyg/exec?action=summary
```

Returns `{ "data": { ... } }` consumed by `FinancialService.fetchSummary` and rendered by `FinancialReportScreen`. Keys used: `saldoAwal`, `kasmasuk`, `kasKeluar`, `saldoAkhir`, `saldoPrasarana`, `saldoNonPrasarana` (amounts formatted as IDR).

Only fetched when internet is up; report mode on the home screen only activates when `AppProvider.financialSummary` is non-null.

## 4. Live Makkah stream

`LiveMakkahScreen` hardcodes the YouTube video id `Cm1v4bteXbI` (muted, autoplay, live) via `youtube_player_flutter`. Shown when `isSpecialLiveMode` = within `minutesBeforeMaghrib`/`minutesBeforeJumat` (default 30) before the prayer **and** online.

## 5. Audio

`AudioService` is a single static `AudioPlayer` playing the bundled `assets/sounds/beep_adzan.wav` and `beep_iqomah.wav`. Adzan beep at: adzan start, shalat start, isyraq start. Iqomah beep at ≤10s remaining in iqomah.

## Persistence keys (SharedPreferences)

| Key | Contents |
| --- | --- |
| `local_config_cache` | JSON of the merged remote config |
