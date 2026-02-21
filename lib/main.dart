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
  static const int DURASI_HOME = !kDebugMode ? 60 : 10;
  static const int DURASI_EVENT = !kDebugMode ? 10 : 0;
  static const int DURASI_ADZAN = 180;
  static const int DURASI_IQOMAH_SUBUH = 900;
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

  // Sound Beep Player
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  Map<String, String> _jadwal = {"Subuh": "--:--", "Syuruq": "--:--", "Dzuhur": "--:--", "Ashar": "--:--", "Maghrib": "--:--", "Isya": "--:--"};
  final List<String> _eventImages = [
    'https://i.ibb.co.com/chKB1B9Z/bg1.jpg',
    'https://i.ibb.co.com/msXhZ9M/bg2.jpg',
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
    // 1. Ambil data lokal dulu biar cepat
    var local = await _prayerService.getTodayJadwalMap();
    if (local != null) setState(() => _jadwal = local);
    
    // 2. Update data 6 bulan di background
    await _prayerService.fetchAndSaveSixMonths();
    
    // 3. Refresh lagi setelah download selesai
    var fresh = await _prayerService.getTodayJadwalMap();
    if (fresh != null) setState(() => _jadwal = fresh);
  }

  void _playSound(String fileName) async {
    await _audioPlayer.play(AssetSource('sounds/$fileName'));
  }

  void _onTick() {
    final now = DateTime.now();
    setState(() {
      _timeString = DateFormat('HH:mm').format(now);

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
          if (name != "Syuruq" && _timeString == time.replaceAll(':', '.')) {
            _appStatus = "ADZAN";
            _currentPrayerName = name;
            _adzanCounter = DURASI_ADZAN;

            _playSound('beep_adzan.wav');
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
            _currentPrayerName = "Tes Adzan";
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
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label, 
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.bold,
                color: isNext ? Colors.white : const Color.fromARGB(150, 0, 0, 0), // Putih jika next, hitam jika tidak
              )
            ),
            Text(
              time, 
              style: TextStyle(
                fontSize: 48, 
                fontWeight: FontWeight.w900,
                color: isNext ? Colors.white : const Color.fromARGB(150, 0, 0, 0), // Putih jika next, hitam jika tidak
              )
            ),
            if (isNext)
              Text(
                label == "Syuruq" ? "Terbit: -$_countdownString" : "-$_countdownString",
                style: const TextStyle(
                  fontSize: 20,
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
