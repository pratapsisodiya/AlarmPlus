import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:alarm_plus/features/location/models/location_alarm.dart';
import 'package:alarm_plus/features/alarm/services/alarm_service.dart';

class LocationAlarmService {
  static const _key = 'location_alarms';
  static StreamSubscription<Position>? _positionSub;
  static List<LocationAlarm> _cached = [];

  static Future<void> save(LocationAlarm alarm) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadAll();
    final idx = existing.indexWhere((e) => e.id == alarm.id);
    if (idx >= 0) {
      existing[idx] = alarm;
    } else {
      existing.add(alarm);
    }
    await prefs.setStringList(_key, existing.map((e) => jsonEncode(e.toJson())).toList());
    _cached = existing;
  }

  static Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadAll();
    existing.removeWhere((e) => e.id == id);
    await prefs.setStringList(_key, existing.map((e) => jsonEncode(e.toJson())).toList());
    _cached = existing;
  }

  static Future<List<LocationAlarm>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((s) {
      try {
        return LocationAlarm.fromJson(jsonDecode(s) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<LocationAlarm>().toList();
  }

  static Future<bool> requestPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  static Future<void> startMonitoring() async {
    await stopMonitoring();
    _cached = await loadAll();
    if (_cached.isEmpty) return;

    const settings = LocationSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 50,
    );

    _positionSub = Geolocator.getPositionStream(locationSettings: settings).listen((pos) {
      _checkGeofences(pos.latitude, pos.longitude);
    });
  }

  static Future<void> stopMonitoring() async {
    await _positionSub?.cancel();
    _positionSub = null;
  }

  static void _checkGeofences(double lat, double lng) {
    for (final alarm in _cached) {
      if (!alarm.isEnabled) continue;
      final dist = _haversineMeters(lat, lng, alarm.lat, alarm.lng);
      if (dist <= alarm.radiusMeters) {
        _triggerLocationAlarm(alarm);
      }
    }
  }

  static Future<void> _triggerLocationAlarm(LocationAlarm locAlarm) async {
    // Disable to prevent repeat triggering
    await save(locAlarm.copyWith(isEnabled: false));

    final alarms = AlarmService.getAllAlarms();
    if (alarms.isEmpty) return;

    // Schedule the first enabled alarm immediately (2 seconds from now)
    final target = alarms.firstWhere((a) => a.isEnabled, orElse: () => alarms.first);
    final triggerTime = DateTime.now().add(const Duration(seconds: 2));
    final updated = target.copyWith(
      time: TimeOfDay(hour: triggerTime.hour, minute: triggerTime.minute),
      isEnabled: true,
    );
    await AlarmService.scheduleAlarm(updated, persist: false);
  }

  static double _haversineMeters(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _toRad(double deg) => deg * pi / 180;

  static String generateId() => const Uuid().v4();
}
