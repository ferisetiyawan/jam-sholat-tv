import 'dart:io';

import 'package:network_info_plus/network_info_plus.dart';

/// Small helper that resolves the device's local IPv4 address so the config
/// server can advertise a reachable URL on the same Wi-Fi.
///
/// Uses [NetworkInfo.getWifiIP] first (the Android Wi-Fi interface), falling
/// back to enumerating the machine's interfaces for any non-loopback IPv4
/// (covers emulators / other platforms where the Wi-Fi lookup returns null).
class NetworkInfoHelper {
  const NetworkInfoHelper();

  /// Returns the local IPv4 as a plain string (e.g. `192.168.1.5`), or `null`
  /// if none could be determined.
  Future<String?> localIPv4() async {
    try {
      final String? wifiIp = await NetworkInfo().getWifiIP();
      if (wifiIp != null && wifiIp.isNotEmpty) return wifiIp;
    } catch (_) {
      // Fall through to the interface scan below.
    }

    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
    } catch (_) {
      // No address found.
    }

    return null;
  }
}
