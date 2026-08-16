import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

import '../../core/constants/app_enum.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/models/financial_summary.dart';
import '../../data/repositories/financial_repository.dart';
import '../../data/repositories/prayer_repository.dart';
import '../../data/services/audio_service.dart';
import '../../domain/use_cases/calculate_countdown.dart';
import '../../domain/use_cases/get_iqomah_duration.dart';
import 'config_provider.dart';

/// The app's central state machine.
///
/// A 1-second timer drives every transition: clock/date strings, the
/// home→adzan→iqomah→shalat cycle, countdowns, the event/report home modes, the
/// special live (Makkah) mode and the midnight data re-sync. Screens are pure
/// presentational widgets that read from this provider.
class AppProvider extends ChangeNotifier {
  final Logger _logger = Logger();

  bool hasInternet = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isFetchingFinance = false;

  String timeString = "";
  AppStatus status = AppStatus.home;
  String currentPrayerName = "";
  int jumatCounter = 0;
  int iqomahCounter = 0;
  int adzanCounter = 0;
  int shalatCounter = 0;
  int isyraqCounter = 0;
  bool isEventMode = false;
  bool isReportMode = false;
  int currentEventIndex = 0;

  String nextPrayerName = "";
  String countdownString = "";
  String dateMasehi = "";
  String dateHijriah = "";
  bool isSpecialLiveMode = false;

  Map<String, String> jadwal = {
    "Subuh": "--:--",
    "Syuruq": "--:--",
    "Dzuhur": "--:--",
    "Ashar": "--:--",
    "Maghrib": "--:--",
    "Isya": "--:--",
  };

  FinancialSummary? financialSummary;

  final FinancialRepository _financialRepository = FinancialRepository();
  final PrayerRepository _prayerRepository = PrayerRepository();
  final CalculateCountdown _calculateCountdown = CalculateCountdown();
  final GetIqomahDuration _getIqomahDuration = GetIqomahDuration();

  DateTime? _fakeTime;
  Timer? _timer;

  ConfigProvider? _config;
  ConfigProvider get config => _config ?? ConfigProvider();

  DateTime get currentDateTime => _fakeTime ?? DateTime.now();

  void init() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    _initConnectivity();
    loadInitialData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void updateConfig(ConfigProvider config) {
    _config = config;
  }

  void _initConnectivity() {
    Connectivity().checkConnectivity().then(_updateConnectionStatus);

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    bool oldInternetStatus = hasInternet;
    hasInternet = !results.contains(ConnectivityResult.none);

    if (hasInternet && !oldInternetStatus) {
      // Schedules are computed locally; only the financial report still needs
      // the network to refresh on reconnect.
      updateFinancialReport();
    }
    notifyListeners();
  }

  void loadInitialData() {
    jadwal = _prayerRepository.getTodayJadwal();
    checkInitialStatus(jadwal);
    notifyListeners();
    updateFinancialReport();
  }

  Future<void> updateFinancialReport() async {
    if (_isFetchingFinance || !hasInternet) return;

    _isFetchingFinance = true;
    try {
      final data = await _financialRepository.fetchMonthlySummary();
      if (data != null) {
        financialSummary = data;
        _logger.d("Report updated: $data");
        notifyListeners();
      }
    } catch (e) {
      _logger.e("Failed to fetch financial report: $e");
    } finally {
      _isFetchingFinance = false;
    }
  }

  void _onTick() {
    if (_config == null) return;

    if (_fakeTime != null) {
      _fakeTime = _fakeTime!.add(const Duration(seconds: 1));
    }
    final now = _fakeTime ?? DateTime.now();

    _updateDateTimeStrings(now);
    _handleCycleLogic(now);
    _handlePrayerStatusLogic();
    _checkSpecialLiveConditions(now);
    _handleMidnightSync(now);

    notifyListeners();
  }

  void _handleMidnightSync(DateTime now) {
    if (now.hour == 0 && now.minute == 0 && now.second == 0) {
      // The date rolled over, so the locally-computed jadwal changes too.
      final fresh = _prayerRepository.getTodayJadwal(now: now);
      jadwal = fresh;
      if (status == AppStatus.home) checkInitialStatus(fresh);
      updateFinancialReport();
      notifyListeners();
    }
  }

  void _updateDateTimeStrings(DateTime now) {
    timeString = DateFormat('HH:mm').format(now);

    final correction = config.hijriCorrection;
    final dates = DateFormatter.getFullDate(correction);
    dateMasehi = dates['masehi']!;
    dateHijriah = dates['hijriah']!;

    final result = _calculateCountdown(jadwal);
    nextPrayerName = result.nextName;
    countdownString = result.countdown;
  }

  void _handleCycleLogic(DateTime now) {
    if (status != AppStatus.home) return;

    bool isFriday = now.weekday == DateTime.friday;
    bool canShowReport = hasInternet && financialSummary != null;
    bool canShowEvent = config.eventImages.isNotEmpty;

    int effectiveReportDuration = canShowReport ? config.reportDuration : 0;
    int effectiveEventDuration = canShowEvent ? config.eventDuration : 0;
    int totalCycle =
        config.homeDuration + effectiveEventDuration + effectiveReportDuration;

    int currentSec = _timer!.tick % totalCycle;

    if (currentSec < config.homeDuration) {
      isEventMode = false;
      isReportMode = false;
    } else if (currentSec < (config.homeDuration + effectiveEventDuration)) {
      if (!isEventMode && canShowEvent) {
        currentEventIndex = (currentEventIndex + 1) % config.eventImages.length;
      }
      isEventMode = true;
      isReportMode = false;
    } else {
      isEventMode = false;
      isReportMode = true;
    }

    for (var entry in jadwal.entries) {
      String prayerKey = entry.key;
      String prayerDisplayName = entry.key;

      if (isFriday && prayerKey == "Dzuhur") {
        prayerDisplayName = "Jumat";
      }

      if (entry.value == timeString && now.second == 0) {
        if (prayerKey == "Syuruq") {
          status = AppStatus.iqomah;
          currentPrayerName = "Syuruq";
          iqomahCounter = config.waitingIsyraqDuration;
          AudioService.playAdzanBeep();
        } else {
          _startAdzan(prayerDisplayName);
        }
        notifyListeners();
        break;
      }
    }
  }

  void _startAdzan(String prayerName) {
    status = AppStatus.adzan;
    currentPrayerName = prayerName;
    adzanCounter = (_fakeTime == null) ? config.adzanDuration : 5;
    AudioService.playAdzanBeep();
    notifyListeners();
  }

  void _startIsyraq() {
    status = AppStatus.isyraq;
    isyraqCounter = (_fakeTime == null) ? config.isyraqDuration : 5;
    AudioService.playAdzanBeep();
    notifyListeners();
  }

  void _handlePrayerStatusLogic() {
    switch (status) {
      case AppStatus.adzan:
        adzanCounter--;
        if (adzanCounter <= 0) _handleAdzanTransition();
        break;

      case AppStatus.iqomah:
        iqomahCounter--;
        if (iqomahCounter <= 10 && iqomahCounter > 0) {
          AudioService.playIqomahBeep();
        }
        if (iqomahCounter <= 0) {
          if (currentPrayerName == "Syuruq") {
            _startIsyraq();
          } else {
            _finishPrayerCycle();
          }
        }
        break;

      case AppStatus.jumatMode:
        jumatCounter--;
        if (jumatCounter <= 0) status = AppStatus.home;
        break;

      case AppStatus.shalat:
        shalatCounter--;
        if (shalatCounter <= 0) status = AppStatus.home;
        break;

      case AppStatus.isyraq:
        isyraqCounter--;
        if (isyraqCounter <= 0) status = AppStatus.home;
        break;

      default:
        break;
    }
  }

  void _handleAdzanTransition() {
    if (currentPrayerName == "Jumat") {
      status = AppStatus.jumatMode;
      jumatCounter = config.jumatDuration;
    } else {
      status = AppStatus.iqomah;
      iqomahCounter = !kDebugMode
          ? _getIqomahDuration(currentPrayerName)
          : config.iqomahTestingDuration;
    }
    notifyListeners();
  }

  void _finishPrayerCycle() {
    status = AppStatus.shalat;
    shalatCounter = config.shalatDuration;
    AudioService.playAdzanBeep();
    notifyListeners();
  }

  void _checkSpecialLiveConditions(DateTime now) {
    final bool isNearMaghrib = _isMinutesBeforePrayer(
      "Maghrib",
      config.minutesBeforeMaghrib,
      now,
    );
    final bool isFriday = now.weekday == DateTime.friday;
    final bool isNearJumat =
        isFriday &&
        _isMinutesBeforePrayer("Jumat", config.minutesBeforeJumat, now);

    isSpecialLiveMode = (isNearMaghrib || isNearJumat) && hasInternet;
  }

  bool _isMinutesBeforePrayer(String prayerName, int minutes, DateTime now) {
    String key = prayerName;
    if (prayerName == "Jumat") key = "Dzuhur";

    final String? tStr = jadwal[key];
    if (tStr == null || tStr == "--:--") return false;

    final parts = tStr.split(':');
    final pTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
    final diff = pTime.difference(now).inSeconds;

    return diff >= 0 && diff <= (minutes * 60);
  }

  void enableFakeTime() {
    final now = DateTime.now();
    final maghrib = jadwal["Maghrib"] ?? "18:00";
    final p = maghrib.split(':');
    _fakeTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(p[0]),
      int.parse(p[1]) - 1,
      55,
    );
    status = AppStatus.home;
    notifyListeners();
  }

  void enableFakeSyuruqTime() {
    final now = DateTime.now();
    final syuruq = jadwal["Syuruq"] ?? "06:00";
    final p = syuruq.split(':');

    _fakeTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(p[0]),
      int.parse(p[1]),
      0,
    ).subtract(const Duration(seconds: 5));

    status = AppStatus.home;
    notifyListeners();
  }

  void enableFakeJumatTime() {
    final now = DateTime.now();

    int daysUntilFriday = (DateTime.friday - now.weekday + 7) % 7;
    DateTime targetFriday = now.add(Duration(days: daysUntilFriday));

    final dzuhur = jadwal["Dzuhur"] ?? "12:00";
    final p = dzuhur.split(':');

    _fakeTime = DateTime(
      targetFriday.year,
      targetFriday.month,
      targetFriday.day,
      int.parse(p[0]),
      int.parse(p[1]),
      0,
    ).subtract(const Duration(seconds: 5));

    status = AppStatus.home;
    _logger.i(
      "Fake Time set to Friday at ${DateFormat('HH:mm:ss').format(_fakeTime!)}",
    );

    _updateDateTimeStrings(_fakeTime!);
    notifyListeners();
  }

  void checkInitialStatus(Map<String, String> data) {
    final now = DateTime.now();
    bool isFriday = now.weekday == DateTime.friday;

    data.forEach((name, time) {
      String displayName = name;
      if (isFriday && name == "Dzuhur") displayName = "Jumat";

      final parts = time.split(':');
      final pTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );

      if (name == "Syuruq") {
        final endWaiting = pTime.add(const Duration(seconds: 900));
        final endIsyraq = endWaiting.add(const Duration(seconds: 600));

        if (now.isAfter(pTime) && now.isBefore(endWaiting)) {
          status = AppStatus.iqomah;
          currentPrayerName = "Syuruq";
          iqomahCounter = endWaiting.difference(now).inSeconds;
        } else if (now.isAfter(endWaiting) && now.isBefore(endIsyraq)) {
          status = AppStatus.isyraq;
          isyraqCounter = endIsyraq.difference(now).inSeconds;
        }
        return;
      }

      final endAdzan = pTime.add(Duration(seconds: config.adzanDuration));

      if (now.isAfter(pTime) && now.isBefore(endAdzan)) {
        status = AppStatus.adzan;
        currentPrayerName = displayName;
        adzanCounter = endAdzan.difference(now).inSeconds;
        return;
      }

      int currentIqomahDuration = (displayName == "Jumat")
          ? 0
          : _getIqomahDuration(name);
      final currentContentDuration = (displayName == "Jumat")
          ? config.jumatDuration
          : currentIqomahDuration;
      final endCycle = endAdzan.add(Duration(seconds: currentContentDuration));

      if (now.isAfter(endAdzan) && now.isBefore(endCycle)) {
        currentPrayerName = displayName;
        if (displayName == "Jumat") {
          status = AppStatus.jumatMode;
          jumatCounter = endCycle.difference(now).inSeconds;
        } else {
          status = AppStatus.iqomah;
          iqomahCounter = endCycle.difference(now).inSeconds;
        }
      }
    });
  }
}
