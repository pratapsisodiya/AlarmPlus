class SleepEntry {
  const SleepEntry({
    required this.date,
    required this.sleepQuality,
    required this.morningMood,
    this.notes,
    this.bedtime,
    this.wakeTime,
    this.deepSleepEstimate,
  });

  final String date; // 'YYYY-MM-DD'
  final int sleepQuality; // 1-5
  final int morningMood; // 1-5
  final String? notes;
  final DateTime? bedtime;
  final DateTime? wakeTime;
  final int? deepSleepEstimate; // minutes

  Map<String, dynamic> toJson() => {
    'date': date,
    'sleepQuality': sleepQuality,
    'morningMood': morningMood,
    'notes': notes,
    'bedtime': bedtime?.toIso8601String(),
    'wakeTime': wakeTime?.toIso8601String(),
    'deepSleepEstimate': deepSleepEstimate,
  };

  factory SleepEntry.fromJson(Map<String, dynamic> json) => SleepEntry(
    date: json['date'] as String? ?? '',
    sleepQuality: json['sleepQuality'] as int? ?? 3,
    morningMood: json['morningMood'] as int? ?? 3,
    notes: json['notes'] as String?,
    bedtime: json['bedtime'] != null ? DateTime.parse(json['bedtime'] as String) : null,
    wakeTime: json['wakeTime'] != null ? DateTime.parse(json['wakeTime'] as String) : null,
    deepSleepEstimate: json['deepSleepEstimate'] as int?,
  );

  SleepEntry copyWith({
    String? date,
    int? sleepQuality,
    int? morningMood,
    String? notes,
    DateTime? bedtime,
    DateTime? wakeTime,
    int? deepSleepEstimate,
  }) => SleepEntry(
    date: date ?? this.date,
    sleepQuality: sleepQuality ?? this.sleepQuality,
    morningMood: morningMood ?? this.morningMood,
    notes: notes ?? this.notes,
    bedtime: bedtime ?? this.bedtime,
    wakeTime: wakeTime ?? this.wakeTime,
    deepSleepEstimate: deepSleepEstimate ?? this.deepSleepEstimate,
  );
}
