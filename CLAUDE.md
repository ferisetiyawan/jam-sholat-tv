# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

**Jam Sholat TV** — a Flutter Android app for a masjid TV/display screen (Masjid Al Hijrah CGE, Depok). It shows the current time, today's prayer schedule, and a live countdown to the next prayer, then cycles through full-screen states as each prayer time arrives: **Adzan** → **Iqomah** → **Shalat**, with a dedicated **Jumat** state on Friday and an **Isyraq** countdown after Syuruq. On the home screen it alternates the clock+schedule with a **monthly financial report** fed by offline sample data (see "Data sources"). Announcement-image (event mode) screens rotate in automatically once images are uploaded through the config server (dormant until then). It plays a live Makkah YouTube stream during the 30 minutes before Maghrib / Jumat.

All UI text is Indonesian. The app runs on Android TV/tablet in landscape, fullscreen, with the screen kept awake.

## Commands

Everything is FVM-based — always prefix Flutter commands with `fvm` (Flutter 3.41.1, pinned in `.fvmrc`).

```bash
fvm flutter pub get          # install dependencies
fvm flutter run              # run on connected device/emulator
fvm flutter analyze          # static analysis (flutter_lints ^6.0.0)
fvm flutter test             # run tests (unit tests for use cases and models)
fvm flutter build apk --release      # production APK
fvm flutter build appbundle          # Play Store bundle
```

There is no `.git` workflow shortcut for this; releases go through git tags (see [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)).

## Architecture — big picture

**Everything is one big state machine driven by `AppProvider`.** A 1-second `Timer.periodic` in `AppProvider.init()` fires `_onTick()` every second; it updates the clock/date strings, then decides the app state. The current `AppStatus` decides the entire screen via a `switch` in `MainController` (`lib/app/main_controller.dart`).

```
AppStatus { home, adzan, iqomah, jumatMode, shalat, isyraq }
```

Screens are pure presentational widgets — they take data via constructor params and never own logic. The only real logic lives in:
- `lib/app/providers/app_provider.dart` — the state machine (tick, transitions, countdowns, fake-time debug tools)
- `lib/app/providers/config_provider.dart` — fixed runtime config (AppConstants defaults only, no remote fetch)
- `lib/data/repositories/` + `lib/data/services/` — data access + audio (the financial fetch pipeline is retained but never called; the report is fed by an offline sample)
- `lib/domain/` — typed models and pure use cases (countdown, iqomah durations)

Provider wiring: `ConfigProvider` (serves the fixed `AppConstants` defaults — no remote fetch) and `AppProvider` (wraps `PrayerRepository`, `FinancialRepository`, `AudioService`) are created in `main.dart` via a `MultiProvider` with `ChangeNotifierProxyProvider`. `AppProvider` reads `config` for all durations. Config is static after construction, so the getters are always non-null by the time `AppProvider._onTick` runs.

### The prayer cycle (the heart of the app)

Read `docs/STATE_MACHINE.md` for the full diagram. Summary:

- **Home** → at a prayer time (exact HH:mm match on the second) → **Adzan** (beep plays) → countdown ends → **Iqomah** (beep at ≤10s) → countdown ends → **Shalat** (beep, shows the hadith card) → countdown ends → **Home**.
- **Syuruq is special**: at Syuruq time it goes to Iqomah state with label "Syuruq" ("MENANTI ISYRAQ"), then to **Isyraq**, then Home.
- **Friday**: the Dzuhur entry is *displayed as* "Jumat" and Adzan("Jumat") → **jumatMode** (the "WAKTUNYA SHOLAT JUMAT" screen) → Home. Jumat has no iqomah stage.
- On app start, `checkInitialStatus` re-derives the current state from today's schedule so a mid-cycle restart (e.g. TV reboot during adzan) resumes in the right state.

### Friday / Jumat — fragile area, handled in several places

The `jadwal` map always keys the Friday prayer as `"Dzuhur"`, but multiple widgets/paths translate it to `"Jumat"` for display, and `"Jumat"` is translated back to `"Dzuhur"` for schedule lookups. This shows up independently in: `AppProvider._handleCycleLogic`, `AppProvider.checkInitialStatus`, `CalculateCountdown` (`lib/domain/use_cases/calculate_countdown.dart`), `PrayerCard`, and `SidePrayerPanel`. Recent changelog entries show recurring bugs here — if you touch anything Jumat-related, check all five sites.

### Durations are fixed local constants

Every duration (`homeDuration`, `adzanDuration`, `iqomah*Duration`, `shalatDuration`, `isyraqDuration`, `jumatDuration`, `minutesBeforeMaghrib`, …) defaults to the `AppConstants` values (`lib/core/constants/app_constants.dart`). The remote Google Apps Script config fetch was removed, but values **can** change at runtime through the embedded local config server (see "Local config server" below) — saved overrides are persisted and hot-applied via `ConfigProvider.applyConfig()`. In `kDebugMode` most durations are shortened to a few seconds to speed up testing.

Iqomah duration logic (`GetIqomahDuration` use case in `lib/domain/use_cases/get_iqomah_duration.dart`): Subuh = 15 min, Maghrib during Ramadhan (hijri month 9) = 15 min, otherwise 10 min; in debug = 5s. Hijri correction (`hijriCorrection`, default `-1`, clamped to [-2, 2]) is applied by adding days in `DateFormatter.getFullDate`.

### Data sources (all offline — no network, one local persistence)

1. **Prayer schedules** — computed **entirely on-device** with the `adhan_dart` package using the **Kemenag method** (fajr 20°, isha 18°, Shafi madhab). The per-prayer **ihtiyat** minutes, `fajrAngle`, `ishaAngle`, `madhab`, and the Depok coordinates default to constants in `AppConstants` (`lib/core/constants/app_constants.dart`) but are **runtime-editable** `AppConfig` fields (location incl. a city-preset dropdown in the web editor, madhab, ihtiyat, angles). `CalculatePrayerTimes` (`lib/domain/use_cases/calculate_prayer_times.dart`) produces today's canonical jadwal map (`Subuh, Syuruq, Dzuhur, Ashar, Maghrib, Isya` → `HH:mm`); it is recomputed at launch, at midnight, and whenever the calc params change at runtime (`AppProvider._refreshJadwalIfNeeded`, a per-tick fingerprint compare). No network, bundled schedules, or cache needed — see `docs/DATA_SOURCES.md`.
2. **Config (durations, marquee, background, images, calc params)** — **no longer fetched remotely**, but editable via the embedded **local config server** (`lib/services/local_server_service.dart`, port `8080`). `ConfigProvider` starts from the `AppConstants` defaults; `ConfigProvider.load()` merges any persisted override (`SharedPreferences` key `ConfigProvider.configPrefsKey`) at startup, and `POST /api/config` hot-applies changes while running. **Image uploads** (`POST /api/upload/background`, `POST /api/upload/event` up to 10, plus deletes) replace the background and populate `eventImages` — uploading at least one event image **activates event mode** on the home cycle; marquee and background default to `AppConstants.marqueeText` / `AppConstants.backgroundImage` unless overridden.
3. **Financial report** — **fed by offline sample data**. `AppProvider.financialSummary` is initialized with `FinancialSummary.offlineSample()` (hard-coded values in `lib/domain/models/financial_summary.dart`) — edit those to change what the TV shows. On the home screen the report rotates in during the `reportDuration` slice (`isReportMode`), so it alternates with the clock+schedule. It can be disabled entirely by setting `AppConstants.enableFinancialReport` to `false` (a config toggle served through `ConfigProvider`); the report slice then drops out of the idle cycle. `FinancialService` / `FinancialRepository` / `AppProvider.updateFinancialReport()` are retained but never called (no network).

There is **no cloud/network dependency** to operate — prayer times are computed on-device and the config server is LAN-only. The only persistence is `shared_preferences` holding the settings saved through the config server (and the server's auth token). The whole app is one Android target (`com.jamsholattv`); `ios` is not configured.

## Local config server (runs in all builds)

`LocalServerService` (`lib/services/local_server_service.dart`) embeds a `shelf` HTTP server bound to `0.0.0.0:8080`, started in `main.dart`. It lets you edit settings from any browser on the same Wi-Fi:

- **TV menu**: long-press the remote **OK** button (or press **Menu**) — `RemoteKeyDetector` (`lib/app/remote_key_handler.dart`) pushes `ConfigMenuScreen`, which shows a **QR code** of the authenticated URL.
- **Auth**: every `/api/*` call needs the per-device token (`?token=…` or `Authorization: Bearer …`), generated once and persisted, so the QR URL is stable across restarts.
- **Endpoints**: `GET /api/config` (current effective config as JSON) and `POST /api/config` (parse → persist to SharedPreferences → hot-apply via `ConfigProvider.applyConfig`, validating durations, lat/long ranges and fajr/isha angles). Image routes: `POST /api/upload/background` and `POST /api/upload/event` (raw image bytes, ≤ 10 MB, raster only; magic-byte sniffing when the browser sends `application/octet-stream`), `DELETE /api/event/<index>`, `DELETE /api/background` (restores the bundled image). Uploaded images are stored in the app-support `config_images` dir, referenced as baked `http://127.0.0.1:8080/images/<unique-name>` URLs, and served **publicly** (no token) at `GET /images/<name>` (path-traversal guarded) so the TV's `NetworkImage`/`CachedNetworkImage` loads need no plumbing. The web editor lives in `assets/web/index.html` and is served at `/`.
- **Static serving**: `shelf_static` from on-disk `assets/web` when present (dev/tests), otherwise a `rootBundle` fallback (Android release — bundled assets aren't real files).
- **Local IP**: `NetworkInfoHelper` (`lib/services/network_info_helper.dart`) resolves the LAN IPv4 via `network_info_plus` (needs `ACCESS_WIFI_STATE`).

Reach the editor by scanning the QR on the TV, or open `http://<tv-ip>:8080?token=<token>` directly.

## Debug tools you should know about

In `kDebugMode`, a FAB column is overlaid on every screen (`MainController._buildDebugFab`):
- **Orange** (`enableFakeSyuruqTime`) — jumps the clock to just before Syuruq.
- **Red** (`enableFakeTime`) — jumps the clock to ~1 minute before Maghrib.

`enableFakeJumatTime` also exists on `AppProvider` (jumps to the next Friday) but is **not wired to a button**. Fake time advances in real time and is the standard way to test prayer transitions without waiting.

## Conventions & gotchas

- Use `fvm flutter` for every Flutter command; never the raw `flutter` binary.
- `dart.lineLength = 80` is enforced by VS Code format-on-save and `analysis_options.yaml`.
- The `home` screen intentionally shows a full-screen "JAM TV BELUM DIATUR!" warning if the system year is < 2025 (masjid TVs with wrong clocks).
- `pubspec.yaml` version stays `1.0.0+1`; the real version is injected by CI from the git tag (`--build-name`), so **bump CHANGELOG.md and tag `vX.Y.Z` for a release** — do not edit pubspec version.
- Prayer times are computed locally for **Depok** coordinates (`AppConstants.latitude` / `AppConstants.longitude`); changing location means editing those two constants (Kemenag method and ihtiyat stay as-is).

## Further reading

- `docs/ARCHITECTURE.md` — file-by-file role map and layering
- `docs/STATE_MACHINE.md` — the full state machine with transitions and timings
- `docs/DATA_SOURCES.md` — schedule JSON shape, API endpoints, config schema
- `docs/DEVELOPMENT.md` — dev loop, debug tooling, release/CI process
