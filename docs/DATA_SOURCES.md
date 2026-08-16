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
marqueeText, backgroundImage, enableFinancialReport
```

`eventImages` is always empty, so the event screen / announcement feature never activates; the marquee and background render the bundled defaults.

## 3. Financial report — offline sample data (no fetch)

The financial summary endpoint is **never called**. `FinancialService` / `FinancialRepository` / `AppProvider.updateFinancialReport()` are retained in the codebase but have no call sites. Instead, `AppProvider.financialSummary` is initialized with `FinancialSummary.offlineSample()` (`lib/domain/models/financial_summary.dart`), which parses hard-coded JSON — edit those values to change what the TV displays.

On the home screen the report is shown during the `reportDuration` slice of the idle cycle (`isReportMode`), so it **alternates with the clock+schedule** (`homeDuration` → event (always 0) → report → repeat). Setting `AppConstants.enableFinancialReport` to `false` removes the report slice entirely (the clock+schedule runs alone).

Current offline sample shape (all amounts parsed as `double`; dates are ISO 8601 UTC and rendered `.toLocal()` — `17:00Z` is `00:00` the next day WIB):

| Key | Value | Meaning |
| --- | --- | --- |
| `saldoKasDate` | `2026-06-03T17:00:00.000Z` | balance recorded date (4 Juni 2026 WIB) |
| `totalKasMasjid` | `121381630` | total kas balance |
| `weeklyIncome` | array of 5 | weekly income entries |

Each `weeklyIncome` entry:

| Key | Example | Meaning |
| --- | --- | --- |
| `periodeStart` | `2026-04-30T17:00:00.000Z` | week start (1 Mei 2026 WIB) |
| `periodeEnd` | `2026-05-06T17:00:00.000Z` | week end (7 Mei 2026 WIB) |
| `pemasukan` | `2050000` | week's income (Rp2.050.000) |

The sample's five weeks run 1–7, 8–14, 15–21, 22–28 Mei and 29 Mei–4 Juni 2026.

## 4. Live Makkah stream

`LiveMakkahScreen` hardcodes the YouTube video id `Cm1v4bteXbI` (muted, autoplay, live) via `youtube_player_flutter`. Shown when `isSpecialLiveMode` = within `minutesBeforeMaghrib`/`minutesBeforeJumat` (default 30) before the prayer **and** online.

## 5. Audio

`AudioService` is a single static `AudioPlayer` playing the bundled `assets/sounds/beep_adzan.wav` and `beep_iqomah.wav`. Adzan beep at: adzan start, shalat start, isyraq start. Iqomah beep at ≤10s remaining in iqomah.

## 6. Local config server (LAN-only editing)

An embedded `shelf` HTTP server (`lib/services/local_server_service.dart`) binds to `0.0.0.0:8080` on every launch (started in `main.dart`), so settings can be edited from any browser on the same Wi-Fi without rebuilding the app.

**Reaching it:** on the TV, long-press the remote's **OK** (or press **Menu**) → the `ConfigMenuScreen` shows a QR code of `http://<tv-ip>:8080?token=<token>`. Scanning it (or opening the URL) loads the editor at `/`.

**Auth:** every `/api/*` call must include the per-device token — `?token=…` or `Authorization: Bearer …`. The token is generated once with `Random.secure()`, persisted under `config_auth_token`, and validated with constant-time comparison. The static editor page is public, but its JS reads the token from the URL and sends it on every request, so a token-less browser sees an unusable page and `401`s on the API.

**Endpoints:**

| Method | Path | Behavior |
| --- | --- | --- |
| `GET` | `/api/config` | Current effective config (`AppConfig.toJson()`) plus an `eventImage` string passthrough (persisted separately; event mode is dormant). |
| `POST` | `/api/config` | Parse JSON → validate (durations ≥ 0, `hijriCorrection` clamped) → persist to `SharedPreferences` → hot-apply via `ConfigProvider.applyConfig`. Malformed body or negative duration → `400`. |
| any | `/` (fallback) | The editor UI from `assets/web/` — `shelf_static` when the folder is on disk (dev/tests), else a `rootBundle` fallback (Android release). |

**Persistence:** saved config is stored as one JSON object under `ConfigProvider.configPrefsKey` (`app_config_json`) in `SharedPreferences`; `ConfigProvider.load()` merges it over `AppConstants` defaults at startup, so saved settings survive relaunch. `hijriCorrection` is clamped to `[-2, 2]`.

The `network_info_plus` helper (`lib/services/network_info_helper.dart`) resolves the LAN IPv4 for the URL/QR; it needs `ACCESS_WIFI_STATE` (already in the manifest).
