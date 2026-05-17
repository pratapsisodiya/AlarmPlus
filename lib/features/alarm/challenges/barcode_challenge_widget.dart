import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeChallengeWidget extends StatefulWidget {
  const BarcodeChallengeWidget({
    super.key,
    required this.onPassed,
    this.lockedQrCode,
  });

  final VoidCallback onPassed;
  /// When set, only the matching QR/barcode value dismisses the alarm (scan-a-spot mode).
  final String? lockedQrCode;

  @override
  State<BarcodeChallengeWidget> createState() => _BarcodeChallengeWidgetState();
}

class _BarcodeChallengeWidgetState extends State<BarcodeChallengeWidget> {
  bool _scanned = false;
  bool _wrongScan = false;

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty || barcodes.first.rawValue == null) return;

    final scannedValue = barcodes.first.rawValue!;
    final locked = widget.lockedQrCode;

    if (locked == null || scannedValue == locked) {
      _scanned = true;
      widget.onPassed();
    } else {
      setState(() => _wrongScan = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _wrongScan = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLockedMode = widget.lockedQrCode != null;
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          if (_wrongScan)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: Text(
                    'Wrong code!\nWalk to your spot.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Text(
                isLockedMode
                    ? 'Walk to your spot and scan the QR code!'
                    : 'Scan any barcode or QR code to dismiss',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
