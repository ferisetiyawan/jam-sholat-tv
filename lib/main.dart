import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

// constants & enums
import 'core/constants/app_constants.dart';
import 'core/constants/app_enum.dart';

// utils
import 'core/utils/date_formatter.dart';

// widgets
import 'widgets/prayer_card.dart';

// services
import 'services/prayer_service.dart';
import 'services/audio_service.dart';

// screens
import 'screens/adzan_screen.dart';
import 'screens/iqomah_screen.dart';
import 'screens/event_screen.dart';
import 'screens/jumat_screen.dart';
import 'screens/live_makkah_screen.dart';

// wrappers
import 'wrappers/home_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await initializeDateFormatting('id_ID', null); 
  WakelockPlus.enable(); 
  runApp(const MasjidApp());
}

class MasjidApp extends StatelessWidget {
  const MasjidApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, fontFamily: 'Roboto'),
      home: const MainController(),
    );
  }
}

class MainController extends StatefulWidget {
  const MainController({super.key});
  @override
  State<MainController> createState() => _MainControllerState();
}

class _MainControllerState extends State<MainController> {
  // STATE
  String _timeString = "";
  
  AppStatus _appStatus = AppStatus.home;

  String _currentPrayerName = "";
  int _jumatCounter = 0;
  int _iqomahCounter = 0;
  int _adzanCounter = 0;
  bool _isEventMode = false;
  int _currentEventIndex = 0;

  // Fake Time for Testing
  DateTime? _fakeTime;

  String _nextPrayerName = "";
  String _countdownString = "";

  String _dateMasehi = "";
  String _dateHijriah = "";
  
  Map<String, String> _jadwal = {"Subuh": "--:--", "Syuruq": "--:--", "Dzuhur": "--:--", "Ashar": "--:--", "Maghrib": "--:--", "Isya": "--:--"};
  
  final List<String> _eventImages = [
    'assets/images/kajian1.svg',
    'assets/images/kajian2.svg',
    'assets/images/kajian3.svg',
  ];

  final PrayerService _prayerService = PrayerService();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) => _onTick());
    _initData();
  }

  // Ambil data saat aplikasi pertama buka
  Future<void> _initData() async {
    var local = await _prayerService.getTodayJadwalMap();
    if (local != null) {
      setState(() => _jadwal = local);
      // Cek apakah saat ini sedang dalam rentang waktu Adzan atau Iqomah
      _checkInitialStatus(local); 
    }
    
    await _prayerService.fetchAndSaveSixMonths();
    
    var fresh = await _prayerService.getTodayJadwalMap();
    if (fresh != null) {
      setState(() => _jadwal = fresh);
      // Cek ulang jika ada perubahan jadwal dari API
      if (_appStatus == AppStatus.home) _checkInitialStatus(fresh); 
    }
  }

  void _checkInitialStatus(Map<String, String> jadwal) {
    final now = DateTime.now();
    
    jadwal.forEach((name, time) {
      if (name == "Syuruq") return; // Syuruq tidak punya siklus adzan/iqomah

      final parts = time.split(':');
      final prayerTime = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
      
      int durasiIqomah = PrayerService.getIqomahDuration(name);
      
      if (name == "Jumat") durasiIqomah = 0; // Jumat langsung ke mode JUMAT_MODE setelah adzan

      // 1. CEK RENTANG ADZAN
      final endAdzanTime = prayerTime.add(Duration(seconds: AppConstants.adzanDuration));
      if (now.isAfter(prayerTime) && now.isBefore(endAdzanTime)) {
        int remainingAdzan = endAdzanTime.difference(now).inSeconds;
        setState(() {
          _appStatus = AppStatus.adzan;
          _currentPrayerName = name;
          _adzanCounter = remainingAdzan;
        });
        return;
      }

      // 2. CEK RENTANG IQOMAH / JUMAT MODE
      final endIqomahTime = endAdzanTime.add(Duration(seconds: (name == "Jumat") ? AppConstants.jumatDuration : durasiIqomah));
      if (now.isAfter(endAdzanTime) && now.isBefore(endIqomahTime)) {
        int remainingContent = endIqomahTime.difference(now).inSeconds;
        setState(() {
          if (name == "Jumat") {
            _appStatus = AppStatus.jumatMode;
            _jumatCounter = remainingContent;
          } else {
            _appStatus = AppStatus.iqomah;
            _currentPrayerName = name;
            _iqomahCounter = remainingContent;
          }
        });
        return;
      }
    });
  }

  void _onTick() {
    // Jika _fakeTime ada, gunakan itu dan tambahkan 1 detik setiap tick
    if (_fakeTime != null) {
      _fakeTime = _fakeTime!.add(const Duration(seconds: 1));
    }
    final now = _fakeTime ?? DateTime.now();

    setState(() {
      _updateDateTime(now);
      _handleCycleLogic(now);
      _handlePrayerStatusLogic();
    });
  }

  void _updateDateTime(DateTime now) {
    _timeString = DateFormat('HH:mm').format(now);
    
    final dates = DateFormatter.getFullDate();
    _dateMasehi = dates['masehi']!;
    _dateHijriah = dates['hijriah']!;
    
    final result = PrayerService.calculateCountdown(_jadwal);
    _nextPrayerName = result["nextName"]!;
    _countdownString = result["countdown"]!;
  }

  void _handleCycleLogic(DateTime now) {
    if (_appStatus != AppStatus.home) return;

    int totalCycle = AppConstants.homeDuration + AppConstants.eventDuration;
    int currentSec = _timer!.tick % totalCycle;
    if (currentSec < AppConstants.homeDuration) {
      _isEventMode = false;
    } else {
      if (!_isEventMode) _currentEventIndex = (_currentEventIndex + 1) % _eventImages.length;
      _isEventMode = true;
    }

    // CEK WAKTU ADZAN
    _jadwal.forEach((name, time) {
      // Pastikan format string sama persis (contoh: "18:15" == "18:15")
      if (name != "Syuruq" && _timeString == time && now.second == 0) {
        if (_appStatus == AppStatus.home) {
          _appStatus = AppStatus.adzan;
          _currentPrayerName = name;
          _adzanCounter = (_fakeTime == null) ? AppConstants.adzanDuration : 5;
          AudioService.playAdzanBeep();
        }
      }
    });
  }

  void _handlePrayerStatusLogic(){
    if (_appStatus == AppStatus.adzan) {
      _adzanCounter--;
      if (_adzanCounter <= 0) {
        if (_currentPrayerName == "Jumat") {
          _appStatus = AppStatus.jumatMode;
          _jumatCounter = AppConstants.jumatDuration;
        } else {
          _appStatus = AppStatus.iqomah;

          _iqomahCounter = !kDebugMode ? PrayerService.getIqomahDuration(_currentPrayerName) : 15;
        }
      }
    }

    if (_appStatus == AppStatus.iqomah) {
      _iqomahCounter--;

      if (_iqomahCounter <= 10 && _iqomahCounter > 0) {
        AudioService.playIqomahBeep();
      }

      if (_iqomahCounter <= 0) {
        _appStatus = AppStatus.home;

        AudioService.playAdzanBeep();
      }
    }

    if (_appStatus == AppStatus.jumatMode) {
      _jumatCounter--;
      if (_jumatCounter <= 0) {
        _appStatus = AppStatus.home;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget screen = switch (_appStatus) {
      AppStatus.adzan => AdzanScreen(namaSholat: _currentPrayerName),
      AppStatus.iqomah => IqomahScreen(namaSholat: _currentPrayerName, countdown: _iqomahCounter),
      AppStatus.jumatMode => const JumatScreen(),
      AppStatus.home when _isEventMode => EventScreen(
        key: const ValueKey("event_screen_fixed"),
        images: _eventImages,
        currentIndex: _currentEventIndex,
        currentTime: _timeString
        ),
      _ => HomeWrapper(
          time: _timeString,
          dateMasehi: _dateMasehi,
          dateHijriah: _dateHijriah,
          jadwal: _jadwal,
          prayerItemBuilder: _buildPrayerItem,
        ),
    };

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 800),
        child: screen,
      ),
      floatingActionButton: _buildDebugFab(),
    );
  }

  Widget? _buildDebugFab() {
    if (!kDebugMode) return null;
  
    return FloatingActionButton(
      backgroundColor: Colors.red.withValues(alpha: 0.5),
      onPressed: () {
        final maghrib = _jadwal["Maghrib"] ?? "18:00";
        final p = maghrib.split(':');
        setState(() {
          _fakeTime = DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day, 
            int.parse(p[0]), int.parse(p[1]) - 1, 55
          );
          _appStatus = AppStatus.home;
        });
      },
      child: const Icon(Icons.fast_forward),
    );
  }

  Widget _buildPrayerItem(String label, String time) {
    return PrayerCard(
      label: label,
      time: time,
      isNext: (label == _nextPrayerName),
      countdown: _countdownString,
    );
  }
}
