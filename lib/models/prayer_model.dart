class PrayerSchedule {
  final String tanggal;
  final String subuh;
  final String syuruq;
  final String dzuhur;
  final String ashar;
  final String maghrib;
  final String isya;

  PrayerSchedule({
    required this.tanggal,
    required this.subuh,
    required this.syuruq,
    required this.dzuhur,
    required this.ashar,
    required this.maghrib,
    required this.isya,
  });

  factory PrayerSchedule.fromJson(Map<String, dynamic> json) {
    return PrayerSchedule(
      tanggal: json['tanggal'] ?? "",
      subuh: json['subuh'] ?? "--:--",
      syuruq: json['terbit'] ?? "--:--", // MyQuran pakai 'terbit' untuk syuruq
      dzuhur: json['dzuhur'] ?? "--:--",
      ashar: json['ashar'] ?? "--:--",
      maghrib: json['maghrib'] ?? "--:--",
      isya: json['isya'] ?? "--:--",
    );
  }
}
