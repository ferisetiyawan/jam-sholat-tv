# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

**Jam Sholat TV** — a Flutter Android app for a masjid TV/display screen (Masjid Al Hijrah CGE, Depok). It shows the current time, today's prayer schedule, and a live countdown to the next prayer, then cycles through full-screen states as each prayer time arrives: **Adzan** → **Iqomah** → **Shalat**, with a dedicated **Jumat** state on Friday and an **Isyraq** countdown after Syuruq. It also rotates through announcement images (event mode) and a monthly financial report (report mode) while on the home screen, and plays a live Makkah YouTube stream during the 30 minutes before Maghrib / Jumat.

All UI text is Indonesian. The app runs on Android TV/tablet in landscape, fullscreen, with the screen kept awake.

## Commands

Everything is FVM-based — always prefix Flutter commands with `fvm` (Flutter 3.41.1, pinned in `.fvmrc`).

```bash
fvm flutter pub get          # install dependencies
fvm flutter run              # run on connected device/emulator
fvm flutter analyze          # static analysis (flutter_lints ^6.0.0)
fvm flutter test             # run tests (test/ is currently empty)
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
- `lib/app/providers/config_provider.dart` — merged runtime config (remote over defaults)
- `lib/data/repositories/` + `lib/data/services/` — data fetching, caching + audio
- `lib/domain/` — typed models and pure use cases (countdown, iqomah durations)

Provider wiring: `ConfigProvider` (wraps `ConfigService`) and `AppProvider` (wraps `PrayerService`, `FinancialService`, `AudioService`) are created in `main.dart` via a `MultiProvider` with `ChangeNotifierProxyProvider`. `AppProvider` reads `config` for all durations. **The config getters must be non-null by the time `AppProvider._onTick` runs** — `_onTick` early-returns if `_config == null`.

### The prayer cycle (the heart of the app)

Read `docs/STATE_MACHINE.md` for the full diagram. Summary:

- **Home** → at a prayer time (exact HH:mm match on the second) → **Adzan** (beep plays) → countdown ends → **Iqomah** (beep at ≤10s) → countdown ends → **Shalat** (beep, shows the hadith card) → countdown ends → **Home**.
- **Syuruq is special**: at Syuruq time it goes to Iqomah state with label "Syuruq" ("MENANTI ISYRAQ"), then to **Isyraq**, then Home.
- **Friday**: the Dzuhur entry is *displayed as* "Jumat" and Adzan("Jumat") → **jumatMode** (the "WAKTUNYA SHOLAT JUMAT" screen) → Home. Jumat has no iqomah stage.
- On app start, `checkInitialStatus` re-derives the current state from today's schedule so a mid-cycle restart (e.g. TV reboot during adzan) resumes in the right state.

### Friday / Jumat — fragile area, handled in several places

The `jadwal` map always keys the Friday prayer as `"Dzuhur"`, but multiple widgets/paths translate it to `"Jumat"` for display, and `"Jumat"` is translated back to `"Dzuhur"` for schedule lookups. This shows up independently in: `AppProvider._handleCycleLogic`, `AppProvider.checkInitialStatus`, `CalculateCountdown` (`lib/domain/use_cases/calculate_countdown.dart`), `PrayerCard`, and `SidePrayerPanel`. Recent changelog entries show recurring bugs here — if you touch anything Jumat-related, check all five sites.

### Durations are all runtime config

Every duration (`homeDuration`, `adzanDuration`, `iqomah*Duration`, `shalatDuration`, `isyraqDuration`, `jumatDuration`, `minutesBeforeMaghrib`, …) comes from `ConfigProvider`, which merges a **remote Google Apps Script config** over the `AppConstants` defaults (`lib/core/constants/app_constants.dart`). Config re-fetches every minute. In `kDebugMode` most durations are shortened to a few seconds to speed up testing.

Iqomah duration logic (`GetIqomahDuration` use case in `lib/domain/use_cases/get_iqomah_duration.dart`): Subuh = 15 min, Maghrib during Ramadhan (hijri month 9) = 15 min, otherwise 10 min; in debug = 5s. Hijri correction (`hijriCorrection`, default `-1`, clamped to [-2, 2]) is applied by adding days in `DateFormatter.getFullDate`.

### Data sources (all "offline-first")

1. **Prayer schedules** — bundled as JSON assets in `assets/schedules/YYYYMM.json` (myquran.com API format, see `docs/DATA_SOURCES.md` for the shape). On first launch / after midnight, `PrayerScheduleService.fetchAndSaveSixMonths` loads assets into SharedPreferences under the key `offline_prayer_data` (a map `"YYYY-MM"` → jadwal list). If the current month isn't found in assets, it fetches the next 6 months from `https://api.myquran.com/v2/sholat/jadwal/1225/{year}/{month}` (city **1225 = KOTA DEPOK**, hardcoded in `AppConstants.cityId`).
2. **Remote config + event images** — a Google Apps Script endpoint (`?action=config`) returns durations, marquee text, background image URL, and an `eventImages` list. Remote image URLs are downloaded to the app documents dir as `event_<hash>.<ext>` and stale files are cleaned up. Cached in SharedPreferences `local_config_cache`.
3. **Financial report** — a separate Google Apps Script endpoint (`?action=summary`) returns monthly kas data (`saldoAwal`, `kasmasuk`, `kasKeluar`, `saldoAkhir`, `saldoPrasarana`, `saldoNonPrasarana`), rendered on the FinancialReport screen in report mode (internet + data required).

Only SharedPreferences is used for persistence — no local database. The whole app is one Android target (`com.jamsholattv`); `ios` is not configured.

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
- Do not hardcode city/schedule assumptions: the schedule bundle and API city are tied to Depok (1225); changing city means regenerating `assets/schedules/`.

## Further reading

- `docs/ARCHITECTURE.md` — file-by-file role map and layering
- `docs/STATE_MACHINE.md` — the full state machine with transitions and timings
- `docs/DATA_SOURCES.md` — schedule JSON shape, API endpoints, config schema
- `docs/DEVELOPMENT.md` — dev loop, debug tooling, release/CI process
