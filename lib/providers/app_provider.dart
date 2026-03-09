import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

import '../core/constants/app_enum.dart';
import '../core/utils/date_formatter.dart';
import '../services/audio_service.dart';
import '../services/financial_service.dart';
import '../services/prayer_service.dart';
import 'config_provider.dart';

class AppProvider extends ChangeNotifier {
  final Logger _logger = Logger();

  bool hasInternet = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isDataUpdatedFromServer = false;
  bool _isFetchingPrayer = false;
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

  final FinancialService _financialService = FinancialService();
  Map<String, dynamic> financialData = {};

  DateTime? _fakeTime;
  Timer? _timer;
  final PrayerService _prayerService = PrayerService();

  ConfigProvider? _config;
  ConfigProvider get config => _config ?? ConfigProvider();

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
      if (!_isDataUpdatedFromServer) _fetchServerDataWithRetry();

      updateFinancialReport();
    }
    notifyListeners();
  }

  Future<void> loadInitialData() async {
    var local = await _prayerService.getTodayJadwalMap();
    if (local != null) {
      jadwal = local;
      checkInitialStatus(local);
      notifyListeners();
    }

    _fetchServerDataWithRetry();
    updateFinancialReport();
  }

  Future<void> _fetchServerDataWithRetry() async {
    if (_isFetchingPrayer || _isDataUpdatedFromServer || !hasInternet) return;

    _isFetchingPrayer = true;
    try {
      _logger.d("Try fetching prayer data from server...");
      await _prayerService.fetchAndSaveSixMonths();

      var fresh = await _prayerService.getTodayJadwalMap();
      if (fresh != null) {
        jadwal = fresh;
        if (status == AppStatus.home) checkInitialStatus(fresh);
        _isDataUpdatedFromServer = true;
        _logger.d("Synchronization successful!");
        notifyListeners();
      }
    } catch (e) {
      _logger.e("Synchronization failed: $e. Retrying in 30 seconds...");

      Future.delayed(const Duration(seconds: 30), () {
        _isFetchingPrayer = false;
        _fetchServerDataWithRetry();
      });
    } finally {
      _isFetchingPrayer = false;
    }
  }

  Future<void> updateFinancialReport() async {
    if (_isFetchingFinance || !hasInternet) return;

    _isFetchingFinance = true;
    try {
      final data = await _financialService.fetchSummary();
      if (data != null) {
        financialData = data;
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
      _isDataUpdatedFromServer = false;
      _fetchServerDataWithRetry();
      updateFinancialReport();
    }
  }

  void _updateDateTimeStrings(DateTime now) {
    timeString = DateFormat('HH:mm').format(now);
    final dates = DateFormatter.getFullDate();
    dateMasehi = dates['masehi']!;
    dateHijriah = dates['hijriah']!;

    final result = PrayerService.calculateCountdown(jadwal);
    nextPrayerName = result["nextName"]!;
    countdownString = result["countdown"]!;
  }

  void _handleCycleLogic(DateTime now) {
    if (status != AppStatus.home) return;

    bool canShowReport = hasInternet && financialData.isNotEmpty;
    bool canShowEvent = config.eventImages.isNotEmpty;

    int effectiveReportDuration = canShowReport ? config.reportDuration : 0;
    int effectiveEventDuration = canShowEvent ? config.eventDuration : 0;
    int totalCycle =
        config.homeDuration + effectiveEventDuration + effectiveReportDuration;

    int currentSec = _timer!.tick % totalCycle;

    bool oldEventMode = isEventMode;

    if (currentSec < config.homeDuration) {
      isEventMode = false;
      isReportMode = false;
    } else if (currentSec < (config.homeDuration + effectiveEventDuration)) {
      isEventMode = true;
      isReportMode = false;
    } else {
      isEventMode = false;
      isReportMode = true;
    }

    if (isEventMode && !oldEventMode && canShowEvent) {
      if (config.eventImages.isNotEmpty) {
        currentEventIndex = (currentEventIndex + 1) % config.eventImages.length;
      }
    }

    for (var entry in jadwal.entries) {
      if (entry.key == "Syuruq") {
        final parts = entry.value.split(':');
        final syuruqTime = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );

        final isyraqStart = syuruqTime.add(const Duration(minutes: 15));

        if (now.hour == isyraqStart.hour &&
            now.minute == isyraqStart.minute &&
            now.second == 0) {
          _startIsyraq();
          break;
        }
      }

      if (entry.key != "Syuruq" &&
          entry.value == timeString &&
          now.second == 0) {
        _startAdzan(entry.key);
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
    isyraqCounter = (_fakeTime == null) ? 600 : 5;
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
        if (iqomahCounter <= 0) _finishPrayerCycle();
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
          ? PrayerService.getIqomahDuration(currentPrayerName)
          : config.iqomahTestingDuration;
    }
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
    if (prayerName == "Jumat" && !jadwal.containsKey("Jumat")) key = "Dzuhur";
    if (prayerName == "Dzuhur" && jadwal.containsKey("Jumat")) key = "Jumat";

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
      int.parse(p[1]) + 14,
      55,
    );
    status = AppStatus.home;
    notifyListeners();
  }

  void checkInitialStatus(Map<String, String> data) {
    final now = DateTime.now();
    data.forEach((name, time) {
      if (name == "Syuruq") return;

      final parts = time.split(':');
      final pTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      final endAdzan = pTime.add(Duration(seconds: config.adzanDuration));

      if (now.isAfter(pTime) && now.isBefore(endAdzan)) {
        status = AppStatus.adzan;
        currentPrayerName = name;
        adzanCounter = endAdzan.difference(now).inSeconds;
        return;
      }

      int currentIqomahDuration = (name == "Jumat")
          ? 0
          : PrayerService.getIqomahDuration(name);
      final currentContentDuration = (name == "Jumat")
          ? config.jumatDuration
          : currentIqomahDuration;
      final endCycle = endAdzan.add(Duration(seconds: currentContentDuration));

      if (now.isAfter(endAdzan) && now.isBefore(endCycle)) {
        currentPrayerName = name;
        if (name == "Jumat") {
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
