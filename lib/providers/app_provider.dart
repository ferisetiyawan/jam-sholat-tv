import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/app_enum.dart';

import '../core/utils/date_formatter.dart';

import '../services/prayer_service.dart';
import '../services/audio_service.dart';

class AppProvider extends ChangeNotifier {
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
    "Subuh": "--:--", "Syuruq": "--:--", "Dzuhur": "--:--", 
    "Ashar": "--:--", "Maghrib": "--:--", "Isya": "--:--"
  };

  // Fake Time for Testing Purposes
  DateTime? _fakeTime;
  Timer? _timer;
  final PrayerService _prayerService = PrayerService();

  void init() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) => _onTick());
    loadInitialData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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

    _updateDateTime(now);
    _handleCycleLogic(now);
    _handlePrayerStatusLogic();
    _checkSpecialLiveConditions(now);

    notifyListeners();
  }

  void _updateDateTime(DateTime now) {
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
    
    if (currentSec < AppConstants.homeDuration) {
      isEventMode = false;
    } else {
      if (!isEventMode) {
        currentEventIndex = (currentEventIndex + 1) % AppConstants.eventImages.length;
      }
      isEventMode = true;
    }

    jadwal.forEach((name, time) {
      if (name != "Syuruq" && timeString == time && now.second == 0) {
        status = AppStatus.adzan;
        currentPrayerName = name;
        adzanCounter = (_fakeTime == null) ? AppConstants.adzanDuration : 5;
        AudioService.playAdzanBeep();
      }
    });
  }

  void _handlePrayerStatusLogic() {
    if (status == AppStatus.adzan) {
      adzanCounter--;
      if (adzanCounter <= 0) {
        if (currentPrayerName == "Jumat") {
          status = AppStatus.jumatMode;
          jumatCounter = AppConstants.jumatDuration;
        } else {
          status = AppStatus.iqomah;
          iqomahCounter = !kDebugMode ? PrayerService.getIqomahDuration(currentPrayerName) : 15;
        }
      }
    }

    if (status == AppStatus.iqomah) {
      iqomahCounter--;
      if (iqomahCounter <= 10 && iqomahCounter > 0) AudioService.playIqomahBeep();
      if (iqomahCounter <= 0) {
        status = AppStatus.home;
        AudioService.playAdzanBeep();
      }
    }

    if (status == AppStatus.jumatMode) {
      jumatCounter--;
      if (jumatCounter <= 0) status = AppStatus.home;
    }
  }

  // Helper method to enable fake time for testing
  void enableFakeTime() {
    final maghrib = jadwal["Maghrib"] ?? "18:00";
    final p = maghrib.split(':');
    _fakeTime = DateTime(
      DateTime.now().year, DateTime.now().month, DateTime.now().day, 
      int.parse(p[0]), int.parse(p[1]) - 1, 55
    );
    status = AppStatus.home;
    notifyListeners();
  }

  void checkInitialStatus(Map<String, String> currentJadwal) {
    final now = DateTime.now();
    currentJadwal.forEach((name, time) {
      if (name == "Syuruq") return;

      final parts = time.split(':');
      final prayerTime = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
      
      int durasiIqomah = (name == "Jumat") ? 0 : PrayerService.getIqomahDuration(name);
      
      final endAdzanTime = prayerTime.add(Duration(seconds: AppConstants.adzanDuration));
      if (now.isAfter(prayerTime) && now.isBefore(endAdzanTime)) {
        status = AppStatus.adzan;
        currentPrayerName = name;
        adzanCounter = endAdzanTime.difference(now).inSeconds;
        return;
      }

      final durasiIsi = (name == "Jumat") ? AppConstants.jumatDuration : durasiIqomah;
      final endIqomahTime = endAdzanTime.add(Duration(seconds: durasiIsi));
      if (now.isAfter(endAdzanTime) && now.isBefore(endIqomahTime)) {
        if (name == "Jumat") {
          status = AppStatus.jumatMode;
          jumatCounter = endIqomahTime.difference(now).inSeconds;
        } else {
          status = AppStatus.iqomah;
          currentPrayerName = name;
          iqomahCounter = endIqomahTime.difference(now).inSeconds;
        }
      }
    });
  }

  void _checkSpecialLiveConditions(DateTime now) {
    final bool isNearMaghrib = _isMinutesBeforePrayer("Maghrib", AppConstants.minutesBeforeMaghrib, now);
    
    final bool isFriday = now.weekday == DateTime.friday;
    final bool isNearJumat = isFriday && _isMinutesBeforePrayer("Jumat", AppConstants.minutesBeforeJumat, now);

    isSpecialLiveMode = isNearMaghrib || isNearJumat;
  }

  bool _isMinutesBeforePrayer(String prayerName, int minutes, DateTime now) {
    String key = prayerName;
    if (prayerName == "Jumat" && !jadwal.containsKey("Jumat")) key = "Dzuhur";
    if (prayerName == "Dzuhur" && jadwal.containsKey("Jumat")) key = "Jumat";

    final String? timeString = jadwal[key];
    if (timeString == null || timeString == "--:--") return false;

    final parts = timeString.split(':');
    final prayerTime = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));

    final difference = prayerTime.difference(now).inSeconds;
    
    return difference >= 0 && difference <= (minutes * 60);
  }
}
