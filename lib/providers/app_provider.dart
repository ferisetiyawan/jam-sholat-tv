import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/app_enum.dart';
import '../core/utils/date_formatter.dart';
import '../services/audio_service.dart';
import '../services/prayer_service.dart';

class AppProvider extends ChangeNotifier {
  bool hasInternet = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  String timeString = "";
  AppStatus status = AppStatus.home;
  String currentPrayerName = "";
  int jumatCounter = 0;
  int iqomahCounter = 0;
  int adzanCounter = 0;
  bool isEventMode = false;
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

  DateTime? _fakeTime;
  Timer? _timer;
  final PrayerService _prayerService = PrayerService();

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

  void _initConnectivity() {
    Connectivity().checkConnectivity().then(_updateConnectionStatus);

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    hasInternet = !results.contains(ConnectivityResult.none);
    notifyListeners();
  }

  Future<void> loadInitialData() async {
    var local = await _prayerService.getTodayJadwalMap();
    if (local != null) {
      jadwal = local;
      checkInitialStatus(local);
      notifyListeners();
    }

    await _prayerService.fetchAndSaveSixMonths();
    var fresh = await _prayerService.getTodayJadwalMap();
    if (fresh != null) {
      jadwal = fresh;
      if (status == AppStatus.home) checkInitialStatus(fresh);
      notifyListeners();
    }
  }

  void _onTick() {
    if (_fakeTime != null) {
      _fakeTime = _fakeTime!.add(const Duration(seconds: 1));
    }
    final now = _fakeTime ?? DateTime.now();

    _updateDateTimeStrings(now);
    _handleCycleLogic(now);
    _handlePrayerStatusLogic();
    _checkSpecialLiveConditions(now);

    notifyListeners();
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

    int totalCycle = AppConstants.homeDuration + AppConstants.eventDuration;
    int currentSec = _timer!.tick % totalCycle;

    bool oldEventMode = isEventMode;
    isEventMode = currentSec >= AppConstants.homeDuration;

    if (isEventMode && !oldEventMode) {
      currentEventIndex =
          (currentEventIndex + 1) % AppConstants.eventImages.length;
    }

    for (var entry in jadwal.entries) {
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
    adzanCounter = (_fakeTime == null) ? AppConstants.adzanDuration : 5;
    AudioService.playAdzanBeep();
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

      default:
        break;
    }
  }

  void _handleAdzanTransition() {
    if (currentPrayerName == "Jumat") {
      status = AppStatus.jumatMode;
      jumatCounter = AppConstants.jumatDuration;
    } else {
      status = AppStatus.iqomah;
      iqomahCounter = !kDebugMode
          ? PrayerService.getIqomahDuration(currentPrayerName)
          : AppConstants.iqomahTestingDuration;
    }
  }

  void _finishPrayerCycle() {
    status = AppStatus.home;
    AudioService.playAdzanBeep();
  }

  void _checkSpecialLiveConditions(DateTime now) {
    final bool isNearMaghrib = _isMinutesBeforePrayer(
      "Maghrib",
      AppConstants.minutesBeforeMaghrib,
      now,
    );
    final bool isFriday = now.weekday == DateTime.friday;
    final bool isNearJumat =
        isFriday &&
        _isMinutesBeforePrayer("Jumat", AppConstants.minutesBeforeJumat, now);

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
      final endAdzan = pTime.add(Duration(seconds: AppConstants.adzanDuration));

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
          ? AppConstants.jumatDuration
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
