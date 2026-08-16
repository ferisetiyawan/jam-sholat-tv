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
│       ├── config_provider.dart      # runtime config state (remote over defaults), reloads every 1 min
│       └── app_provider.dart         # THE state machine (1-sec tick) + financial/event state
├── core/
│   ├── constants/app_constants.dart  # all fallback defaults + asset paths + city id
│   ├── constants/app_enum.dart       # AppStatus enum
│   ├── theme/app_theme.dart          # dark theme
│   ├── utils/date_formatter.dart     # Masehi + Hijriah date strings (applies hijri correction)
│   └── widgets/                      # shared UI building blocks
│       ├── background_image.dart     # configurable background (asset or network)
│       ├── prayer_card.dart          # one prayer cell in the home schedule row
│       ├── side_prayer_panel.dart    # clock + schedule sidebar (report / live modes)
│       └── bottom_marquee_bar.dart   # scrolling marquee text
├── data/
│   ├── models/prayer_schedule.dart   # PrayerSchedule API model (fromJson for one day's jadwal row)
│   ├── services/
│   │   ├── prayer_schedule_service.dart  # schedule asset/API fetch + SharedPreferences cache
│   │   ├── config_remote_service.dart    # remote config fetch, event-image download + cleanup
│   │   ├── financial_service.dart        # monthly kas summary fetch (raw API client)
│   │   └── audio_service.dart            # adzan/iqomah beep playback (static AudioPlayer)
│   └── repositories/
│       ├── prayer_repository.dart    # single source of truth: today's jadwal
│       ├── config_repository.dart    # single source of truth: merged AppConfig
│       └── financial_repository.dart # single source of truth: FinancialSummary
├── domain/
│   ├── models/
│   │   ├── app_config.dart           # typed runtime config with AppConstants fallbacks
│   │   ├── countdown_result.dart     # next prayer name + HH:mm:ss countdown
│   │   ├── event_image.dart          # announcement image (type + url)
│   │   └── financial_summary.dart    # monthly kas amounts (doubles, zero-fallback)
│   └── use_cases/
│       ├── calculate_countdown.dart  # next prayer + countdown from a jadwal map
│       └── get_iqomah_duration.dart  # iqomah length per prayer (Subuh / Ramadhan rules)
└── ui/
    ├── home/                         # home status + its mode screens
    │   ├── home_screen.dart          # big clock + schedule row (used inside HomeWrapper)
    │   ├── home_wrapper.dart         # BackgroundImage + HomeScreen
    │   ├── event_screen.dart         # rotating announcement images
    │   ├── financial_report_screen.dart  # monthly kas report
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
- **`data/`** — services talk to the outside world (HTTP, SharedPreferences, assets, platform plugins); repositories are the single entry point the rest of the app uses and the only place that knows about services.

## Startup flow

`main()` (`lib/main.dart`):

1. Forces landscape, immersive fullscreen, enables wakelock, initializes `intl` for `id_ID`.
2. `runApp(const MasjidApp())`.

`MasjidApp` (`lib/app/masjid_app.dart`) builds `MultiProvider`:
- `ConfigProvider()..init()` — immediately loads config (from remote, falling back to cache/defaults), then reloads every minute.
- `ChangeNotifierProxyProvider<ConfigProvider, AppProvider>` — `AppProvider()..init()`, updated with `app.updateConfig(config)` whenever config changes.
- `MaterialApp(darkTheme)` → `MainController`.

`MainController` (`lib/app/main_controller.dart`) watches both providers and maps `app.status` (+ mode flags) to exactly one screen through a `switch`. On the `home` status it further branches:
- `isSpecialLiveMode` → `LiveMakkahScreen` (30 min before Maghrib or, on Friday, Jumat — and internet is up)
- `financialSummary != null` → `FinancialReportScreen`
- `isEventMode && eventImages.isNotEmpty` → `EventScreen`
- otherwise → `HomeWrapper`

An `AnimatedSwitcher` cross-fades between screen changes. A tiny red `wifi_off` badge overlays when offline. In debug mode a FAB column (fake-time simulators) floats on top.

## The one-second heartbeat

`AppProvider` owns a `Timer.periodic(Duration(seconds: 1))`. Each tick (`_onTick`) runs in order:

1. `_updateDateTimeStrings(now)` — `timeString`, Masehi/Hijriah dates, next-prayer name + `countdownString` (via the `CalculateCountdown` use case).
2. `_handleCycleLogic(now)` — only when `status == home`: rotates between home / event / report segments, and detects an exact HH:mm match against the `jadwal` map to trigger **Adzan** (or the Syuruq → Iqomah path).
3. `_handlePrayerStatusLogic()` — decrements the active state's counter and fires its transition (adzan→iqomah, iqomah→shalat/isyraq, etc.).
4. `_checkSpecialLiveConditions(now)` — sets `isSpecialLiveMode`.
5. `_handleMidnightSync(now)` — at 00:00:00, forces a fresh schedule/config sync.

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

`ConfigProvider` exposes an `AppConfig` model built by `ConfigRepository` → `ConfigRemoteService.fetchRemoteConfig()`:

1. GET the Google Apps Script endpoint (`?action=config`).
2. If `eventImages` present, download new remote image URLs to the app documents dir as `event_<url.hashCode>.<ext>` and delete `event_*` files no longer referenced.
3. `AppConfig.fromJson` merges remote values over `AppConstants` defaults (`AppConfig.toJson` persists the merged result).
4. Cache to SharedPreferences `local_config_cache`; on any failure return the cached config (or bare defaults).

`hijriCorrection` is clamped to `[-2, 2]` when parsing and applied in `DateFormatter.getFullDate` by shifting `DateTime.now()` by that many days before converting to Hijriah (`hijriyah_indonesia` package). Default is `-1`.
