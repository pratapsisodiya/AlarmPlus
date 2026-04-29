import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

import '../models/alarm_model.dart';
import '../models/challenge_type.dart';
import 'smart_alarm_service.dart';
import 'storage_service.dart';

class AlarmService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static final Uuid _uuid = const Uuid();
  static final StreamController<int> _ringIntents =
      StreamController<int>.broadcast();

  static Stream<int> get ringIntents => _ringIntents.stream;

  static bool get _supportsNativeAlarmOps => !kIsWeb;

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    if (_supportsNativeAlarmOps) {
      await Alarm.init();
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await AndroidAlarmManager.initialize();
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
      macOS: iosInit,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTap,
    );
    await requestPermissions();
  }

  static void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload?.trim() ?? '';
    final alarmId = int.tryParse(payload);
    if (alarmId == null) {
      return;
    }
    _ringIntents.add(alarmId);
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTap(NotificationResponse response) {
    _onNotificationResponse(response);
  }

  static Future<void> requestPermissions() async {
    if (kIsWeb) {
      return;
    }

    await Permission.notification.request();

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await Permission.scheduleExactAlarm.request();
      await Permission.ignoreBatteryOptimizations.request();
    }
  }

  static Future<void> saveAlarm(AlarmModel alarm) async {
    await StorageService.saveAlarm(alarm);
  }

  static Future<void> scheduleAlarm(
    AlarmModel alarm, {
    bool persist = true,
  }) async {
    await _cancelScheduledArtifacts(alarm.id);

    if (!_supportsNativeAlarmOps) {
      if (persist) {
        await saveAlarm(alarm.copyWith(isEnabled: true));
      }
      return;
    }

    final targetTime = alarm.nextDateTimeFrom(DateTime.now());
    final alarmId = alarmIntId(alarm.id);
    final selectedSound = SmartAlarmService.rotateSoundForDate(
      targetTime,
      alarm.sound,
    );

    final settings = AlarmSettings(
      id: alarmId,
      dateTime: targetTime,
      assetAudioPath: selectedSound == 'default' ? null : selectedSound,
      volumeSettings: VolumeSettings.fade(fadeDuration: Duration(seconds: 8)),
      notificationSettings: NotificationSettings(
        title: alarm.label.isEmpty ? 'Alarm+' : alarm.label,
        body: alarm.tag,
      ),
      loopAudio: true,
      vibrate: true,
      warningNotificationOnKill:
          !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
      androidFullScreenIntent: true,
    );

    try {
      await Alarm.set(alarmSettings: settings);
      await SmartAlarmService.checkNightOwlBadge(alarm.time);
    } catch (error) {
      // Some devices deny exact alarms; keep notification fallback alive.
      debugPrint('Alarm.set failed for ${alarm.id}: $error');
    }

    final location = tz.local;
    final zoned = tz.TZDateTime.from(targetTime, location);
    final exactPermission = await Permission.scheduleExactAlarm.status;
    final scheduleMode = (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
        ? (exactPermission.isGranted
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexactAllowWhileIdle)
        : AndroidScheduleMode.exactAllowWhileIdle;

    await _notifications.zonedSchedule(
      alarmId,
      alarm.label.isEmpty ? 'Alarm+' : alarm.label,
      alarm.tag,
      zoned,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'alarm_plus_alarms',
          'Alarm+ Alarms',
          channelDescription: 'Daily and weekly smart alarm reminders',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          ongoing: true,
          autoCancel: false,
          ticker: 'Alarm+ is ringing',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: scheduleMode,
      matchDateTimeComponents: alarm.repeatDays.isNotEmpty
          ? DateTimeComponents.time
          : null,
      payload: '$alarmId',
    );

    final windDownMinutes = await SmartAlarmService.getWindDownMinutes();
    final windDownTime = targetTime.subtract(
      Duration(minutes: windDownMinutes),
    );
    if (windDownTime.isAfter(DateTime.now())) {
      await _notifications.zonedSchedule(
        _windDownNotificationId(alarm.id),
        'Wind-down reminder',
        'Alarm in $windDownMinutes min. ${SmartAlarmService.windDownChecklist().join(' • ')}',
        tz.TZDateTime.from(windDownTime, location),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'alarm_plus_winddown',
            'Alarm+ Wind-down',
            channelDescription: 'Pre-alarm sleep prep reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: scheduleMode,
      );
    }

    if (persist) {
      await saveAlarm(alarm.copyWith(isEnabled: true));
    }
  }

  static Future<void> cancelAlarm(String id) async {
    await _cancelScheduledArtifacts(id);
  }

  static Future<void> deleteAlarm(String id) async {
    await _cancelScheduledArtifacts(id);
    await StorageService.deleteAlarm(id);
  }

  static Future<void> restoreEnabledAlarms() async {
    final alarms = getAllAlarms().where((alarm) => alarm.isEnabled);
    for (final alarm in alarms) {
      await scheduleAlarm(alarm, persist: false);
    }
  }

  static Future<void> _cancelScheduledArtifacts(String id) async {
    if (!_supportsNativeAlarmOps) {
      return;
    }

    final alarmId = alarmIntId(id);
    await Alarm.stop(alarmId);
    await _notifications.cancel(alarmId);
    await _notifications.cancel(_windDownNotificationId(id));
  }

  static Future<void> toggleAlarm(String id, bool on) async {
    final alarm = StorageService.getAlarm(id);
    if (alarm == null) {
      return;
    }

    final updated = alarm.copyWith(isEnabled: on);
    await saveAlarm(updated);

    if (on) {
      await scheduleAlarm(updated);
    } else {
      await cancelAlarm(id);
    }
  }

  static List<AlarmModel> getAllAlarms() {
    return StorageService.getAllAlarms();
  }

  static AlarmModel createAlarm({
    required TimeOfDay time,
    required String label,
    required List<int> repeatDays,
    required bool isEnabled,
    required String tag,
    String sound = 'default',
    String personality = 'gentle',
    bool gentleWake = false,
    int gentleWakeDurationSeconds = 60,
    ChallengeType? challengeType,
    String? voiceMemoPath,
  }) {
    return AlarmModel(
      id: _uuid.v4(),
      time: time,
      label: label,
      repeatDays: repeatDays,
      isEnabled: isEnabled,
      tag: tag,
      sound: sound,
      personality: personality,
      gentleWake: gentleWake,
      gentleWakeDurationSeconds: gentleWakeDurationSeconds,
      challengeType: challengeType,
      voiceMemoPath: voiceMemoPath,
    );
  }

  static String formatTimeLabel(DateTime value) {
    return DateFormat('hh:mm a').format(value);
  }

  static int _idToInt(String id) {
    final sanitized = id.replaceAll('-', '');

    // Build a stable positive 31-bit value so Android-side int IDs never overflow.
    var hash = 0;
    for (final codeUnit in sanitized.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }

    if (hash == 0) {
      hash = id.hashCode & 0x7fffffff;
    }

    // Avoid zero and keep headroom for derived notification IDs.
    return (hash % 1000000000) + 1;
  }

  static int alarmIntId(String id) => _idToInt(id);

  static int _windDownNotificationId(String id) {
    final base = alarmIntId(id);
    return ((base + 900000) % 1000000000) + 1;
  }

  static AlarmModel? findByIntId(int alarmId) {
    for (final alarm in getAllAlarms()) {
      if (alarmIntId(alarm.id) == alarmId) {
        return alarm;
      }
    }
    return null;
  }

  static Future<void> scheduleNapAlarm(DateTime wakeTime) async {
    final alarm = createAlarm(
      time: TimeOfDay(hour: wakeTime.hour, minute: wakeTime.minute),
      label: 'Nap Over! 😴',
      repeatDays: const [],
      isEnabled: true,
      tag: 'nap_timer',
    );
    await saveAlarm(alarm);
    await scheduleAlarm(alarm);
  }

  static Future<void> cancelNapAlarm() async {
    final nap = getAllAlarms().where((a) => a.tag == 'nap_timer').firstOrNull;
    if (nap != null) {
      await deleteAlarm(nap.id);
    }
  }

  static Future<bool> autoAdjustNextAlarmFromMood({
    required int energy,
    required int sleepQuality,
  }) async {
    final alarms = getAllAlarms().where((alarm) => alarm.isEnabled).toList();
    if (alarms.isEmpty) {
      return false;
    }

    alarms.sort(
      (a, b) => a
          .nextDateTimeFrom(DateTime.now())
          .compareTo(b.nextDateTimeFrom(DateTime.now())),
    );
    final target = alarms.first;

    var deltaMinutes = 0;
    if (sleepQuality <= 2 || energy <= 2) {
      deltaMinutes = 15;
    } else if (sleepQuality >= 4 && energy >= 4) {
      deltaMinutes = -10;
    }

    if (deltaMinutes == 0) {
      return false;
    }

    final current = (target.time.hour * 60) + target.time.minute;
    final shifted = (current + deltaMinutes).clamp(0, (24 * 60) - 1);
    final updated = target.copyWith(
      time: TimeOfDay(hour: shifted ~/ 60, minute: shifted % 60),
      tag: 'Mood-adjusted',
    );

    await scheduleAlarm(updated);
    return true;
  }
}
