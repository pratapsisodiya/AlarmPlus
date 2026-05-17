import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class ShakeChallengeWidget extends StatefulWidget {
  const ShakeChallengeWidget({super.key, required this.onPassed});

  final VoidCallback onPassed;
  static const _requiredShakes = 20;

  @override
  State<ShakeChallengeWidget> createState() => _ShakeChallengeWidgetState();
}

class _ShakeChallengeWidgetState extends State<ShakeChallengeWidget> {
  int _shakeCount = 0;
  StreamSubscription<AccelerometerEvent>? _sub;
  double _prevMag = 0;
  static const _threshold = 15.0;

  @override
  void initState() {
    super.initState();
    _sub = accelerometerEventStream().listen((event) {
      final mag = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (_prevMag > 0 && (mag - _prevMag).abs() > _threshold) {
        setState(() => _shakeCount++);
        if (_shakeCount >= ShakeChallengeWidget._requiredShakes) {
          _sub?.cancel();
          widget.onPassed();
        }
      }
      _prevMag = mag;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _shakeCount / ShakeChallengeWidget._requiredShakes;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📳', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          const Text(
            'Shake your phone!',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
          ),
          const SizedBox(height: 8),
          Text(
            '$_shakeCount / ${ShakeChallengeWidget._requiredShakes} shakes',
            style: const TextStyle(fontSize: 16, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
            ),
          ),
        ],
      ),
    );
  }
}
