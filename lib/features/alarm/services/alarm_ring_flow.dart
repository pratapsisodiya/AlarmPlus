import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:alarm_plus/features/alarm/screens/alarm_ring_screen.dart';
import 'package:alarm_plus/features/alarm/services/alarm_service.dart';
import 'package:alarm_plus/core/services/smart_alarm_service.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AlarmRingFlow {
  static StreamSubscription<dynamic>? _ringSubscription;
  static StreamSubscription<int>? _ringIntentSubscription;
  static bool _ringScreenVisible = false;
  static final Set<int> _knownRingingIds = <int>{};
  static final Map<int, Timer> _missedRecoveryTimers = <int, Timer>{};
  static int _currentRingingId = 0;

  // Tracks alarms that were snoozed before being stopped (for XP calculation)
  static final Set<int> _snoozedIds = <int>{};
  // Tracks snooze count per alarm session for Boss Mode
  static final Map<int, int> _snoozeSessionCount = <int, int>{};

  static const _channel = MethodChannel('alarmplus/alarm_controls');

  static void bindNativeAlarmEvents() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'snooze') {
        final id = (call.arguments as int?) ?? _currentRingingId;
        if (id > 0) await snoozeAlarm(id);
      } else if (call.method == 'stopFromNotification') {
        final id = (call.arguments as int?) ?? _currentRingingId;
        if (id > 0) await _stopFromNotification(id);
      }
    });

    _ringSubscription ??= Alarm.ringing.listen((ringingSet) {
      final ids = ringingSet.alarms.map((alarm) => alarm.id).toSet();
      final newIds = ids.difference(_knownRingingIds);

      for (final id in newIds) {
        onAlarmRing(id);
      }

      _knownRingingIds
        ..clear()
        ..addAll(ids);

      if (ids.isEmpty) {
        _ringScreenVisible = false;
      }
    });

    _ringIntentSubscription ??= AlarmService.ringIntents.listen((alarmId) {
      if (alarmId <= 0) {
        return;
      }
      onAlarmRing(alarmId);
    });
  }

  static Future<void> onAlarmRing(int alarmId) async {
    _currentRingingId = alarmId;
    await WakelockPlus.enable();

    // Start foreground service for lock-screen takeover + volume-snooze
    await _startForegroundService(alarmId);

    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        await Vibration.vibrate(pattern: [500, 1000], repeat: 0);
      }
    } catch (_) {
      // Vibration capability differs by device.
    }

    final navigator = appNavigatorKey.currentState;
    if (navigator != null && !_ringScreenVisible) {
      _ringScreenVisible = true;
      navigator.pushNamed(
        AlarmRingScreen.routeName,
        arguments: {'alarmId': alarmId, 'snoozeCount': _snoozeSessionCount[alarmId] ?? 0},
      );
    }

    _missedRecoveryTimers[alarmId]?.cancel();
    _missedRecoveryTimers[alarmId] = Timer(
      const Duration(minutes: 2),
      () async {
        final alarm = AlarmService.findByIntId(alarmId);
        if (alarm == null) {
          return;
        }

        final stillRinging = await Alarm.isRinging(alarmId);
        if (!stillRinging) {
          return;
        }

        await SmartAlarmService.recordMissed();

        final backupTime = DateTime.now().add(const Duration(minutes: 3));
        final backup = alarm.copyWith(
          time: TimeOfDay(hour: backupTime.hour, minute: backupTime.minute),
          tag: 'Recovery backup',
          isEnabled: true,
        );
        await AlarmService.scheduleAlarm(backup);
      },
    );
  }

  static Future<void> snoozeAlarm(int alarmId) async {
    final alarm = AlarmService.findByIntId(alarmId);
    if (alarm == null) {
      return;
    }

    await AlarmService.cancelAlarm(alarm.id);

    final newTime = DateTime.now().add(const Duration(minutes: 5));
    final updated = alarm.copyWith(
      time: TimeOfDay(hour: newTime.hour, minute: newTime.minute),
      isEnabled: true,
    );

    await AlarmService.scheduleAlarm(updated, persist: false);
    await SmartAlarmService.recordSnoozed();

    // Mark this alarm as having been snoozed before final dismissal
    _snoozedIds.add(alarmId);
    _snoozeSessionCount[alarmId] = (_snoozeSessionCount[alarmId] ?? 0) + 1;

    await _stopEffects();

    appNavigatorKey.currentState?.pop();
    _ringScreenVisible = false;
  }

  /// Stops the alarm and records XP/badges. Does NOT pop the ring screen —
  /// the screen calls [completeRingScreenDismiss] after showing its celebration modal.
  static Future<DismissReward?> stopAlarm(int alarmId) async {
    final alarm = AlarmService.findByIntId(alarmId);
    if (alarm == null) {
      return null;
    }

    await AlarmService.cancelAlarm(alarm.id);

    if (alarm.repeatDays.isNotEmpty) {
      await AlarmService.scheduleAlarm(alarm);
    } else {
      await AlarmService.saveAlarm(alarm.copyWith(isEnabled: false));
    }

    // Determine if user snoozed before finally dismissing
    final hadSnooze = _snoozedIds.remove(alarmId);
    final snoozeCount = _snoozeSessionCount.remove(alarmId) ?? 0;
    final reward = await SmartAlarmService.recordDismissed(hadSnooze: hadSnooze, snoozeCount: snoozeCount);

    _missedRecoveryTimers[alarmId]?.cancel();
    _missedRecoveryTimers.remove(alarmId);

    // Stop audio/vibration immediately so sound doesn't play during celebration modal
    await _stopEffects();

    return reward;
  }

  /// Call this after the ring screen celebration modal is dismissed to pop the screen.
  static void completeRingScreenDismiss() {
    appNavigatorKey.currentState?.pop();
    _ringScreenVisible = false;
    _currentRingingId = 0;
  }

  /// Stop button tapped directly on the lock-screen notification.
  /// Silently dismisses — no challenge, no celebration modal.
  static Future<void> _stopFromNotification(int alarmId) async {
    final alarm = AlarmService.findByIntId(alarmId);
    if (alarm == null) return;
    await AlarmService.cancelAlarm(alarm.id);
    if (alarm.repeatDays.isNotEmpty) {
      await AlarmService.scheduleAlarm(alarm);
    } else {
      await AlarmService.saveAlarm(alarm.copyWith(isEnabled: false));
    }
    _snoozedIds.remove(alarmId);
    _snoozeSessionCount.remove(alarmId);
    _missedRecoveryTimers[alarmId]?.cancel();
    _missedRecoveryTimers.remove(alarmId);
    await SmartAlarmService.recordDismissed(hadSnooze: false, snoozeCount: 0);
    await _stopEffects();
    appNavigatorKey.currentState?.pop();
    _ringScreenVisible = false;
    _currentRingingId = 0;
  }

  static Future<void> _stopEffects() async {
    await Vibration.cancel();
    await WakelockPlus.disable();
    await _stopForegroundService();
  }

  static Future<void> _startForegroundService(int alarmId) async {
    try {
      await _channel.invokeMethod<void>('startAlarmService', {'alarmId': alarmId});
    } catch (_) {}
  }

  static Future<void> _stopForegroundService() async {
    try {
      await _channel.invokeMethod<void>('stopAlarmService');
    } catch (_) {}
  }
}
