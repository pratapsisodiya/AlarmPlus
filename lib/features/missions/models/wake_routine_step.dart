class WakeRoutineStep {
  const WakeRoutineStep({
    required this.id,
    required this.title,
    required this.instruction,
    required this.icon,
    required this.durationSeconds,
    this.isTimedBreath = false,
  });

  final String id;
  final String title;
  final String instruction;
  final String icon;
  final int durationSeconds;
  final bool isTimedBreath;
}
