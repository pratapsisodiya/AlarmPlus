import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/wake_routine_step.dart';
import '../services/smart_alarm_service.dart';
import '../services/wake_routine_service.dart';
import 'morning_missions_screen.dart';

class WakeRoutineScreen extends StatefulWidget {
  const WakeRoutineScreen({super.key});

  static const routeName = '/wake-routine';

  @override
  State<WakeRoutineScreen> createState() => _WakeRoutineScreenState();
}

class _WakeRoutineScreenState extends State<WakeRoutineScreen>
    with TickerProviderStateMixin {
  final List<WakeRoutineStep> _steps = WakeRoutineService.defaultSteps;

  int _stepIndex = 0;
  int _secondsLeft = 0;
  int _completedCount = 0;
  bool _stepDone = false;

  // Breath phase: 0=inhale, 1=hold, 2=exhale
  int _breathPhase = 0;
  int _breathPhaseSeconds = 0;
  static const _breathPhaseDurations = [4, 4, 4];
  static const _breathPhaseLabels = ['Inhale', 'Hold', 'Exhale'];

  late AnimationController _timerController;
  late AnimationController _breathController;
  Timer? _countdownTimer;

  WakeRoutineStep get _currentStep => _steps[_stepIndex];

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(vsync: this);
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _startStep();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _timerController.dispose();
    _breathController.dispose();
    super.dispose();
  }

  void _startStep() {
    _countdownTimer?.cancel();
    final step = _currentStep;
    setState(() {
      _secondsLeft = step.durationSeconds;
      _stepDone = false;
      _breathPhase = 0;
      _breathPhaseSeconds = _breathPhaseDurations[0];
    });

    _timerController.duration = Duration(seconds: step.durationSeconds);
    _timerController.forward(from: 0);

    if (step.isTimedBreath) {
      _breathController.repeat(reverse: true);
    } else {
      _breathController.stop();
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _secondsLeft--;
        if (step.isTimedBreath) {
          _breathPhaseSeconds--;
          if (_breathPhaseSeconds <= 0) {
            _breathPhase = (_breathPhase + 1) % 3;
            _breathPhaseSeconds = _breathPhaseDurations[_breathPhase];
          }
        }
        if (_secondsLeft <= 0) {
          t.cancel();
          _stepDone = true;
        }
      });
    });
  }

  void _advance({required bool completed}) {
    _countdownTimer?.cancel();
    if (completed) {
      _completedCount++;
    }

    if (_stepIndex < _steps.length - 1) {
      setState(() => _stepIndex++);
      _startStep();
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final bonus = WakeRoutineService.calculateAwakeBonus(
      _completedCount,
      _steps.length,
    );
    await WakeRoutineService.markRoutineCompleted();
    if (bonus > 0) {
      await SmartAlarmService.addXp(bonus);
    }
    if (!mounted) return;
    _showCompletionSheet(bonus);
  }

  void _showCompletionSheet(int bonus) {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌟', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            const Text(
              'Wake Routine Complete!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '$_completedCount / ${_steps.length} steps · +$bonus XP',
              style: const TextStyle(fontSize: 16, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pushReplacementNamed(
                    MorningMissionsScreen.routeName,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
                child: const Text(
                  'Start Morning Missions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).pushNamed('/morning-checkin');
              },
              child: const Text(
                'Sleep Check-In',
                style: TextStyle(color: Color(0xFF6366F1)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).pop();
              },
              child: const Text(
                'Skip missions',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_stepIndex) / _steps.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'WAKE ROUTINE',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
            color: Color(0xFF64748B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF22C55E),
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Step ${_stepIndex + 1} of ${_steps.length}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            // Step icon
            Center(
              child: Text(
                _currentStep.icon,
                style: const TextStyle(fontSize: 72),
              ),
            ),
            const SizedBox(height: 20),
            // Title
            Center(
              child: Text(
                _currentStep.title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            // Instruction
            Center(
              child: Text(
                _currentStep.instruction,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 36),
            // Timer ring or breath indicator
            Center(
              child: _currentStep.isTimedBreath
                  ? _buildBreathIndicator()
                  : _buildTimerRing(),
            ),
            const Spacer(),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _advance(completed: false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _stepDone ? () => _advance(completed: true) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                    child: Text(
                      _stepIndex < _steps.length - 1 ? 'Done  →' : 'Finish',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerRing() {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _timerController,
            builder: (context, child) => CustomPaint(
              size: const Size(140, 140),
              painter: _RingPainter(
                progress: 1.0 - _timerController.value,
                color: const Color(0xFF22C55E),
              ),
            ),
          ),
          Text(
            '$_secondsLeft',
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreathIndicator() {
    final label = _breathPhaseLabels[_breathPhase];
    return Column(
      children: [
        AnimatedBuilder(
          animation: _breathController,
          builder: (context, child) {
            final scale = 0.7 + (_breathController.value * 0.3);
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                  border: Border.all(
                    color: const Color(0xFF22C55E),
                    width: 3,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          label,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        Text(
          '$_breathPhaseSeconds s',
          style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final trackPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
