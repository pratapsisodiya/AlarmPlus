class AlarmRingEvent {
  const AlarmRingEvent({
    required this.alarmId,
    required this.scheduledTime,
    required this.snoozeCount,
    required this.wasMissed,
    required this.wakeScore,
    this.actualDismissTime,
  });

  final String alarmId;
  final DateTime scheduledTime;
  final DateTime? actualDismissTime;
  final int snoozeCount;
  final bool wasMissed;
  final int wakeScore;

  Map<String, dynamic> toJson() => {
    'alarmId': alarmId,
    'scheduledTime': scheduledTime.toIso8601String(),
    'actualDismissTime': actualDismissTime?.toIso8601String(),
    'snoozeCount': snoozeCount,
    'wasMissed': wasMissed,
    'wakeScore': wakeScore,
  };

  factory AlarmRingEvent.fromJson(Map<String, dynamic> json) => AlarmRingEvent(
    alarmId: json['alarmId'] as String? ?? '',
    scheduledTime: DateTime.parse(json['scheduledTime'] as String),
    actualDismissTime: json['actualDismissTime'] != null
        ? DateTime.parse(json['actualDismissTime'] as String)
        : null,
    snoozeCount: json['snoozeCount'] as int? ?? 0,
    wasMissed: json['wasMissed'] as bool? ?? false,
    wakeScore: json['wakeScore'] as int? ?? 0,
  );
}
