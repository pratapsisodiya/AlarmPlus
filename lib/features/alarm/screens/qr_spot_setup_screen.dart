import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Shown when user wants to register a specific QR/barcode as their "dismiss spot".
/// Returns the scanned QR value as a String via Navigator.pop().
class QrSpotSetupScreen extends StatefulWidget {
  const QrSpotSetupScreen({super.key});
  static const routeName = '/qr-spot-setup';

  @override
  State<QrSpotSetupScreen> createState() => _QrSpotSetupScreenState();
}

class _QrSpotSetupScreenState extends State<QrSpotSetupScreen> {
  String? _scannedCode;
  bool _confirmed = false;

  void _onDetect(BarcodeCapture capture) {
    if (_confirmed) return;
    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final value = barcodes.first.rawValue!;
      setState(() => _scannedCode = value);
    }
  }

  void _confirm() {
    if (_scannedCode == null) return;
    setState(() => _confirmed = true);
    Navigator.of(context).pop(_scannedCode);
  }

  void _rescan() {
    setState(() {
      _scannedCode = null;
      _confirmed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Set Dismiss Spot',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Text(
                _scannedCode == null
                    ? 'Stick a QR sticker on your bathroom mirror, coffee maker, or any spot you want to walk to. Then scan it here.'
                    : 'Code registered! This QR will be required to dismiss your alarm.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
              ),
            ),
            Expanded(
              child: _scannedCode != null
                  ? _buildConfirmView()
                  : _buildScannerView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: MobileScanner(onDetect: _onDetect),
      ),
    );
  }

  Widget _buildConfirmView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.qr_code_scanner_rounded,
              color: Color(0xFF10B981), size: 48),
        ),
        const SizedBox(height: 24),
        const Text('Spot Registered!',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _scannedCode!.length > 40
                ? '${_scannedCode!.substring(0, 40)}...'
                : _scannedCode!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ElevatedButton(
            onPressed: _confirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
            ),
            child: const Text('Use This Spot',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _rescan,
          child: const Text('Scan a Different Code',
              style: TextStyle(color: Colors.white54)),
        ),
      ],
    );
  }
}
