import 'package:flutter/material.dart';

import '../models/location_alarm.dart';
import '../services/location_alarm_service.dart';
import 'location_picker_screen.dart';

class LocationAlarmScreen extends StatefulWidget {
  const LocationAlarmScreen({super.key});

  static const routeName = '/location-alarms';

  @override
  State<LocationAlarmScreen> createState() => _LocationAlarmScreenState();
}

class _LocationAlarmScreenState extends State<LocationAlarmScreen> {
  late Future<List<LocationAlarm>> _alarmsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _alarmsFuture = LocationAlarmService.loadAll();
    });
  }

  Future<void> _addNew() async {
    final result = await Navigator.of(context).pushNamed(LocationPickerScreen.routeName);
    if (result != null) _refresh();
  }

  Future<void> _delete(LocationAlarm alarm) async {
    await LocationAlarmService.delete(alarm.id);
    _refresh();
  }

  Future<void> _toggle(LocationAlarm alarm, bool enabled) async {
    await LocationAlarmService.save(alarm.copyWith(isEnabled: enabled));
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'LOCATION ALARMS',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 3, color: Color(0xFF64748B)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNew,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_location_alt_rounded),
      ),
      body: FutureBuilder<List<LocationAlarm>>(
        future: _alarmsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final alarms = snapshot.data!;
          if (alarms.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('📍', style: TextStyle(fontSize: 56)),
                  SizedBox(height: 16),
                  Text('No location alarms', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to add an alarm that\ntriggers when you arrive somewhere',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
            itemCount: alarms.length,
            itemBuilder: (context, i) {
              final alarm = alarms[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.location_on_rounded, color: Color(0xFF3B82F6)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(alarm.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          Text(
                            '${alarm.lat.toStringAsFixed(4)}, ${alarm.lng.toStringAsFixed(4)} · ${alarm.radiusMeters.round()}m radius',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: alarm.isEnabled,
                      onChanged: (v) => _toggle(alarm, v),
                      activeTrackColor: const Color(0xFF22C55E),
                      activeThumbColor: Colors.white,
                      inactiveTrackColor: const Color(0xFFE2E8F0),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                      onPressed: () => _delete(alarm),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
