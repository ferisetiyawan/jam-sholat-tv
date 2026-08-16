# Development

## Toolchain

This project pins **Flutter 3.41.1** via **FVM** (`.fvmrc`). Always use the `fvm` prefix — never the raw `flutter` binary.

```bash
dart pub global activate fvm   # once, if FVM is not installed
fvm install                    # download the pinned Flutter SDK
fvm use                        # link the project
fvm flutter pub get            # install dependencies
```

VS Code is configured (`.vscode/settings.json`) to use `.fvm/versions/3.41.1` as the SDK, with format-on-save and `dart.lineLength = 80`.

## Dev loop

```bash
fvm flutter run                 # debug run on device/emulator
fvm flutter analyze             # lint (flutter_lints ^6.0.0)
fvm flutter test                # run tests (use cases + models)
```

Lint rules come from `analysis_options.yaml` (package:flutter_lints). Keep lines ≤ 80 chars and let format-on-save fix style.

## Testing prayer transitions without waiting

In `kDebugMode` every duration is compressed (see `docs/STATE_MACHINE.md` → Durations) and a FAB column is overlaid:

- **Orange sun FAB** — `enableFakeSyuruqTime()`: jumps the clock to just before Syuruq → walks the Syuruq/Iqomah/Isyraq path.
- **Red fast-forward FAB** — `enableFakeTime()`: jumps the clock to ~1 minute before Maghrib → walks adzan → iqomah → shalat.
- `enableFakeJumatTime()` exists on `AppProvider` (jumps to the next Friday at Dzuhur −5s) but is **not wired to a button**; call it from the debugger or wire a FAB while testing.

Fake time advances in real seconds (`currentDateTime = _fakeTime ?? DateTime.now()`). Note fake-time mode also shrinks adzan/isyraq counters to 5s.

## Configuring the TV from a browser (local server)

The app runs an embedded HTTP server on `0.0.0.0:8080` in all builds (`lib/services/local_server_service.dart`):

1. On the device, long-press the remote **OK** (or press **Menu**) → a QR + URL (`http://<tv-ip>:8080?token=<token>`) is shown.
2. On another device on the same Wi-Fi, scan the QR or open the URL — it loads `assets/web/index.html`, the config editor.
3. Change values and hit **Simpan Pengaturan** → the TV applies them immediately (hot-apply) and the change survives relaunch (persisted).

API: `GET/POST /api/config` (token required), image routes `POST /api/upload/background`, `POST /api/upload/event`, `DELETE /api/event/<index>`, `DELETE /api/background`, and public `GET /images/<name>`. To smoke-test from a laptop:

```bash
curl "http://<tv-ip>:8080/api/config?token=<token>"
curl -X POST "http://<tv-ip>:8080/api/config?token=<token>" \
  -H 'Content-Type: application/json' \
  -d '{"marqueeText":"Selamat Datang di Masjid Al Hijrah"}'
curl -X POST "http://<tv-ip>:8080/api/upload/background?token=<token>" \
  --data-binary @background.jpg
# GET /api/config returns backgroundImage like ".../images/bg_123.jpg" —
# fetch it back with no token:
curl "http://<tv-ip>:8080/images/bg_123.jpg"
```

If the server fails to bind (port 8080 taken), it logs and the app continues — settings then stay at their defaults.

## Project layout & conventions

- Screens are stateless and receive all data through constructors — keep it that way; no logic inside `ui/`. State lives in `app/providers/`, data access behind `data/repositories/`, and pure rules in `domain/use_cases/`.
- All durations/text/images flow through `ConfigProvider`, which starts from the `AppConstants` defaults (no remote config) and merges persisted overrides saved through the local config server. Add new tunables in `AppConstants`, not as ad-hoc local constants — and if it should be editable from the web UI, add the field to `AppConfig` + `assets/web/index.html` too.
- The Jumat rename ("Dzuhur" → "Jumat" on Friday) exists in **five** sites — see `docs/ARCHITECTURE.md` → "Where the Jumat translation lives". Touch all five or you reintroduce the recurring bug.
- Prayer times are computed locally for **Depok** coordinates (`AppConstants.latitude` / `AppConstants.longitude`). The location (plus `fajrAngle`/`ishaAngle`/`madhab`/`ihtiyat`) is **editable at runtime** through the web editor's "Lokasi & Perhitungan Waktu" card (city preset dropdown fills lat/long), and the schedule recomputes within ~1s via `AppProvider._refreshJadwalIfNeeded`.

## Release process

Releases are tag-driven — **`pubspec.yaml` version stays `1.0.0+1`**; do not bump it manually.

1. Add the release notes to `CHANGELOG.md` (top, `## [x.y.z] - date`).
2. Commit and push.
3. Create and push a tag `vX.Y.Z` (e.g. `v1.3.1`).

`.github/workflows/android-build.yml` then:

- Builds a release APK with `--build-name` from the tag and `--build-number` from the GitHub run number.
- Reads the top `CHANGELOG.md` section as the release body.
- Publishes a GitHub Release with the APK attached (`softprops/action-gh-release`).

Output APK: `build/app/outputs/flutter-apk/app-release.apk`.

For a manual local build:

```bash
fvm flutter build apk --release
fvm flutter build appbundle     # Play Store
```

## Notes

- The app targets Android only (`com.jamsholattv`); iOS is not configured.
- The Home screen shows a "JAM TV BELUM DIATUR!" overlay when the device clock reports a year < 2025 — this is an intentional guard for misconfigured masjid TVs, not a bug.
