import 'package:flutter/material.dart';

class SunriseGradient extends StatefulWidget {
  const SunriseGradient({
    super.key,
    required this.durationSeconds,
    required this.child,
  });

  final int durationSeconds;
  final Widget child;

  @override
  State<SunriseGradient> createState() => _SunriseGradientState();
}

class _SunriseGradientState extends State<SunriseGradient>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _stops = [
    Color(0xFF1a0533), // midnight purple
    Color(0xFF7c3aed), // deep violet
    Color(0xFFf97316), // deep orange
    Color(0xFFfbbf24), // golden
    Color(0xFFfef9c3), // soft white-yellow
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.durationSeconds),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final colorIndex = (t * (_stops.length - 1)).floor().clamp(0, _stops.length - 2);
        final localT = (t * (_stops.length - 1)) - colorIndex;
        final color = Color.lerp(_stops[colorIndex], _stops[colorIndex + 1], localT)!;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [color, color.withValues(alpha: 0.6)],
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
