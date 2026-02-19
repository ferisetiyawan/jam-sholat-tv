import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

// Import buatan sendiri
import 'services/prayer_service.dart';
import 'screens/home_screen.dart';
import 'screens/adzan_screen.dart';
import 'screens/iqomah_screen.dart';

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
  static const int DURASI_HOME = 60;
  static const int DURASI_EVENT = 15;
  static const int DURASI_ADZAN = 180; // 3 Menit

  // STATE
  String _timeString = "";
  String _appStatus = "HOME"; // HOME, ADZAN, IQOMAH
  String _currentPrayerName = "";
  int _iqomahCounter = 0;
  int _adzanCounter = 0;
  bool _isEventMode = false;
  int _currentEventIndex = 0;
  
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

  void _onTick() {
    final now = DateTime.now();
    setState(() {
      _timeString = DateFormat('HH.mm').format(now);
      
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
          }
        });
      }

      // KONTROL ADZAN -> IQOMAH
      if (_appStatus == "ADZAN") {
        _adzanCounter--;
        if (_adzanCounter <= 0) {
          _appStatus = "IQOMAH";
          _iqomahCounter = (_currentPrayerName == "Subuh") ? 900 : 600;
        }
      }

      // KONTROL IQOMAH -> HOME
      if (_appStatus == "IQOMAH") {
        _iqomahCounter--;
        if (_iqomahCounter <= 0) _appStatus = "HOME";
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
    } else if (_isEventMode) {
      screen = _buildEventScreen();
    } else {
      screen = _buildHomeWrapper();
    }

    return Scaffold(
      body: AnimatedSwitcher(duration: const Duration(milliseconds: 800), child: screen),
    );
  }

  Widget _buildHomeWrapper() {
    return Stack(
      children: [
        Positioned.fill(child: Image.network('https://i.ibb.co.com/mPvfRZ7/Whats-App-Image-2026-02-19-at-4-29-11-PM.jpg', fit: BoxFit.cover)),
        Container(color: Colors.black.withOpacity(0.5)),
        HomeScreen(time: _timeString, jadwal: _jadwal, prayerItemBuilder: _buildPrayerItem),
      ],
    );
  }

  Widget _buildEventScreen() {
    return SizedBox.expand( // Memaksa konten mengisi seluruh layar
      child: Container(
        color: Colors.black,
        child: Image.network(
          _eventImages[_currentEventIndex],
          // BoxFit.cover akan membuat gambar memenuhi layar tanpa gepeng.
          // Bagian pinggir gambar akan sedikit terpotong jika rasio tidak pas 16:9
          fit: BoxFit.cover, 
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.center, // Memastikan pusat gambar tetap di tengah
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Text("Gagal Memuat Poster Event", style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerItem(String label, String time) {
    bool isActive = (_timeString == time.replaceAll(':', '.'));
    return Expanded(
      child: Container(
        decoration: BoxDecoration(color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(time, style: const TextStyle(fontSize: 50, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}
