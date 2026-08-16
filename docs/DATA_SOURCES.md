# Data Sources

The app is **offline-first**: everything runs from bundled assets + SharedPreferences, with network calls only as fallback/refresh. There is no local database — SharedPreferences holds the schedule blob and the config cache.

## 1. Prayer schedules

**Asset bundle** — `assets/schedules/YYYYMM.json`, one file per month (currently 202603–202608). Format is exactly the myquran.com API response body:

```json
{
  "status": true,
  "request": { "path": "/sholat/jadwal/1225/2026/08" },
  "data": {
    "id": 1225,
    "lokasi": "KOTA DEPOK",
    "daerah": "JAWA BARAT",
    "jadwal": [
      {
        "tanggal": "Sabtu, 01/08/2026",
        "imsak": "04:36", "subuh": "04:46", "terbit": "06:01",
        "dhuha": "06:29", "dzuhur": "12:03", "ashar": "15:24",
        "maghrib": "17:58", "isya": "19:09", "date": "2026-08-01"
      }
    ]
  }
}
```

`PrayerScheduleService.fetchAndSaveSixMonths` reads every file in `AppConstants.prayerScheduleFiles`, extracts the `"YYYY-MM"` key from `request.path` (segments 5 and 6), and stores `data.jadwal` (the whole list) into SharedPreferences `offline_prayer_data` — a JSON object `{ "2026-08": [ ...jadwal rows... ], ... }`.

**Network fallback** — if the current month isn't in the assets, it fetches six months from:

```
GET https://api.myquran.com/v2/sholat/jadwal/1225/{year}/{month}
```

`1225` is the hardcoded **KOTA DEPOK** city id (`AppConstants.cityId`). The response `data.jadwal` is stored under the same key. If you change city, you must regenerate the asset bundle and update `cityId`.

**Reading today** — `getTodayJadwalMap` looks up `"YYYY-MM"` → finds the row whose `tanggal` contains `dd/MM/yyyy` → maps it through `PrayerSchedule.fromJson` into the canonical app map:

```
{ "Subuh": "...", "Syuruq": "...", "Dzuhur": "...", "Ashar": "...", "Maghrib": "...", "Isya": "..." }
```

Note `fromJson` maps the API's `terbit` field into the app's **`Syuruq`** key.

**Refresh cadence** — first launch and again at every midnight (`_handleMidnightSync`), which clears `_isDataUpdatedFromServer` so the server path re-runs.

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
| `offline_prayer_data` | JSON object of `"YYYY-MM"` → jadwal list |
| `local_config_cache` | JSON of the merged remote config |
