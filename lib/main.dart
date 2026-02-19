import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:marquee/marquee.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      home: const JadwalSholatScreen(),
    );
  }
}

class JadwalSholatScreen extends StatefulWidget {
  const JadwalSholatScreen({super.key});

  @override
  State<JadwalSholatScreen> createState() => _JadwalSholatScreenState();
}

class _JadwalSholatScreenState extends State<JadwalSholatScreen> {
  String _timeString = "";
  String _dateString = "";
  bool _isIqomahMode = false;
  int _iqomahCountdown = 600; 
  Timer? _timer;
  
  // Data Jadwal Sholat (Default)
  Map<String, String> _jadwal = {
    "Subuh": "--:--",
    "Syuruq": "--:--",
    "Dzuhur": "--:--",
    "Ashar": "--:--",
    "Maghrib": "--:--",
    "Isya": "--:--",
  };

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateTime());
    _updateTime();
    _loadJadwal(); // Ambil data dari API/Lokal
  }

  // --- LOGIKA AMBIL DATA API (6 BULAN OFFLINE) ---
  Future<void> _loadJadwal() async {
    final prefs = await SharedPreferences.getInstance();
    String? localData = prefs.getString('jadwal_sholat');

    if (localData != null) {
      var data = json.decode(localData);
      _updateJadwalUI(data);
    }
    
    _fetchAPI(); // Tetap fetch di background untuk update terbaru
  }

  Future<void> _fetchAPI() async {
    try {
      // ID 1203 adalah Cimanggis/Kota Depok di API MyQuran
      final response = await Dio().get("https://api.myquran.com/v2/sholat/jadwal/1203/${DateTime.now().year}/${DateTime.now().month}");
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jadwal_sholat', json.encode(response.data['data']['jadwal']));
        setState(() {
          _updateJadwalUI(response.data['data']['jadwal']);
        });
      }
    } catch (e) {
      print("Gagal ambil API, menggunakan data lokal");
    }
  }

  void _updateJadwalUI(dynamic jadwalHariIni) {
    // API biasanya mengembalikan array bulanan, kita ambil hari ini
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    // Logika filter hari ini disederhanakan:
    setState(() {
      _jadwal["Subuh"] = jadwalHariIni['subuh'] ?? "--:--";
      _jadwal["Syuruq"] = jadwalHariIni['terbit'] ?? "--:--";
      _jadwal["Dzuhur"] = jadwalHariIni['dzuhur'] ?? "--:--";
      _jadwal["Ashar"] = jadwalHariIni['ashar'] ?? "--:--";
      _jadwal["Maghrib"] = jadwalHariIni['maghrib'] ?? "--:--";
      _jadwal["Isya"] = jadwalHariIni['isya'] ?? "--:--";
    });
  }

  void _updateTime() {
    final DateTime now = DateTime.now();
    setState(() {
      _timeString = DateFormat('HH.mm').format(now);
      _dateString = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);
      
      // Cek apakah waktu sekarang sama dengan salah satu jadwal sholat
      _jadwal.forEach((key, value) {
        if (key != "Syuruq" && _timeString == value.replaceAll(':', '.') && !_isIqomahMode) {
          _startIqomah(key);
        }
      });
    });
  }

  void _startIqomah(String sholat) {
    int menit = (sholat == "Subuh") ? 15 : 10;
    setState(() {
      _isIqomahMode = true;
      _iqomahCountdown = menit * 60;
    });
    // Tambahkan timer countdown iqomah di sini...
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Di dalam Widget build, bagian Stack:
          Positioned.fill(
            child: Image.network(
              'https://i.ibb.co.com/mPvfRZ7/Whats-App-Image-2026-02-19-at-4-29-11-PM.jpg', 
              fit: BoxFit.cover,
              // INI KUNCINYA: Jika internet gagal, gunakan assets
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  'assets/background_masjid.jpg', // Sesuaikan dengan nama file Anda
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
          Container(color: Colors.black.withOpacity(0.5)),
          SafeArea(
            child: _isIqomahMode ? _buildIqomahScreen() : _buildMainScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainScreen() {
    return Column(
      children: [
        // HEADER
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 25),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_timeString, style: const TextStyle(fontSize: 110, fontWeight: FontWeight.w900, letterSpacing: -5)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text("MASJID AL HIJRAH", style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold)),
                  Text("Cimanggis Golf Estate", style: TextStyle(fontSize: 18, color: Colors.white70)),
                ],
              ),
            ],
          ),
        ),

        // Gunakan Spacer untuk mendorong konten ke bawah
        const Spacer(),

        // GRID JADWAL - Dikunci tingginya agar tidak overflow
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                // Kunci tinggi di sini (misal 160) agar tidak kena garis kuning
                height: 165, 
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  children: _jadwal.entries.map((e) => _prayerItemClean(e.key, e.value)).toList(),
                ),
              ),
            ),
          ),
        ),

        // RUNNING TEXT
        Container(
          height: 32,
          width: double.infinity, 
          color: Colors.black.withOpacity(0.8),
          child: Marquee(
            text: 'Selamat Datang di Masjid Al Hijrah CGE - Jagalah Kebersihan dan Matikan Handphone saat Sholat - ',
            style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
            velocity: 45.0,
            blankSpace: 0,
          ),
        ),
      ],
    );
  }

  Widget _prayerItemClean(String label, String time) {
    bool isActive = (_timeString == time.replaceAll(':', '.'));

    return Expanded(
      child: Container(
        // Padding vertikal dikurangi sedikit agar muat dalam height 165
        padding: const EdgeInsets.symmetric(vertical: 15), 
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.25) : Colors.transparent,
          border: Border(
            right: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Pusatkan konten di tengah kotak
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 20, // Sedikit disesuaikan
                color: isActive ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  time,
                  style: const TextStyle(
                    fontSize: 55, // Tetap besar
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(top: 5),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIqomahScreen() {
    return Stack(
      children: [
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "MENUJU IQOMAH",
                      style: TextStyle(fontSize: 40, fontWeight: FontWeight.w300, letterSpacing: 8),
                    ),
                    const SizedBox(height: 20),
                    // Counter Besar
                    Text(
                      "${(_iqomahCountdown ~/ 60).toString().padLeft(2, '0')}:${(_iqomahCountdown % 60).toString().padLeft(2, '0')}",
                      style: const TextStyle(
                        fontSize: 220, 
                        fontWeight: FontWeight.w900, 
                        color: Colors.greenAccent, // Warna hijau iqomah
                        fontFeatures: [FontFeature.tabularFigures()] // Biar angka tidak goyang saat berubah
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "LURUSKAN DAN RAPATKAN SHAF",
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                    const SizedBox(height: 40),
                    // Tombol Batal (Hanya untuk testing/admin)
                    TextButton(
                      onPressed: () => setState(() => _isIqomahMode = false),
                      child: Text("BATAL", style: TextStyle(color: Colors.white.withOpacity(0.3))),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
