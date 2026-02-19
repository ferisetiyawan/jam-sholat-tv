import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import Screens dari folder screens
import 'screens/home_screen.dart';
import 'screens/adzan_screen.dart';
import 'screens/iqomah_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Paksa Landscape untuk TV
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Mode Full Screen
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
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Roboto', 
      ),
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
  // --- KONFIGURASI DURASI (GANTI DI SINI) ---
  static const int HOME_DURATION = 10;  // Detik tampil jadwal
  static const int EVENT_DURATION = 15; // Detik tampil event/iklan
  static const int ADZAN_DURATION = 180; // Detik tampil layar adzan (3 menit)
  
  final List<String> _eventImages = [
    'https://via.placeholder.com/1920x1080.png?text=Event+Kajian+1',
    'https://via.placeholder.com/1920x1080.png?text=Event+Kajian+2',
  ];

  // --- STATE VARIABEL ---
  String _timeString = "";
  String _appStatus = "HOME"; // HOME, ADZAN, IQOMAH
  String _currentPrayerName = "";
  int _iqomahCounter = 0;
  int _adzanCounter = 0;
  
  bool _isEventMode = false;
  int _currentEventIndex = 0;
  
  Timer? _mainTimer;
  Timer? _cycleTimer;
  
  Map<String, String> _jadwal = {
    "Subuh": "--:--", "Syuruq": "--:--", "Dzuhur": "--:--",
    "Ashar": "--:--", "Maghrib": "--:--", "Isya": "--:--",
  };

  @override
  void initState() {
    super.initState();
    // Timer Utama (Setiap detik)
    _mainTimer = Timer.periodic(const Duration(seconds: 1), (t) => _onTick());
    _startDisplayCycle();
    _loadJadwal();
  }

  @override
  void dispose() {
    _mainTimer?.cancel();
    _cycleTimer?.cancel();
    super.dispose();
  }

  // --- LOGIKA SETIAP DETIK ---
  void _onTick() {
    final now = DateTime.now();
    setState(() {
      _timeString = DateFormat('HH.mm').format(now);
      
      // 1. Cek Waktu Adzan
      if (_appStatus == "HOME") {
        _jadwal.forEach((name, time) {
          if (name != "Syuruq" && _timeString == time.replaceAll(':', '.')) {
            _appStatus = "ADZAN";
            _currentPrayerName = name;
            _adzanCounter = ADZAN_DURATION;
          }
        });
      }

      // 2. Logika Countdown Adzan -> Ke Iqomah
      if (_appStatus == "ADZAN") {
        _adzanCounter--;
        if (_adzanCounter <= 0) {
          _appStatus = "IQOMAH";
          _iqomahCounter = (_currentPrayerName == "Subuh") ? 900 : 600; // 15m atau 10m
        }
      }

      // 3. Logika Countdown Iqomah -> Kembali ke Home
      if (_appStatus == "IQOMAH") {
        _iqomahCounter--;
        if (_iqomahCounter <= 0) {
          _appStatus = "HOME";
        }
      }
    });
  }

  // --- LOGIKA SIKLUS EVENT ---
  void _startDisplayCycle() {
    _cycleTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_appStatus != "HOME") return; // Jangan ganti layar kalau adzan/iqomah

      int totalCycle = HOME_DURATION + EVENT_DURATION;
      int sec = timer.tick % totalCycle;

      setState(() {
        if (sec < HOME_DURATION) {
          _isEventMode = false;
        } else {
          if (!_isEventMode) {
            _currentEventIndex = (_currentEventIndex + 1) % _eventImages.length;
          }
          _isEventMode = true;
        }
      });
    });
  }

  // --- DATA FETCHING ---
  Future<void> _loadJadwal() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('jadwal_sholat')) {
      _updateJadwalUI(json.decode(prefs.getString('jadwal_sholat')!));
    }
    _fetchAPI();
  }

  Future<void> _fetchAPI() async {
    try {
      final res = await Dio().get("https://api.myquran.com/v2/sholat/jadwal/1203/${DateTime.now().year}/${DateTime.now().month}");
      if (res.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jadwal_sholat', json.encode(res.data['data']['jadwal']));
        _updateJadwalUI(res.data['data']['jadwal']);
      }
    } catch (e) { debugPrint("Offline"); }
  }

  void _updateJadwalUI(dynamic data) {
    setState(() {
      _jadwal["Subuh"] = data['subuh']; _jadwal["Syuruq"] = data['terbit'];
      _jadwal["Dzuhur"] = data['dzuhur']; _jadwal["Ashar"] = data['ashar'];
      _jadwal["Maghrib"] = data['maghrib']; _jadwal["Isya"] = data['isya'];
    });
  }

  // --- BUILDER ---
  @override
  Widget build(BuildContext context) {
    Widget currentWidget;

    // Hirarki Tampilan: Adzan > Iqomah > Event > Home
    if (_appStatus == "ADZAN") {
      currentWidget = AdzanScreen(namaSholat: _currentPrayerName);
    } else if (_appStatus == "IQOMAH") {
      currentWidget = IqomahScreen(namaSholat: _currentPrayerName, countdown: _iqomahCounter);
    } else if (_isEventMode) {
      currentWidget = _buildEventScreen();
    } else {
      currentWidget = _buildHomeScreenWrapper();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 800),
        child: currentWidget,
      ),
    );
  }

  Widget _buildHomeScreenWrapper() {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.network(
            'https://i.ibb.co.com/mPvfRZ7/Whats-App-Image-2026-02-19-at-4-29-11-PM.jpg', 
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Image.asset('assets/background_masjid.jpg', fit: BoxFit.cover),
          ),
        ),
        Container(color: Colors.black.withOpacity(0.5)),
        HomeScreen(
          time: _timeString, 
          jadwal: _jadwal,
          prayerItemBuilder: (label, time) => _prayerItemClean(label, time),
        ),
      ],
    );
  }

  Widget _buildEventScreen() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Image.network(
        _eventImages[_currentEventIndex],
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Center(child: Text("Info Kegiatan Masjid")),
      ),
    );
  }

  Widget _prayerItemClean(String label, String time) {
    bool isActive = (_timeString == time.replaceAll(':', '.'));
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
          border: Border(right: BorderSide(color: Colors.white.withOpacity(0.1))),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label.toUpperCase(), 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isActive ? Colors.white : Colors.white70)),
            Text(time, style: const TextStyle(fontSize: 50, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}
