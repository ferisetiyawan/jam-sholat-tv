import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../services/local_server_service.dart';

/// Full-screen menu shown when the TV remote's OK is held (or Menu pressed).
///
/// Displays the config-server URL as a QR code (with the auth token baked in)
/// plus the plain-text URL, so anyone on the same Wi-Fi can open the editor on
/// their phone/laptop. The remote's long-press OK / Menu closes it again.
class ConfigMenuScreen extends StatefulWidget {
  const ConfigMenuScreen({super.key});

  @override
  State<ConfigMenuScreen> createState() => _ConfigMenuScreenState();
}

class _ConfigMenuScreenState extends State<ConfigMenuScreen> {
  String? _authenticatedUrl;
  String? _localUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _resolveUrls();
  }

  Future<void> _resolveUrls() async {
    setState(() => _loading = true);
    final LocalServerService? server = LocalServerService.instance;
    final String? authenticated = await server?.authenticatedUrl;
    final String? local = await server?.localUrl;
    if (!mounted) return;
    setState(() {
      _authenticatedUrl = authenticated;
      _localUrl = local;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Row(
            children: [
              _buildQrCard(),
              const SizedBox(width: 36),
              Expanded(child: _buildInfoColumn()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: _authenticatedUrl == null
          ? SizedBox(
              width: 260,
              height: 260,
              child: Center(
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Tidak ada alamat'),
              ),
            )
          : QrImageView(
              data: _authenticatedUrl!,
              version: QrVersions.auto,
              size: 260,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
    );
  }

  Widget _buildInfoColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "PENGATURAN TV",
          style: TextStyle(
            color: Colors.amber,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Scan QR atau buka URL di HP / laptop yang terhubung ke Wi-Fi yang sama:",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 12),
        SelectableText(
          _authenticatedUrl ?? ( _loading ? 'Mencari alamat…' : '—'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (_localUrl != null && _localUrl != _authenticatedUrl) ...[
          const SizedBox(height: 4),
          SelectableText(
            _localUrl!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
        ],
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: _loading ? null : _resolveUrls,
          icon: const Icon(Icons.refresh),
          label: const Text("Muat ulang alamat"),
        ),
        const Spacer(),
        Text(
          "Tutup: tekan lama tombol OK / tekan tombol Menu pada remote.",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
