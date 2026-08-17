# Data Sources

The app is **fully offline**: the prayer schedule is computed entirely on-device, and every runtime duration/config value is a fixed local `AppConstants` constant. There is no local database and no persistence layer.

## 1. Prayer schedules (computed locally — no network)

Prayer times are **calculated on-device** with the `adhan_dart` package using the **Kemenag (Indonesian) method**, so this feature needs no internet connection and no bundled schedule data.

The method parameters **default to constants in `AppConstants`** (`lib/core/constants/app_constants.dart`) but are **runtime-editable**: each is an `AppConfig` field (`latitude`, `longitude`, `fajrAngle`, `ishaAngle`, `madhab`, `ihtiyat`) that can be overridden through the local config server (§6), including a city-preset dropdown in the web editor. Defaults:

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

Times are computed in UTC and read with `.toLocal()`, so they land on the device wall clock (WIB/WITA/WIT). The jadwal is recomputed at launch (`AppProvider.loadInitialData`), at every midnight (`_handleMidnightSync`), and whenever the calc params change at runtime: `AppProvider` compares a fingerprint (`_lastCalcKey`) of `latitude / longitude / fajrAngle / ishaAngle / madhab / ihtiyat` on each 1-second tick and recomputes the schedule only when it changes.

## 2. Config — fixed local constants (no remote fetch)

The remote Google Apps Script config endpoint was **removed**. All durations, `hijriCorrection`, marquee text, the background image, and the prayer-calc params now come from `AppConstants` (`lib/core/constants/app_constants.dart`) via `AppConfig.defaults()` and are served by `ConfigProvider` — and can be **overridden at runtime** through the embedded local config server (§6), which persists and hot-applies them:

```
homeDuration, eventDuration, reportDuration, adzanDuration, jumatDuration,
shalatDuration, isyraqDuration, hijriCorrection (clamped to [-2, 2]),
waitingIsyraqDuration, iqomahSubuhDuration, iqomahMaghribRamadhanDuration,
iqomahDefaultDuration, minutesBeforeMaghrib, minutesBeforeJumat,
latitude, longitude, fajrAngle, ishaAngle, madhab, ihtiyat,
marqueeText, backgroundImage, eventImages, enableFinancialReport, financialSummary
```

`eventImages` starts empty; it is populated through the config server's image uploads (§6), which **activates the event screen** on the home idle cycle. `marqueeText` and `backgroundImage` default to the bundled values and can be overridden too — `backgroundImage` is replaced by an image upload, `marqueeText` is a free-text field.

## 3. Financial report — editable via the web editor (no fetch)

The financial summary endpoint is **never called**. `FinancialService` / `FinancialRepository` / `AppProvider.updateFinancialReport()` are retained in the codebase but have no call sites. Instead the report lives **inside the config** as `financialSummary` (`AppConfig.financialSummary`, default `FinancialSummary.offlineSample()` from `lib/domain/models/financial_summary.dart`) and is edited from the browser through the **"Laporan Keuangan"** card of the web editor (§6): `totalKasMasjid`, `saldoKasDate`, and the `weeklyIncome` rows (periodeStart, periodeEnd, pemasukan) with add/remove row buttons. Saving persists + hot-applies it like any other config field; `AppProvider.financialSummary` mirrors the config value on each tick (`_syncFinancialSummaryIfNeeded`), so the TV report updates within ~1s.

On the home screen the report is shown during the `reportDuration` slice of the idle cycle (`isReportMode`), so it **alternates with the clock+schedule** (`homeDuration` → event (always 0) → report → repeat). Setting `enableFinancialReport` to `false` removes the report slice entirely (the clock+schedule runs alone).

Default offline sample shape (all amounts parsed as `double`; dates are ISO 8601 UTC and rendered `.toLocal()` — `17:00Z` is `00:00` the next day WIB):

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

**Auth:** every `/api/*` call must include the per-device token — `?token=…` or `Authorization: Bearer …`. The token is generated once with `Random.secure()`, persisted under `config_auth_token`, and validated with constant-time comparison. The static editor page is public, but its JS reads the token from the URL and sends it on every request, so a token-less browser sees an unusable page and `401`s on the API. Uploaded **images are served publicly** (`GET /images/<name>`) — only uploads/config edits need the token, so the TV can load them and the editor can preview them.

**Endpoints:**

| Method | Path | Behavior |
| --- | --- | --- |
| `GET` | `/api/config` | Current effective config (`AppConfig.toJson()`). |
| `POST` | `/api/config` | Parse JSON → validate (durations ≥ 0; `latitude` `[-90,90]`; `longitude` `[-180,180]`; `fajrAngle`/`ishaAngle` `(0,40]`) → persist to `SharedPreferences` → hot-apply via `ConfigProvider.applyConfig`. Malformed body or invalid value → `400`. |
| `POST` | `/api/upload/background` | Replace the background image. Raw image bytes in the body (≤ 10 MB, raster only: jpeg/png/webp/gif — extension from `Content-Type`, with magic-byte sniffing fallback). The old `bg_*` file is deleted and `backgroundImage` becomes `http://127.0.0.1:8080/images/bg_<ts>.<ext>`. Too large → `413`, empty → `400`, non-raster → `415`. |
| `POST` | `/api/upload/event` | Add an event image (same body rules, `ev_<ts>.<ext>`). `400` when already at the 10-image cap. |
| `DELETE` | `/api/event/<index>` | Remove the event image at `index` (`400` non-numeric, `404` out of range). The local file is deleted only when the URL is one the server uploaded. |
| `DELETE` | `/api/background` | Restore the bundled `AppConstants.backgroundImage` and delete all uploaded `bg_*` files. |
| `GET` | `/images/<name>` | **Public** — serves an uploaded image (no token), path-traversal guarded (`404` on `..`/nested names). |
| any | `/` (fallback) | The editor UI from `assets/web/` — `shelf_static` when the folder is on disk (dev/tests), else a `rootBundle` fallback (Android release). |

**Persistence:** saved config is stored as one JSON object under `ConfigProvider.configPrefsKey` (`app_config_json`) in `SharedPreferences`; `ConfigProvider.load()` merges it over `AppConstants` defaults at startup, so saved settings survive relaunch. `hijriCorrection` is clamped to `[-2, 2]`. Uploaded images live in the app-support dir (`<app-support>/config_images`), so they survive relaunch but are cleared on uninstall.

The `network_info_plus` helper (`lib/services/network_info_helper.dart`) resolves the LAN IPv4 for the URL/QR; it needs `ACCESS_WIFI_STATE` (already in the manifest).
