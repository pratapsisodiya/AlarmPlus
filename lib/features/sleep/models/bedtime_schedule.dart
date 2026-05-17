import 'package:flutter/material.dart';

class BedtimeSchedule {
  const BedtimeSchedule({
    required this.targetBedtime,
    this.windDownMinutes = 30,
    this.isEnabled = false,
  });

  final TimeOfDay targetBedtime;
  final int windDownMinutes;
  final bool isEnabled;

  Map<String, dynamic> toJson() => {
    'bedtimeHour': targetBedtime.hour,
    'bedtimeMinute': targetBedtime.minute,
    'windDownMinutes': windDownMinutes,
    'isEnabled': isEnabled,
  };

  factory BedtimeSchedule.fromJson(Map<String, dynamic> json) => BedtimeSchedule(
    targetBedtime: TimeOfDay(
      hour: json['bedtimeHour'] as int? ?? 22,
      minute: json['bedtimeMinute'] as int? ?? 30,
    ),
    windDownMinutes: json['windDownMinutes'] as int? ?? 30,
    isEnabled: json['isEnabled'] as bool? ?? false,
  );

  BedtimeSchedule copyWith({
    TimeOfDay? targetBedtime,
    int? windDownMinutes,
    bool? isEnabled,
  }) {
    return BedtimeSchedule(
      targetBedtime: targetBedtime ?? this.targetBedtime,
      windDownMinutes: windDownMinutes ?? this.windDownMinutes,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
