# State Machine & Prayer Cycle

The whole app is a single finite state machine. The current state is `AppProvider.status` (type `AppStatus`), and it is advanced once per second by `AppProvider._onTick()`.

```
enum AppStatus { home, adzan, iqomah, jumatMode, shalat, isyraq }
```

`MainController` (`lib/app/main_controller.dart`) maps each status to a screen. Each non-home state carries a countdown counter (`adzanCounter`, `iqomahCounter`, `jumatCounter`, `shalatCounter`, `isyraqCounter`) that `_handlePrayerStatusLogic()` decrements every tick.

## Normal day (non-Friday)

```
                         HH:mm match (exact second)       counter → 0
   HOME ───────────────────────────▶ ADZAN ────────────▶ IQOMAH ────────────▶ SHALAT ────────────▶ HOME
     │  (idle: 10s)                 (beep, 180s)          (10–15 min,          (600s, beep,         |
     │                              shows prayer name)     beep ≤10s)           hadith card)         │
     └──────────── cycle through event/report screens every ~30s ───────────────────────────────────┘
```

- **Trigger**: `_handleCycleLogic` fires when `entry.value == timeString && now.second == 0` for a prayer in the `jadwal` map. `_startAdzan(name)` plays the adzan beep and sets `adzanCounter`.
- **Adzan → Iqomah** (`_handleAdzanTransition`): unless the prayer is Jumat, `iqomahCounter = GetIqomahDuration()(name)` (or the 5s debug value).
- **Iqomah → Shalat** (`_finishPrayerCycle`): plays the adzan beep, sets `shalatCounter`.
- **Shalat / JumatMode / Isyraq → Home**: when their counter hits 0.

## Syuruq → Isyraq special path

```
   Syuruq HH:mm match ─▶ IQOMAH(label "Syuruq") ─▶ ISYRAQ ─▶ HOME
                          "MENANTI ISYRAQ"          (600s)
                          counter = waitingIsyraqDuration (900s / 15 min)
```

On the Syuruq trigger, `_handleCycleLogic` sets `status = iqomah` with `currentPrayerName = "Syuruq"` and `iqomahCounter = config.waitingIsyraqDuration` (no adzan). When the iqomah counter expires and `currentPrayerName == "Syuruq"`, `_startIsyraq()` runs instead of the normal prayer finish.

## Friday path

```
   "Dzuhur" HH:mm match (renamed "Jumat") ─▶ ADZAN("Jumat") ─▶ JUMAT_MODE ─▶ HOME
                                                               (2700s / 45 min,
                                                                "WAKTUNYA SHOLAT JUMAT" screen)
```

On Friday, `_handleCycleLogic` renames the Dzuhur entry to **Jumat** before triggering, and `_handleAdzanTransition` sends Jumat to `jumatMode` instead of `iqomah` (no iqomah stage on Friday). The Jumat screen shows khutbah-etiquette text.

## Durations

All durations are fixed local constants in `AppConstants` (served via `ConfigProvider` — no remote config) and mostly shortened in `kDebugMode` (`AppConstants.isDebug`):

| Duration | Default (release) | Debug |
| --- | --- | --- |
| `homeDuration` | 10s | 2s |
| `eventDuration` | 20s | 3s |
| `reportDuration` | 20s | 3s |
| `adzanDuration` | 180s | (5s when fake time active) |
| `iqomah*` | Subuh 900s / Maghrib-Ramadhan 900s / else 600s | 5s (`iqomahTestingDuration`) |
| `shalatDuration` | 600s | 10s |
| `isyraqDuration` | 600s | 10s |
| `jumatDuration` | 2700s | 10s |
| `waitingIsyraqDuration` | 900s | 15s |

The `GetIqomahDuration` use case (`lib/domain/use_cases/get_iqomah_duration.dart`) decides the release iqomah length using the Hijriah month via `hijriyah_indonesia` (`hijri.hMonth == 9` → Ramadhan). In debug it always returns the 5s testing value.

## Startup resume — `checkInitialStatus`

On launch (after the local schedule loads), `AppProvider.checkInitialStatus` walks today's schedule and, if the current wall-clock time is already *inside* a cycle, sets the matching state with the remaining counter — so a TV reboot mid-adzan resumes on the Adzan screen instead of jumping Home. Order of checks per prayer: inside the adzan window → `adzan`; after adzan until `endCycle` → `iqomah` (or `jumatMode` for Jumat); Syuruq has its own two windows (waiting → `iqomah("Syuruq")`, then `isyraq`).

## Home-screen idle cycle

While `status == home`, `_handleCycleLogic` slices a rolling cycle of `homeDuration + eventDuration + reportDuration`. The report is fed by the offline sample (`financialSummary` is non-null). The event segment is only active when at least one event image has been uploaded via the config server; with an empty `eventImages` it contributes 0, so the cycle is effectively `home → report → repeat`:

- `tick % totalCycle < homeDuration` → Home (big clock + schedule row)
- `< homeDuration + eventDuration` → `isEventMode = true` (advances `currentEventIndex` through `config.eventImages`) → `EventScreen`
- else → `isReportMode = true` → `FinancialReportScreen` (shows `financialSummary.offlineSample()`)

`isSpecialLiveMode` is checked *separately* and, when true, the live Makkah screen wins over home.

## Edge cases to preserve

- **Exact-second trigger**: transitions fire only when `now.second == 0`, so a second-hand tick past the prayer time is not re-triggered until the next matching second.
- **`_onTick` early-return**: the tick no-ops until `_config` is set; config is now static defaults delivered synchronously via the provider proxy, so it is available from the first tick.
- **Midnight sync**: at 00:00:00 the jadwal is recomputed locally for the new day, so the date rolls over to the next day's schedule.
