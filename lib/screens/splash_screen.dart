import 'dart:math' as math;

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const routeName = '/splash';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnimationController _shimmerController;

  // Circle arc draw
  late final Animation<double> _circleProgress;
  // Star orbiting along arc
  late final Animation<double> _starProgress;
  // Icon scale pop
  late final Animation<double> _iconScale;
  // Icon fade in
  late final Animation<double> _iconOpacity;
  // Title fade + slide up
  late final Animation<double> _titleOpacity;
  late final Animation<double> _titleSlide;
  // Subtitle fade
  late final Animation<double> _subtitleOpacity;
  // Circle scale breath
  late final Animation<double> _circleScale;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _circleProgress = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    );

    _starProgress = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.02, 0.57, curve: Curves.easeOutCubic),
    );

    _circleScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.30, 0.55, curve: Curves.elasticOut),
      ),
    );

    _iconOpacity = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.30, 0.45, curve: Curves.easeIn),
    );

    _titleOpacity = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.58, 0.75, curve: Curves.easeInOut),
    );

    _titleSlide = Tween<double>(begin: 18, end: 0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.58, 0.78, curve: Curves.easeOutCubic),
      ),
    );

    _subtitleOpacity = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.72, 0.88, curve: Curves.easeIn),
    );

    _mainController.forward();
    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).pushReplacementNamed('/app');
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_mainController, _shimmerController]),
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: _circleScale.value,
                  child: SizedBox(
                    width: 260,
                    height: 260,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // The arc + star
                        CustomPaint(
                          size: const Size.square(260),
                          painter: _SplashCirclePainter(
                            progress: _circleProgress.value,
                            starProgress: _starProgress.value,
                          ),
                        ),
                        // Centered icon image with scale pop
                        Opacity(
                          opacity: _iconOpacity.value,
                          child: Transform.scale(
                            scale: _iconScale.value,
                            child: Image.asset(
                              'assets/icon/icon.png',
                              width: 90,
                              height: 90,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                // App name
                Transform.translate(
                  offset: Offset(0, _titleSlide.value),
                  child: Opacity(
                    opacity: _titleOpacity.value,
                    child: const Text(
                      'Alarm+',
                      style: TextStyle(
                        fontSize: 34,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Tagline
                Opacity(
                  opacity: _subtitleOpacity.value,
                  child: const Text(
                    'Wake up smarter',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SplashCirclePainter extends CustomPainter {
  _SplashCirclePainter({required this.progress, required this.starProgress});

  final double progress;
  final double starProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 16;

    final sweepTotal = 2 * math.pi * 0.88;
    final startAngle = -math.pi / 2 - 0.78;
    final sweep = sweepTotal * progress;

    // Light subtle track
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = const Color(0xFFE2E8F0);

    canvas.drawCircle(center, radius, trackPaint);

    // Main arc
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..color = const Color(0xFF0F172A)
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweep,
      false,
      arcPaint,
    );

    // Sparkle star at arc tip
    if (starProgress > 0.01) {
      final starAngle = startAngle + (sweepTotal * starProgress);
      final starCenter = Offset(
        center.dx + radius * math.cos(starAngle),
        center.dy + radius * math.sin(starAngle),
      );
      _drawSparkStar(canvas, starCenter, 14, const Color(0xFF0F172A));
    }
  }

  void _drawSparkStar(Canvas canvas, Offset center, double r, Color color) {
    final path = Path();
    final points = <Offset>[];

    for (var i = 0; i < 8; i++) {
      final angle = (-math.pi / 2) + (i * math.pi / 4);
      final rad = i.isEven ? r : r * 0.38;
      points.add(
        Offset(
          center.dx + rad * math.cos(angle),
          center.dy + rad * math.sin(angle),
        ),
      );
    }

    path.moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    path.close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SplashCirclePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.starProgress != starProgress;
  }
}
