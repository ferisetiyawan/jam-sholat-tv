# Architecture

Jam Sholat TV is a **thin-UI / state-driven** Flutter app with a clean layered structure. Screens are stateless presentational widgets fed by constructor parameters; the state machine lives in `AppProvider`; data access lives behind repositories and services; pure business rules live in domain use cases.

The codebase follows the layered convention from the Flutter architecture skill:

```
lib/
├── main.dart                         # entrypoint only: orientation, fullscreen, intl, wakelock, runApp
├── app/
│   ├── masjid_app.dart               # root widget: MultiProvider wiring + MaterialApp
│   ├── main_controller.dart          # watches providers, maps AppStatus → screen (+ debug FAB)
│   └── providers/
│       ├── config_provider.dart      # fixed runtime config (AppConstants defaults, no fetch)
│       └── app_provider.dart         # THE state machine (1-sec tick) + offline financial sample + event state
├── core/
│   ├── constants/app_constants.dart  # all duration/text/asset defaults + prayer-calc constants
│   ├── constants/app_enum.dart       # AppStatus enum
│   ├── theme/app_theme.dart          # dark theme
│   ├── utils/date_formatter.dart     # Masehi + Hijriah date strings (applies hijri correction)
│   └── widgets/                      # shared UI building blocks
│       ├── background_image.dart     # fixed background (bundled asset)
│       ├── prayer_card.dart          # one prayer cell in the home schedule row
│       ├── side_prayer_panel.dart    # clock + schedule sidebar (report / live modes)
│       └── bottom_marquee_bar.dart   # scrolling marquee text
├── data/
│   ├── services/
│   │   ├── financial_service.dart        # monthly kas summary fetch (retained, never called)
│   │   └── audio_service.dart            # adzan/iqomah beep playback (static AudioPlayer)
│   └── repositories/
│       ├── prayer_repository.dart    # single source of truth: today's (locally computed) jadwal
│       └── financial_repository.dart # single source of truth: FinancialSummary (retained, never called — offline sample)
├── domain/
│   ├── models/
│   │   ├── app_config.dart           # typed runtime config with AppConstants fallbacks
│   │   ├── countdown_result.dart     # next prayer name + HH:mm:ss countdown
│   │   ├── event_image.dart          # announcement image (type + url)
│   │   └── financial_summary.dart    # total kas + weekly income (doubles, zero-fallback)
│   └── use_cases/
│       ├── calculate_countdown.dart      # next prayer + countdown from a jadwal map
│       ├── calculate_prayer_times.dart   # on-device Kemenag prayer-time calc (adhan_dart)
│       └── get_iqomah_duration.dart      # iqomah length per prayer (Subuh / Ramadhan rules)
└── ui/
    ├── home/                         # home status + its mode screens
    │   ├── home_screen.dart          # big clock + schedule row (used inside HomeWrapper)
    │   ├── home_wrapper.dart         # BackgroundImage + HomeScreen
    │   ├── event_screen.dart         # rotating announcement images (dormant)
    │   ├── financial_report_screen.dart  # monthly kas report (offline sample, rotates in on home)
    │   └── live_makkah_screen.dart   # YouTube live stream (LIVE_MECCA video id)
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
- `isEventMode && eventImages.isNotEmpty` → `EventScreen` (dormant: `eventImages` is always empty)
- otherwise → `HomeWrapper`

An `AnimatedSwitcher` cross-fades between screen changes. A tiny red `wifi_off` badge overlays when offline. In debug mode a FAB column (fake-time simulators) floats on top.

## The one-second heartbeat

`AppProvider` owns a `Timer.periodic(Duration(seconds: 1))`. Each tick (`_onTick`) runs in order:

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

`ConfigProvider` exposes a fixed `AppConfig` built from `AppConfig.defaults()` (every field resolved from `AppConstants`). There is no remote config fetch, no event-image sync, and no persistence:

- Durations, `hijriCorrection`, marquee text, and the background asset all come from `AppConstants` (`lib/core/constants/app_constants.dart`); `eventImages` is always empty, so event mode never activates (announcement feature disabled).
- The provider stays a `ChangeNotifier` only to keep the existing `MultiProvider`/proxy wiring intact; it never notifies.

`hijriCorrection` is clamped to `[-2, 2]` when parsing (still via `AppConfig.fromJson`, used by `defaults()`) and applied in `DateFormatter.getFullDate` by shifting `DateTime.now()` by that many days before converting to Hijriah (`hijriyah_indonesia` package). Default is `-1`.
