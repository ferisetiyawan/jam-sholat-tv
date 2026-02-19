import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:marquee/marquee.dart';
import '../services/prayer_service.dart';
import '../models/prayer_model.dart';
import 'adzan_screen.dart';
import 'iqomah_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PrayerSchedule? todaySchedule;
  String currentTime = "";
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Update jam setiap detik
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        currentTime = DateFormat('HH.mm').format(DateTime.now());
      });
      _checkPrayerTime();
    });
  }

  void _loadData() async {
    await PrayerService().fetchAndSaveSixMonths();
    var schedule = await PrayerService().getTodaySchedule();
    setState(() {
      todaySchedule = schedule;
    });
  }

  void _checkPrayerTime() {
    if (todaySchedule == null) return;
    String now = DateFormat('HH:mm').format(DateTime.now());

    // Daftar waktu sholat untuk dicek
    Map<String, String> times = {
      "Subuh": todaySchedule!.subuh,
      "Dzuhur": todaySchedule!.dzuhur,
      "Ashar": todaySchedule!.ashar,
      "Maghrib": todaySchedule!.maghrib,
      "Isya": todaySchedule!.isya,
    };

    times.forEach((name, time) {
      if (now == time) {
        _goToAdzan(name);
      }
    });
  }

  void _goToAdzan(String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdzanScreen(
          namaSholat: name,
          onFinished: () => _goToIqomah(name),
        ),
      ),
    );
  }

  void _goToIqomah(String name) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => IqomahScreen(
          namaSholat: name,
          onFinished: () => Navigator.pop(context),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background (Ganti dengan Image.asset nanti)
          Container(color: Colors.blueGrey),
          
          // Jam Pojok Kiri Atas
          Positioned(
            top: 40, left: 40,
            child: Text(currentTime, style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.white)),
          ),

          // Nama Masjid
          const Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: 40),
              child: Column(
                children: [
                  Text("MASJID AL HIJRAH", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text("CIMANGGIS GOLF ESTATE", style: TextStyle(fontSize: 18, color: Colors.white70)),
                ],
              ),
            ),
          ),

          // Running Text di Bawah
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 50,
              color: Colors.black.withOpacity(0.5),
              child: Marquee(
                text: 'Selamat Datang di Masjid Al Hijrah - Jagalah Kebersihan dan Matikan Handphone saat Sholat - ',
                style: const TextStyle(color: Colors.white, fontSize: 20),
                scrollAxis: Axis.horizontal,
                blankSpace: 20.0,
                velocity: 50.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
