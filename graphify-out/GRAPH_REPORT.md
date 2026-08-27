# Graph Report - jam-sholat-tv  (2026-08-27)

## Corpus Check
- 83 files · ~73,388 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 775 nodes · 936 edges · 51 communities (46 shown, 5 thin omitted)
- Extraction: 96% EXTRACTED · 4% INFERRED · 0% AMBIGUOUS · INFERRED: 42 edges (avg confidence: 0.88)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- local_server_service.dart
- app_provider.dart
- app_constants.dart
- config_provider.dart
- main_controller.dart
- event_screen.dart
- app_config.dart
- local_server_service_test.dart
- follower_sync_service.dart
- financial_report_card.dart
- Finite State Machine AppStatus
- live_makkah_screen.dart
- ../../core/widgets/background_
- financial_report_screen.dart
- Local Config Server API Endpoi
- ../../core/constants/app_const
- side_prayer_panel.dart
- icon.png — 512x512 8-bit RGBA 
- home_screen.dart
- home_wrapper.dart
- calculate_countdown_test.dart
- Jam Sholat TV app launcher ico
- Jam Sholat TV app launcher ico 22
- Jam Sholat TV app launcher ico 23
- ic_launcher_foreground.png (xh
- ic_launcher_foreground.png (xx
- ic_launcher_foreground.png
- StatelessWidget
- prayer_card.dart
- audio_service.dart
- ic_launcher_foreground.png 30
- Jam Sholat TV app launcher ico 31
- Jam Sholat TV app launcher ico 32
- Modern single-story mosque wit
- Release Tag Process (CHANGELOG
- prayer_repository.dart
- app_theme.dart
- event_image.dart
- shalat_screen.dart
- dart:io
- Launcher Foreground Icon - Mos
- countdown_result.dart
- package:flutter/material.dart
- MainActivity.kt
- Analysis Options flutter_lints
- Toolchain FVM Pinned Flutter 3
- AppStatus
- Architectural Layers - Separat

## God Nodes (most connected - your core abstractions)
1. `ConfigProvider` - 17 edges
2. `Jam Sholat TV app launcher icon (xhdpi, 96x96 PNG): white mosque with teal crescent on navy square` - 7 edges
3. `Jam Sholat TV app launcher icon (xxhdpi, 144x144 PNG): white mosque with teal crescent on navy square` - 7 edges
4. `Jam Sholat TV app launcher icon (xxxhdpi, 192x192 PNG): white mosque with teal crescent on navy square` - 7 edges
5. `AppProvider` - 6 edges
6. `icon.png — 512x512 8-bit RGBA PNG, 238 KB, fully opaque (alpha 255, color type 6, no transparency)` - 6 edges
7. `FinancialSummary` - 5 edges
8. `Finite State Machine AppStatus Transitions` - 5 edges
9. `Jam Sholat TV app launcher icon (hdpi): white mosque with teal crescent on navy square` - 5 edges
10. `Jam Sholat TV app launcher icon (mdpi): white mosque with teal crescent on navy square (48x48 baseline)` - 5 edges

## Surprising Connections (you probably didn't know these)
- `Data Layer Repository Pattern (Service + Repository)` --semantically_similar_to--> `Thin-UI State-Driven Architecture (stateless screens + AppProvider)`  [INFERRED] [semantically similar]
  .claude/skills/flutter-apply-architecture-best-practices/SKILL.md → docs/ARCHITECTURE.md
- `Toolchain FVM Pinned Flutter 3.41.1` --semantically_similar_to--> `FVM Quick Start Onboarding (Flutter 3.41.1)`  [INFERRED] [semantically similar]
  docs/DEVELOPMENT.md → README.md
- `Core Features Offline First (adhan_dart Kemenag, Live Makkah)` --semantically_similar_to--> `Prayer Calculation On-Device adhan_dart Kemenag Method (fajr20 isha18, ihtiyat, madhab)`  [INFERRED] [semantically similar]
  README.md → docs/DATA_SOURCES.md
- `flutter_launcher_icons config — android:true ios:false image_path: "assets/images/icon.png" adaptive_icon_background: "#FFFFFF" adaptive_icon_foreground: "assets/images/icon.png" (pubspec.yaml:52-57)` --references--> `Android launcher icon role — generated mipmap/ic_launcher via flutter_launcher_icons, single source for classic + adaptive foreground`  [INFERRED]
  pubspec.yaml → assets/images/icon.png
- `icon.png — 512x512 8-bit RGBA PNG, 238 KB, fully opaque (alpha 255, color type 6, no transparency)` --references--> `Flutter asset bundle — "assets/images/" declared in pubspec.yaml flutter/assets (pubspec.yaml:46)`  [EXTRACTED]
  assets/images/icon.png → pubspec.yaml

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Tag-Driven Release Pipeline (Changelog + Git Tag + GitHub Workflow APK + Release)** — changelog_v2_0_0_offline_release, docs_development_release_tag_process, github_workflows_android_build_android_release_workflow, github_workflows_android_build_apk_build, github_workflows_android_build_github_release [EXTRACTED 1.00]
- **Prayer State Machine Flow (AppStatus + AppProvider heartbeat + MainController mapping)** — claude_appprovider_state_machine, claude_appstatus_enum, claude_maincontroller_screen_switch, docs_state_machine_appstatus_finite_state_machine, docs_architecture_one_second_heartbeat [EXTRACTED 1.00]
- **Offline Config Editing Loop (Local Server API + Web Dashboard + Config Layering Hot-Apply)** — claude_local_config_server, docs_data_sources_local_config_server_api, assets_web_index_dashboard_editor, docs_architecture_config_layering, assets_web_index_config_sections [EXTRACTED 1.00]
- **Islamic Launcher Icon Composition** — android_app_src_main_res_drawable_hdpi_ic_launcher_foreground_file, android_app_src_main_res_drawable_hdpi_ic_launcher_foreground_mosque_arch, android_app_src_main_res_drawable_hdpi_ic_launcher_foreground_crescent_star, android_app_src_main_res_drawable_hdpi_ic_launcher_foreground_color_palette [EXTRACTED 1.00]
- **Adaptive Icon Foreground with Islamic Branding** — android_app_src_main_res_drawable_hdpi_ic_launcher_foreground_adaptive_foreground_layer, android_app_src_main_res_drawable_hdpi_ic_launcher_foreground_islamic_branding, android_app_src_main_res_drawable_hdpi_ic_launcher_foreground_file [INFERRED 0.85]
- **Launcher Icon Visual Composition - Mosque and Islamic Symbol on Dark Blue** — android_app_src_main_res_drawable_mdpi_ic_launcher_foreground_launcher_icon, android_app_src_main_res_drawable_mdpi_ic_launcher_foreground_mosque_silhouette, android_app_src_main_res_drawable_mdpi_ic_launcher_foreground_crescent_star_symbol [EXTRACTED 1.00]
- **Launcher Icon Visual Composition - Mosque and Islamic Symbol on Dark Blue** — android_app_src_main_res_drawable_xhdpi_ic_launcher_foreground_ic_launcher_foreground_png, android_app_src_main_res_drawable_xhdpi_ic_launcher_foreground_white_mosque_silhouette, android_app_src_main_res_drawable_xhdpi_ic_launcher_foreground_crescent_star_symbol, android_app_src_main_res_drawable_xhdpi_ic_launcher_foreground_dark_navy_background [EXTRACTED 1.00]
- **Adaptive Icon Foreground with Islamic Branding** — android_app_src_main_res_drawable_xhdpi_ic_launcher_foreground_adaptive_icon_foreground, android_app_src_main_res_drawable_xhdpi_ic_launcher_foreground_islamic_branding, android_app_src_main_res_drawable_xhdpi_ic_launcher_foreground_jam_sholat_tv [INFERRED 0.85]
- **Launcher Icon Visual Composition - Mosque and Islamic Symbol on Dark Blue** — android_app_src_main_res_drawable_xxhdpi_ic_launcher_foreground_ic_launcher_foreground_png, android_app_src_main_res_drawable_xxhdpi_ic_launcher_foreground_white_mosque_silhouette, android_app_src_main_res_drawable_xxhdpi_ic_launcher_foreground_crescent_star_symbol, android_app_src_main_res_drawable_xxhdpi_ic_launcher_foreground_dark_navy_background [EXTRACTED 1.00]
- **Adaptive Icon Foreground with Islamic Branding** — android_app_src_main_res_drawable_xxhdpi_ic_launcher_foreground_adaptive_icon_foreground, android_app_src_main_res_drawable_xxhdpi_ic_launcher_foreground_islamic_branding, android_app_src_main_res_drawable_xxhdpi_ic_launcher_foreground_jam_sholat_tv [INFERRED 0.85]
- **Islamic iconography composition for launcher icon** — android_app_src_main_res_drawable_xxxhdpi_ic_launcher_foreground_white_mosque_silhouette_with_arched_portal, android_app_src_main_res_drawable_xxxhdpi_ic_launcher_foreground_teal_crescent_moon_and_star_finial, android_app_src_main_res_drawable_xxxhdpi_ic_launcher_foreground_navy_blue_background_field, android_app_src_main_res_drawable_xxxhdpi_ic_launcher_foreground_jam_sholat_tv_islamic_branding [INFERRED 0.85]
- **Launcher icon composition: mosque + crescent finial + navy field form Islamic branding** — android_app_src_main_res_mipmap_xhdpi_ic_launcher_mosque_silhouette, android_app_src_main_res_mipmap_xhdpi_ic_launcher_crescent_moon_star, android_app_src_main_res_mipmap_xhdpi_ic_launcher_navy_background, android_app_src_main_res_mipmap_xhdpi_ic_launcher_islamic_visual_identity [INFERRED 0.85]
- **Launcher icon composition: mosque + crescent finial + navy field form Islamic branding** — android_app_src_main_res_mipmap_xxhdpi_ic_launcher_mosque_silhouette, android_app_src_main_res_mipmap_xxhdpi_ic_launcher_crescent_moon_star, android_app_src_main_res_mipmap_xxhdpi_ic_launcher_navy_background, android_app_src_main_res_mipmap_xxhdpi_ic_launcher_islamic_visual_identity [INFERRED 0.85]
- **Launcher icon composition: mosque + crescent finial + navy field form Islamic branding** — android_app_src_main_res_mipmap_xxxhdpi_ic_launcher_mosque_silhouette, android_app_src_main_res_mipmap_xxxhdpi_ic_launcher_crescent_moon_star, android_app_src_main_res_mipmap_xxxhdpi_ic_launcher_navy_background, android_app_src_main_res_mipmap_xxxhdpi_ic_launcher_islamic_visual_identity [INFERRED 0.85]
- **Wallpaper composition: modern mosque + golden lattice arches + landscaped courtyard under bright daytime sky forms welcoming home-screen backdrop** — assets_images_background_masjid_modern_mosque_rendering, assets_images_background_masjid_golden_lattice_arches, assets_images_background_masjid_landscaped_courtyard, assets_images_background_masjid_bright_daytime_mood [INFERRED 0.85]
- **Icon composition: deep navy opaque field (#02164E) + centered white mosque arch (~40k white px) + teal apex accent (#2F8E8B) forms high-contrast Islamic minimalist mark legible at launcher size** — assets_images_icon_navy_background, assets_images_icon_white_mosque_arch, assets_images_icon_teal_dome_crescent_accent, assets_images_icon_flat_minimal_style [INFERRED 0.90]

## Communities (51 total, 5 thin omitted)

### Community 0 - "local_server_service.dart"
Cohesion: 0.03
Nodes (72): dart:typed_data, Handler, Handler get, HttpServer?, _assetBundleHandler, _authMiddleware, _authToken, _buildHandler (+64 more)

### Community 1 - "app_provider.dart"
Cohesion: 0.03
Nodes (68): config_provider.dart, ConfigProvider get, ../../core/utils/date_formatter.dart, ../../data/repositories/financial_repository.dart, ../../data/repositories/prayer_repository.dart, ../../data/services/audio_service.dart, DateTime get, ../../domain/use_cases/calculate_countdown.dart (+60 more)

### Community 2 - "app_constants.dart"
Cohesion: 0.04
Nodes (50): adzanBeepAssetPath, adzanDuration, AppConstants, backgroundImage, calculationMethod, calculationMethodNames, elevationMeters, enableFinancialReport (+42 more)

### Community 3 - "config_provider.dart"
Cohesion: 0.04
Nodes (48): AppConfig get, double get, FinancialSummary get, int get, adzanDuration, applyConfig, backgroundImage, calculationMethod (+40 more)

### Community 4 - "main_controller.dart"
Cohesion: 0.06
Nodes (44): ../app/providers/config_provider.dart, ChangeNotifier, ../../core/constants/app_enum.dart, ../core/theme/app_theme.dart, ../core/widgets/prayer_card.dart, GlobalKey, build, _buildDebugFab (+36 more)

### Community 5 - "event_screen.dart"
Cohesion: 0.05
Nodes (42): app/masjid_app.dart, ../../domain/models/event_image.dart, RemoteKeyDetector, _RemoteKeyDetectorState, configProvider, initializeDateFormatting, main, null (+34 more)

### Community 6 - "app_config.dart"
Cohesion: 0.05
Nodes (43): dart:math, event_image.dart, financial_summary.dart, adzanDuration, AppConfig, backgroundImage, calculationMethod, defaults (+35 more)

### Community 7 - "local_server_service_test.dart"
Cohesion: 0.07
Nodes (32): dart:convert, Directory, File, LocalServerService, package:flutter_test/flutter_test.dart, package:intl/date_symbol_data_local.dart, package:jam_sholat_tv/app/providers/config_provider.dart, package:jam_sholat_tv/core/constants/app_constants.dart (+24 more)

### Community 8 - "follower_sync_service.dart"
Cohesion: 0.06
Nodes (35): bool get, dart:async, Dio, Duration, build, _cancelHold, child, createState (+27 more)

### Community 9 - "financial_report_card.dart"
Cohesion: 0.06
Nodes (32): DateTime?, ../../domain/models/financial_summary.dart, DateFormatter, getFullDate, fetchMonthlySummary, FinancialRepository, _service, FinancialService (+24 more)

### Community 10 - "Finite State Machine AppStatus"
Cohesion: 0.10
Nodes (22): Changelog Jumat Bug Fixes (v1.2.1, v1.3.1), AppProvider State Machine (Timer.periodic 1s _onTick), AppStatus Enum (home, adzan, iqomah, jumatMode, shalat, isyraq), Jam Sholat TV Flutter Android App (Masjid Al Hijrah CGE), Friday Jumat Translation Fragile Area (5 sites), MainController AppStatus Switch Mapping, Prayer Cycle Heart (Home -> Adzan -> Iqomah -> Shalat -> Home), Data Layer Repository Pattern (Service + Repository) (+14 more)

### Community 11 - "live_makkah_screen.dart"
Cohesion: 0.11
Nodes (18): build, _controller, createState, dateHijriah, dateMasehi, initState, jadwal, LiveMakkahScreen (+10 more)

### Community 12 - "../../core/widgets/background_"
Cohesion: 0.15
Nodes (12): ../../core/widgets/background_image.dart, dart:ui, AdzanScreen, build, prayerName, build, countdown, IqomahScreen (+4 more)

### Community 13 - "financial_report_screen.dart"
Cohesion: 0.18
Nodes (10): ../../core/widgets/side_prayer_panel.dart, financial_report_card.dart, build, dateHijriah, dateMasehi, jadwal, masjidName, nextPrayerName (+2 more)

### Community 14 - "Local Config Server API Endpoi"
Cohesion: 0.22
Nodes (10): Web Editor Config Sections (Identitas, Durasi, Waktu Sholat, Background, Event, Makkah, Keuangan, Peran), Washol TV Dashboard Konfigurasi Web Editor (assets/web/index.html), Sidebar Navigation and View Switching (nav-item, view.active), Local Config Server (LocalServerService shelf 0.0.0.0:8080), Config Layering (AppConstants defaults + SharedPreferences persisted overrides + hot-apply), Startup Flow (main.dart -> MasjidApp MultiProvider -> MainController), Financial Report Offline Sample (FinancialSummary.offlineSample editable via web editor), Local Config Server API Endpoints (GET/POST /api/config, image uploads, GET /images) (+2 more)

### Community 15 - "../../core/constants/app_const"
Cohesion: 0.22
Nodes (8): ../../core/constants/app_constants.dart, CalculatePrayerTimes, call, _madhabFrom, call, GetIqomahDuration, ../models/app_config.dart, package:adhan_dart/adhan_dart.dart

### Community 16 - "side_prayer_panel.dart"
Cohesion: 0.20
Nodes (9): build, _buildPrayerItem, dateHijriah, dateMasehi, jadwal, masjidName, nextPrayerName, time (+1 more)

### Community 17 - "icon.png — 512x512 8-bit RGBA "
Cohesion: 0.36
Nodes (9): Flutter asset bundle — "assets/images/" declared in pubspec.yaml flutter/assets (pubspec.yaml:46), Branding identity — Jam Sholat TV / Washol TV mosque prayer-time TV app (Masjid Al Hijrah CGE Depok), navy/teal Islamic palette, Flat minimalist vector style — navy/white/teal triad, geometric, rounded-square safe zone for adaptive icon, Android launcher icon role — generated mipmap/ic_launcher via flutter_launcher_icons, single source for classic + adaptive foreground, Deep navy flat background — #02164E (2,22,78) covering ~214k px (~81.7%), opaque fill, icon.png — 512x512 8-bit RGBA PNG, 238 KB, fully opaque (alpha 255, color type 6, no transparency), flutter_launcher_icons config — android:true ios:false image_path: "assets/images/icon.png" adaptive_icon_background: "#FFFFFF" adaptive_icon_foreground: "assets/images/icon.png" (pubspec.yaml:52-57), Teal dome / crescent-star finial accent — #2F8E8B (47,142,139) at apex bbox 210,56–290,143 (~80x87 px) (+1 more)

### Community 18 - "home_screen.dart"
Cohesion: 0.22
Nodes (8): ../../core/widgets/bottom_marquee_bar.dart, build, dateHijriah, dateMasehi, jadwal, locationName, masjidName, time

### Community 19 - "home_wrapper.dart"
Cohesion: 0.22
Nodes (8): home_screen.dart, build, dateHijriah, dateMasehi, jadwal, locationName, masjidName, time

### Community 20 - "calculate_countdown_test.dart"
Cohesion: 0.22
Nodes (7): CalculateCountdown, call, ../models/countdown_result.dart, package:jam_sholat_tv/domain/use_cases/calculate_countdown.dart, calculator, jadwal, main

### Community 21 - "Jam Sholat TV app launcher ico"
Cohesion: 0.32
Nodes (8): Jam Sholat TV app launcher icon (xhdpi, 96x96 PNG): white mosque with teal crescent on navy square, Teal crescent moon with star finial atop the minaret, Islamic visual identity for Masjid Al Hijrah masjid-display app, Legacy mipmap launcher fallback for pre-API-26 (complements adaptive-icon in mipmap-anydpi-v26), White mosque dome-and-minaret silhouette (central foreground motif), Dark navy square background field, Android TV launcher asset (LEANBACK_LAUNCHER, 96x96 xhdpi variant of multi-density set), Android mipmap xhdpi density bucket (96x96, ~320dpi, 2x baseline)

### Community 22 - "Jam Sholat TV app launcher ico 22"
Cohesion: 0.32
Nodes (8): Jam Sholat TV app launcher icon (xxhdpi, 144x144 PNG): white mosque with teal crescent on navy square, Teal crescent moon with star finial atop the minaret, Islamic visual identity for Masjid Al Hijrah masjid-display app, Legacy mipmap launcher fallback for pre-API-26 (complements adaptive-icon in mipmap-anydpi-v26), White mosque dome-and-minaret silhouette (central foreground motif), Dark navy square background field, Android TV launcher asset (LEANBACK_LAUNCHER, 144x144 xxhdpi variant of multi-density set), Android mipmap xxhdpi density bucket (144x144, ~480dpi, 3x baseline)

### Community 23 - "Jam Sholat TV app launcher ico 23"
Cohesion: 0.32
Nodes (8): Jam Sholat TV app launcher icon (xxxhdpi, 192x192 PNG): white mosque with teal crescent on navy square, Teal crescent moon with star finial atop the minaret, Islamic visual identity for Masjid Al Hijrah masjid-display app, Legacy mipmap launcher fallback for pre-API-26 (complements adaptive-icon in mipmap-anydpi-v26), White mosque dome-and-minaret silhouette (central foreground motif), Dark navy square background field, Android TV launcher asset (LEANBACK_LAUNCHER, 192x192 xxxhdpi variant of multi-density set), Android mipmap xxxhdpi density bucket (192x192, ~640dpi, 4x baseline)

### Community 24 - "ic_launcher_foreground.png (xh"
Cohesion: 0.38
Nodes (7): Android Adaptive Icon Foreground Layer, Teal Crescent Moon and Star Islamic Symbol, Dark Navy Blue Background, ic_launcher_foreground.png (xhdpi density), Islamic Prayer App Branding, Jam Sholat TV Android App, White Mosque Silhouette with Dome and Arch Doorway

### Community 25 - "ic_launcher_foreground.png (xx"
Cohesion: 0.38
Nodes (7): Android Adaptive Icon Foreground Layer, Teal Crescent Moon and Star Islamic Symbol, Dark Navy Blue Background, ic_launcher_foreground.png (xxhdpi density), Islamic Prayer App Branding, Jam Sholat TV Android App, White Mosque Silhouette with Dome and Arch Doorway

### Community 26 - "ic_launcher_foreground.png"
Cohesion: 0.38
Nodes (6): Android adaptive icon foreground layer, Jam Sholat TV Islamic branding, Navy blue background field, Teal crescent moon and star finial, White mosque silhouette with arched portal, xxxhdpi density bucket (432x432, 4.0x)

### Community 27 - "StatelessWidget"
Cohesion: 0.29
Nodes (7): MasjidApp, SidePrayerPanel, FinancialReportCard, FinancialReportScreen, HomeScreen, HomeWrapper, StatelessWidget

### Community 28 - "prayer_card.dart"
Cohesion: 0.29
Nodes (6): build, countdown, isNext, label, PrayerCard, time

### Community 29 - "audio_service.dart"
Cohesion: 0.29
Nodes (6): AudioService, playAdzanBeep, _player, playIqomahBeep, package:audioplayers/audioplayers.dart, static final AudioPlayer

### Community 30 - "ic_launcher_foreground.png 30"
Cohesion: 0.47
Nodes (5): Adaptive Icon Foreground Layer, Navy Blue and Turquoise Color Palette, Turquoise Crescent Moon and Star, Islamic Prayer App Branding, White Mosque Arch Silhouette

### Community 31 - "Jam Sholat TV app launcher ico 31"
Cohesion: 0.40
Nodes (6): Jam Sholat TV app launcher icon (hdpi): white mosque with teal crescent on navy square, Teal crescent moon with star finial atop the dome, Android mipmap hdpi density bucket (~240dpi, ~72x72px launcher asset), Islamic visual identity of a masjid display app, White mosque dome-and-minaret silhouette (central subject), Dark navy rounded-square background field

### Community 32 - "Jam Sholat TV app launcher ico 32"
Cohesion: 0.40
Nodes (6): Jam Sholat TV app launcher icon (mdpi): white mosque with teal crescent on navy square (48x48 baseline), Teal crescent moon with star finial atop the dome, Islamic visual identity of a masjid display app, Android mipmap mdpi density bucket (160dpi baseline, 48x48px launcher asset), White mosque dome-and-arch silhouette (double arch with central doorway), Dark navy rounded-square background field

### Community 33 - "Modern single-story mosque wit"
Cohesion: 0.33
Nodes (6): Bright daytime aesthetic — blue sky with white clouds, warm cream facade, high-key lighting, Row of tall pointed arches filled with golden geometric lattice / mashrabiya screens, background_masjid.jpeg — bundled default wallpaper (1536x1024 progressive JPEG, 248 KB, JFIF 1.01), Landscaped forecourt — paved courtyard with pink flower beds, trimmed shrubs, palm tree and pathway, Modern single-story mosque with flat roof — 3D architectural rendering as central subject, Flutter asset bundle — 'assets/images/' declared in pubspec.yaml flutter/assets (pubspec.yaml:46)

### Community 34 - "Release Tag Process (CHANGELOG"
Cohesion: 0.33
Nodes (6): Changelog v2.0.0 Offline Major Release, Release Tag Process (CHANGELOG.md top section + git tag vX.Y.Z -> CI), Android Release GitHub Workflow (tag v* trigger), Build APK Release (fvm flutter build apk --release --build-name from tag), FVM Setup Step (dart pub global activate fvm), Create GitHub Release (softprops/action-gh-release with APK)

### Community 35 - "prayer_repository.dart"
Cohesion: 0.33
Nodes (5): ../domain/models/app_config.dart, ../../domain/use_cases/calculate_prayer_times.dart, _calculator, getTodayJadwal, PrayerRepository

### Community 36 - "app_theme.dart"
Cohesion: 0.33
Nodes (5): AppTheme, backgroundColor, cardColor, primaryColor, static const Color

### Community 37 - "event_image.dart"
Cohesion: 0.33
Nodes (5): EventImage, fromJson, toJson, type, url

### Community 38 - "shalat_screen.dart"
Cohesion: 0.33
Nodes (5): build, _buildBadge, _buildPrayerInfo, prayerName, ShalatScreen

### Community 39 - "dart:io"
Cohesion: 0.40
Nodes (4): dart:io, localIPv4, NetworkInfoHelper, package:network_info_plus/network_info_plus.dart

### Community 40 - "Launcher Foreground Icon - Mos"
Cohesion: 0.50
Nodes (4): Teal Crescent Moon and Star Islamic Symbol, Islamic Prayer Time App Branding Concept, Launcher Foreground Icon - Mosque with Crescent and Star, White Mosque Silhouette with Dome and Arch Doorway

### Community 41 - "countdown_result.dart"
Cohesion: 0.50
Nodes (3): countdown, CountdownResult, nextName

### Community 42 - "package:flutter/material.dart"
Cohesion: 0.50
Nodes (3): build, JumatScreen, package:flutter/material.dart

## Knowledge Gaps
- **475 isolated node(s):** `configProvider`, `_navigatorKey`, `build`, `_logger`, `hasInternet` (+470 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `ConfigProvider` connect `main_controller.dart` to `local_server_service.dart`, `app_provider.dart`, `config_provider.dart`, `event_screen.dart`, `local_server_service_test.dart`, `follower_sync_service.dart`?**
  _High betweenness centrality (0.084) - this node is a cross-community bridge._
- **Why does `FinancialSummary` connect `financial_report_card.dart` to `app_provider.dart`, `financial_report_screen.dart`, `app_config.dart`?**
  _High betweenness centrality (0.027) - this node is a cross-community bridge._
- **Why does `CalculateCountdown` connect `calculate_countdown_test.dart` to `app_provider.dart`?**
  _High betweenness centrality (0.014) - this node is a cross-community bridge._
- **What connects `configProvider`, `_navigatorKey`, `build` to the rest of the system?**
  _475 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `local_server_service.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.0273972602739726 - nodes in this community are weakly interconnected._
- **Should `app_provider.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.028985507246376812 - nodes in this community are weakly interconnected._
- **Should `app_constants.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.0392156862745098 - nodes in this community are weakly interconnected._