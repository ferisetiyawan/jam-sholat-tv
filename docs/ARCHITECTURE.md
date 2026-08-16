# Architecture

Jam Sholat TV is a **thin-UI / state-driven** Flutter app with a clean layered structure. Screens are stateless presentational widgets fed by constructor parameters; the state machine lives in `AppProvider`; data access lives behind repositories and services; pure business rules live in domain use cases.

The codebase follows the layered convention from the Flutter architecture skill:

```
lib/
├── main.dart                         # entrypoint: orientation, fullscreen, intl, wakelock, config load, server start
├── app/
│   ├── masjid_app.dart               # root widget: MultiProvider wiring + MaterialApp + navigator key
│   ├── main_controller.dart          # watches providers, maps AppStatus → screen (+ debug FAB)
│   ├── remote_key_handler.dart       # TV remote: long-press OK / Menu toggles the config menu
│   └── providers/
│       ├── config_provider.dart      # AppConfig defaults + persisted overrides (load/applyConfig)
│       └── app_provider.dart         # THE state machine (1-sec tick) + offline financial sample + event state
├── core/
│   ├── constants/app_constants.dart  # all duration/text/asset defaults + prayer-calc constants
│   ├── constants/app_enum.dart       # AppStatus enum
│   ├── theme/app_theme.dart          # dark theme
│   ├── utils/date_formatter.dart     # Masehi + Hijriah date strings (applies hijri correction)
│   └── widgets/                      # shared UI building blocks
│       ├── background_image.dart     # fixed background (bundled asset or uploaded http URL)
│       ├── prayer_card.dart          # one prayer cell in the home schedule row
│       ├── side_prayer_panel.dart    # clock + schedule sidebar (report / live modes)
│       └── bottom_marquee_bar.dart   # scrolling marquee text
├── data/
│   ├── services/
│   │   ├── financial_service.dart        # monthly kas summary fetch (retained, never called)
│   │   └── audio_service.dart            # adzan/iqomah beep playback (static AudioPlayer)
│   └── repositories/
│       ├── prayer_repository.dart    # single source of truth: today's (locally computed) jadwal; passes an optional AppConfig for runtime-editable calc params
│       └── financial_repository.dart # single source of truth: FinancialSummary (retained, never called — offline sample)
├── services/                         # standalone infrastructure (not data-layer)
│   ├── local_server_service.dart     # embedded shelf server: token auth, /api/config, image uploads + public /images/ serving, static UI
│   └── network_info_helper.dart      # resolves the LAN IPv4 for the config URL/QR
├── domain/
│   ├── models/
│   │   ├── app_config.dart           # typed runtime config with AppConstants fallbacks (incl. location/madhab/ihtiyat calc fields)
│   │   ├── countdown_result.dart     # next prayer name + HH:mm:ss countdown
│   │   ├── event_image.dart          # announcement image (type + url)
│   │   └── financial_summary.dart    # total kas + weekly income (doubles, zero-fallback)
│   └── use_cases/
│       ├── calculate_countdown.dart      # next prayer + countdown from a jadwal map
│       ├── calculate_prayer_times.dart   # on-device Kemenag prayer-time calc (adhan_dart), reads AppConfig for location/madhab/ihtiyat
│       └── get_iqomah_duration.dart      # iqomah length per prayer (Subuh / Ramadhan rules)
└── ui/
    ├── home/                         # home status + its mode screens
    │   ├── home_screen.dart          # big clock + schedule row (used inside HomeWrapper)
    │   ├── home_wrapper.dart         # BackgroundImage + HomeScreen
    │   ├── event_screen.dart         # rotating announcement images (active when eventImages is non-empty)
    │   ├── financial_report_screen.dart  # monthly kas report (offline sample, rotates in on home)
    │   └── live_makkah_screen.dart   # YouTube live stream (LIVE_MECCA video id)
    ├── settings/
    │   └── config_menu_screen.dart   # QR + URL of the config server (opened via remote)
    └── prayer/                       # prayer-cycle screens
        ├── adzan_screen.dart         # "WAKTU ADZAN BERKUMANDANG"
        ├── iqomah_screen.dart        # countdown MM:SS, also handles Syuruq → "MENANTI ISYRAQ"
        ├── shalat_screen.dart        # hadith card during prayer
        ├── isyraq_screen.dart        # "WAKTU ISYRAQ TELAH TIBA"
        └── jumat_screen.dart         # Friday khutbah etiquette screen
```

## Layering rules

- **`ui/`** — presentational only. Widgets never fetch data or own business logic; they read from providers or receive constructor parameters.
- **`app/providers/`** — app-wide state (the ViewModels). `AppProvider` is the state machine; `ConfigProvider` exposes the merged config.
- **`domain/`** — pure business logic and models, no Flutter/dependency imports.
- **`data/`** — services talk to the outside world (HTTP, platform plugins, assets); repositories are the single entry point the rest of the app uses and the only place that knows about services.

## Startup flow

`main()` (`lib/main.dart`):

1. Forces landscape, immersive fullscreen, enables wakelock, initializes `intl` for `id_ID`.
2. `runApp(const MasjidApp())`.

`MasjidApp` (`lib/app/masjid_app.dart`) builds `MultiProvider`:
- `ConfigProvider()` — exposes the fixed offline config (AppConstants defaults; no fetch).
- `ChangeNotifierProxyProvider<ConfigProvider, AppProvider>` — `AppProvider()..init()`, updated once with `app.updateConfig(config)` at startup (config never changes afterwards).
- `MaterialApp(darkTheme)` → `MainController`.

`MainController` (`lib/app/main_controller.dart`) watches both providers and maps `app.status` (+ mode flags) to exactly one screen through a `switch`. On the `home` status it further branches:
- `isSpecialLiveMode` → `LiveMakkahScreen` (30 min before Maghrib or, on Friday, Jumat — and internet is up)
- `isReportMode && financialSummary != null` → `FinancialReportScreen` (fed by the offline sample; shows during the `reportDuration` slice of the home idle cycle)
- `isEventMode && eventImages.isNotEmpty` → `EventScreen` (active once at least one image is uploaded via the config server)
- otherwise → `HomeWrapper`

An `AnimatedSwitcher` cross-fades between screen changes. A tiny red `wifi_off` badge overlays when offline. In debug mode a FAB column (fake-time simulators) floats on top.

## The one-second heartbeat

`AppProvider` owns a `Timer.periodic(Duration(seconds: 1))`. Each tick (`_onTick`) runs in order:

0. `_refreshJadwalIfNeeded()` — compares a fingerprint of the calc params (`latitude`/`longitude`/`fajrAngle`/`ishaAngle`/`madhab`/sorted `ihtiyat`, `_lastCalcKey`) and recomputes the jadwal only when it changed (e.g. via the config server). Runs in timer context so it is safe outside the build phase, and self-heals the startup gap (persisted overrides are picked up on the first tick).
1. `_updateDateTimeStrings(now)` — `timeString`, Masehi/Hijriah dates, next-prayer name + `countdownString` (via the `CalculateCountdown` use case).
2. `_handleCycleLogic(now)` — only when `status == home`: rotates between home / event / report segments, and detects an exact HH:mm match against the `jadwal` map to trigger **Adzan** (or the Syuruq → Iqomah path).
3. `_handlePrayerStatusLogic()` — decrements the active state's counter and fires its transition (adzan→iqomah, iqomah→shalat/isyraq, etc.).
4. `_checkSpecialLiveConditions(now)` — sets `isSpecialLiveMode`.
5. `_handleMidnightSync(now)` — at 00:00:00, recomputes the local jadwal for the new day.

`currentDateTime` returns `_fakeTime ?? DateTime.now()` so the whole machine can be simulated.

## Where the Jumat translation lives

The schedule data only knows `Dzuhur`. The "Friday → Jumat" rename is implemented independently at five sites — keep them in sync when editing:

| Site | What it does |
| --- | --- |
| `AppProvider._handleCycleLogic` | Display name for triggering Adzan |
| `AppProvider.checkInitialStatus` | Display name when resuming mid-cycle |
| `domain/use_cases/calculate_countdown.dart` | Next-prayer name for the countdown |
| `core/widgets/prayer_card.dart` | Home schedule row label |
| `core/widgets/side_prayer_panel.dart` | Live/report sidebar label |

Additionally `_isMinutesBeforePrayer("Jumat", ...)` maps the lookup key back to `Dzuhur`. Recurring bug fixes in `CHANGELOG.md` (1.2.1, 1.3.1) all live around this logic.

## Config layering

`ConfigProvider` starts from `AppConfig.defaults()` (every field resolved from `AppConstants`). There is no remote config fetch. The only persistence is the embedded local config server (`lib/services/local_server_service.dart`):

- `ConfigProvider.load()` (called in `main.dart` before `runApp`) reads the persisted JSON from `SharedPreferences` (`configPrefsKey`) and merges it over the defaults via `AppConfig.fromJson`.
- `POST /api/config` persists the new values **and** hot-applies them with `ConfigProvider.applyConfig(config)` (reassigns `_config` + `notifyListeners`). `AppProvider` reads through the same `ConfigProvider` instance, so the next 1-second tick picks up the change — no state-machine edits needed. For the prayer-calc params the tick's `_refreshJadwalIfNeeded()` (see above) also recomputes the schedule.
- Durations, `hijriCorrection`, marquee text, the background asset, the `enableFinancialReport` toggle, and the prayer-calc params (`latitude`/`longitude`/`fajrAngle`/`ishaAngle`/`madhab`/`ihtiyat`) all default from `AppConstants` (`lib/core/constants/app_constants.dart`).
- **Image uploads** (`POST /api/upload/background` / `POST /api/upload/event`, `DELETE /api/event/<index>` / `DELETE /api/background`) write raster files to the app-support `config_images` dir, store baked `http://127.0.0.1:8080/images/<unique-name>` URLs in config, then persist + hot-apply. The TV loads them via the existing `NetworkImage`/`CachedNetworkImage` branches in `BackgroundImage` / `EventScreen` — **no widget changes**. Uploads are token-protected; the `GET /images/<name>` read route is public (path-traversal guarded). `eventImages` is empty until images are uploaded, so event mode is dormant by default.

`hijriCorrection` is clamped to `[-2, 2]` when parsing (still via `AppConfig.fromJson`, used by `defaults()`) and applied in `DateFormatter.getFullDate` by shifting `DateTime.now()` by that many days before converting to Hijriah (`hijriyah_indonesia` package). Default is `-1`.
