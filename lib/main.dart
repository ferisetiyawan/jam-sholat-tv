import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:audioplayers/audioplayers.dart';

// screens
import 'services/prayer_service.dart';
import 'screens/adzan_screen.dart';
import 'screens/iqomah_screen.dart';
import 'screens/event_screen.dart';
import 'screens/jumat_screen.dart';

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
  // KONFIGURASI SIKLUS (Detik)
  static const int DURASI_HOME = !kDebugMode ? 60 : 5;
  static const int DURASI_EVENT = !kDebugMode ? 10 : 3;
  static const int DURASI_ADZAN = 180;
  static const int DURASI_IQOMAH_SUBUH = !kDebugMode ? 900 : 15;
  static const int DURASI_IQOMAH_DEFAULT = !kDebugMode ? 600 : 15;
  static const int DURASI_JUMAT = !kDebugMode ? 2700 : 10;

  // STATE
  String _timeString = "";
  String _appStatus = "HOME"; // HOME, ADZAN, IQOMAH
  String _currentPrayerName = "";
  int _jumatCounter = 0;
  int _iqomahCounter = 0;
  int _adzanCounter = 0;
  bool _isEventMode = false;
  int _currentEventIndex = 0;

  String _nextPrayerName = "";
  String _countdownString = "";

  String _dateMasehi = "";
  String _dateHijriah = "";

  // Sound Beep Player
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  Map<String, String> _jadwal = {"Subuh": "--:--", "Syuruq": "--:--", "Dzuhur": "--:--", "Ashar": "--:--", "Maghrib": "--:--", "Isya": "--:--"};
  final List<String> _eventImages = [
    'https://i.ibb.co.com/v4XVCXxm/kajian1.jpg',
    'https://i.ibb.co.com/fdjQytfY/kajian2.jpg',
    'https://i.ibb.co.com/qY3QbqHQ/kajian3.jpg'
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
      if (_appStatus == "HOME") _checkInitialStatus(fresh); 
    }
  }

  void _checkInitialStatus(Map<String, String> jadwal) {
    final now = DateTime.now();
    
    jadwal.forEach((name, time) {
      if (name == "Syuruq") return; // Syuruq tidak punya siklus adzan/iqomah

      final parts = time.split(':');
      final prayerTime = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
      
      int durasiIqomah = (name == "Subuh") ? DURASI_IQOMAH_SUBUH : DURASI_IQOMAH_DEFAULT;
      if (name == "Jumat") durasiIqomah = 0; // Jumat langsung ke mode JUMAT_MODE setelah adzan

      // 1. CEK RENTANG ADZAN
      final endAdzanTime = prayerTime.add(Duration(seconds: DURASI_ADZAN));
      if (now.isAfter(prayerTime) && now.isBefore(endAdzanTime)) {
        int remainingAdzan = endAdzanTime.difference(now).inSeconds;
        setState(() {
          _appStatus = "ADZAN";
          _currentPrayerName = name;
          _adzanCounter = remainingAdzan;
        });
        return;
      }

      // 2. CEK RENTANG IQOMAH / JUMAT MODE
      final endIqomahTime = endAdzanTime.add(Duration(seconds: (name == "Jumat") ? DURASI_JUMAT : durasiIqomah));
      if (now.isAfter(endAdzanTime) && now.isBefore(endIqomahTime)) {
        int remainingContent = endIqomahTime.difference(now).inSeconds;
        setState(() {
          if (name == "Jumat") {
            _appStatus = "JUMAT_MODE";
            _jumatCounter = remainingContent;
          } else {
            _appStatus = "IQOMAH";
            _currentPrayerName = name;
            _iqomahCounter = remainingContent;
          }
        });
        return;
      }
    });
  }

  void _playSound(String fileName) async {
    await _audioPlayer.play(AssetSource('sounds/$fileName'));
  }

  void _onTick() {
    final now = DateTime.now();
    setState(() {
      _timeString = DateFormat('HH:mm').format(now);

      final dates = PrayerService.getFullDate();
      _dateMasehi = dates['masehi']!;
      _dateHijriah = dates['hijriah']!;

      final result = PrayerService.calculateCountdown(_jadwal);
      _nextPrayerName = result["nextName"]!;
      _countdownString = result["countdown"]!;
      
      // KONTROL SIKLUS HOME/EVENT (hanya jika sedang status HOME)
      if (_appStatus == "HOME") {
        int totalCycle = DURASI_HOME + DURASI_EVENT;
        int currentSec = _timer!.tick % totalCycle;
        if (currentSec < DURASI_HOME) {
          _isEventMode = false;
        } else {
          if (!_isEventMode) _currentEventIndex = (_currentEventIndex + 1) % _eventImages.length;
          _isEventMode = true;
        }

        // CEK WAKTU ADZAN
        _jadwal.forEach((name, time) {
          if (name != "Syuruq" && _timeString == time.replaceAll(':', '.') && now.second == 0) {
            if (_appStatus == "HOME") { // Pastikan tidak memutus status yang sudah ada
              _appStatus = "ADZAN";
              _currentPrayerName = name;
              _adzanCounter = DURASI_ADZAN;
              _playSound('beep_adzan.wav');
            }
          }
        });
      }

      // KONTROL ADZAN -> IQOMAH
      if (_appStatus == "ADZAN") {
        _adzanCounter--;
        if (_adzanCounter <= 0) {
          if (_currentPrayerName == "Jumat") {
            _appStatus = "JUMAT_MODE";
            _jumatCounter = DURASI_JUMAT;
          } else {
            _appStatus = "IQOMAH";
            _iqomahCounter = (_currentPrayerName == "Subuh") ? DURASI_IQOMAH_SUBUH : DURASI_IQOMAH_DEFAULT;
          }
        }
      }

      // KONTROL IQOMAH -> HOME
      if (_appStatus == "IQOMAH") {
        _iqomahCounter--;

        if (_iqomahCounter <= 10 && _iqomahCounter > 0) {
          _playSound('beep_iqomah.wav');
        }

        if (_iqomahCounter <= 0) {
          _appStatus = "HOME";

          _playSound('beep_adzan.wav');
        }
      }

      if (_appStatus == "JUMAT_MODE") {
        _jumatCounter--;
        if (_jumatCounter <= 0) {
          _appStatus = "HOME";
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget screen;
    if (_appStatus == "ADZAN") {
      screen = AdzanScreen(namaSholat: _currentPrayerName);
    } else if (_appStatus == "IQOMAH") {
      screen = IqomahScreen(namaSholat: _currentPrayerName, countdown: _iqomahCounter);
    } else if (_appStatus == "JUMAT_MODE") {
      screen = const JumatScreen();
    } else if (_isEventMode) {
      screen = EventScreen(key: const ValueKey("event_screen_fixed"), images: _eventImages, currentIndex: _currentEventIndex, currentTime: _timeString);
    } else {
      screen = HomeWrapper(
        time: _timeString,
        dateMasehi: _dateMasehi, // Ambil dari variabel state di main.dart
        dateHijriah: _dateHijriah,
        jadwal: _jadwal,
        prayerItemBuilder: _buildPrayerItem,
      );
    }

    return Scaffold(
      body: AnimatedSwitcher(duration: const Duration(milliseconds: 800), child: screen),
      
      floatingActionButton: kDebugMode ? FloatingActionButton(
        backgroundColor: Colors.red.withValues(alpha: 0.5),
        onPressed: () {
          setState(() {
            _appStatus = "ADZAN";
            _currentPrayerName = "Subuh";
            _adzanCounter = 5;
            
            _playSound('beep_adzan.wav');
          });
        },
        child: const Icon(Icons.bug_report),
      ) : null,
    );
  }

  Widget _buildPrayerItem(String label, String time) {
    bool isNext = (label == _nextPrayerName);

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          color: isNext ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label, 
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: isNext ? Colors.white : const Color.fromARGB(150, 0, 0, 0), // Putih jika next, hitam jika tidak
              )
            ),
            Text(
              time, 
              style: TextStyle(
                fontSize: 40, 
                fontWeight: FontWeight.w900,
                color: isNext ? Colors.white : const Color.fromARGB(150, 0, 0, 0), // Putih jika next, hitam jika tidak
              )
            ),
            if (isNext)
              Text(
                "-$_countdownString",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
