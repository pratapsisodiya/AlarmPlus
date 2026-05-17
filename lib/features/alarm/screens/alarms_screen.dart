import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alarm_plus/features/alarm/models/alarm_personality.dart';
import 'package:alarm_plus/shared/models/challenge_type.dart';
import 'package:alarm_plus/features/alarm/services/alarm_providers.dart';
import 'package:alarm_plus/features/alarm/services/challenge_service.dart';
import 'package:alarm_plus/features/alarm/screens/quest_builder_screen.dart';
import 'package:alarm_plus/features/alarm/screens/qr_spot_setup_screen.dart';
import 'package:alarm_plus/core/services/premium_service.dart';
import 'package:alarm_plus/core/services/smart_alarm_service.dart';
import 'package:alarm_plus/shared/widgets/alarm_card.dart';
import 'package:alarm_plus/features/sleep/widgets/voice_memo_recorder.dart';

class AlarmsScreen extends ConsumerWidget {
  const AlarmsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarmsAsync = ref.watch(alarmsListProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'YOUR ALARMS',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            letterSpacing: 3,
            color: const Color(0xFF64748B),
          ),
        ),
      ),
      body: alarmsAsync.when(
        data: (alarms) => ListView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
          children: [
            ...alarms.map(
              (alarm) => AlarmCard(
                alarm: alarm,
                onToggle: (enabled) {
                  ref
                      .read(alarmsMapProvider.notifier)
                      .toggleAlarm(alarm.id, enabled);
                },
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAlarmSheet(context, ref),
        backgroundColor: const Color(0xFFF4F4F6),
        foregroundColor: Colors.black,
        elevation: 2,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }

  void _showAddAlarmSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddAlarmSheet(ref: ref),
    );
  }
}

class _AddAlarmSheet extends ConsumerStatefulWidget {
  const _AddAlarmSheet({required this.ref});
  final WidgetRef ref;

  @override
  ConsumerState<_AddAlarmSheet> createState() => _AddAlarmSheetState();
}

class _AddAlarmSheetState extends ConsumerState<_AddAlarmSheet> {
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _voiceQuickAddController =
      TextEditingController();

  int _hour = 7;
  int _minute = 30;
  bool _isAm = true;
  bool _setAlarm = true;
  String _tag = 'Steady wake';
  String _sound = 'default';
  String _personality = 'gentle';
  final Set<int> _repeatDays = {2, 3, 4, 5, 6};
  bool _gentleWake = false;
  int _gentleWakeDuration = 60;
  ChallengeType? _challengeType;
  String? _voiceMemoPath;
  bool _questMode = false;
  List<ChallengeType> _questSteps = [];
  String? _savedQrCode;
  int _stepGoal = 20;

  DayTypeProfile _profile = DayTypeProfile.workday;
  double _sleepGoalHours = 7.5;

  @override
  void initState() {
    super.initState();
    _loadTeenSleepProfile();
  }

  @override
  void dispose() {
    _labelController.dispose();
    _voiceQuickAddController.dispose();
    super.dispose();
  }

  Future<void> _loadTeenSleepProfile() async {
    final profile = await SmartAlarmService.getTeenSleepProfile();
    if (!mounted) {
      return;
    }

    setState(() {
      _sleepGoalHours = profile.targetSleepHours;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 12, 24, bottomInset + 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 86,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4D7DD),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildTimePicker(context),
              const SizedBox(height: 18),
              TextField(
                controller: _labelController,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Alarm label...',
                  hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF94A3B8),
                    fontSize: 20,
                  ),
                  contentPadding: EdgeInsets.zero,
                  border: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Day Type Profile',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: DayTypeProfile.values
                    .map(
                      (profile) => ChoiceChip(
                        label: Text(_profileLabel(profile)),
                        selected: _profile == profile,
                        onSelected: (selected) {
                          if (!selected) return;
                          _applyProfile(profile);
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              Text(
                'Smart Sleep Window',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sleep Goal: ${_sleepGoalHours.toStringAsFixed(1)}h',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Slider(
                      value: _sleepGoalHours,
                      min: 6.0,
                      max: 9.0,
                      divisions: 12,
                      onChanged: (value) =>
                          setState(() => _sleepGoalHours = value),
                    ),
                    Text(
                      'Suggested bedtime: ${_suggestedBedtimeLabel()}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Repeat',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: List.generate(7, (index) {
                  final weekday = index + 1;
                  const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                  final selected = _repeatDays.contains(weekday);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (selected) {
                            _repeatDays.remove(weekday);
                          } else {
                            _repeatDays.add(weekday);
                          }
                        });
                      },
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: selected ? Colors.black : Colors.white,
                          borderRadius: BorderRadius.circular(23),
                          border: Border.all(color: const Color(0xFFD4D7DD)),
                        ),
                        child: Center(
                          child: Text(
                            labels[index],
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF94A3B8),
                                  fontSize: 18,
                                ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: _cycleSound,
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    Text(
                      'Sound',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _soundLabel(),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Alarm Personality',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: AlarmPersonality.values.map((p) {
                    final config = PersonalityConfig.all[p]!;
                    final selected = _personality == p.name;
                    return GestureDetector(
                      onTap: () => setState(() => _personality = p.name),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? config.primaryColor : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected ? config.primaryColor : const Color(0xFFE2E8F0),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(config.emoji, style: const TextStyle(fontSize: 22)),
                            const SizedBox(height: 4),
                            Text(
                              config.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              // Gentle Wake toggle
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gentle Wake', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 18)),
                        Text('Gradually ramp volume over ${_gentleWakeDuration}s with sunrise colors', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  Switch(
                    value: _gentleWake,
                    onChanged: (v) => setState(() => _gentleWake = v),
                    thumbColor: MaterialStatePropertyAll(Colors.white),
                    trackColor: MaterialStateProperty.resolveWith<Color?>((states) =>
                        states.contains(MaterialState.selected)
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFE2E8F0)),
                  ),
                ],
              ),
              if (_gentleWake) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [30, 60, 120].map((s) {
                    final selected = _gentleWakeDuration == s;
                    return ChoiceChip(
                      label: Text('${s}s'),
                      selected: selected,
                      selectedColor: const Color(0xFF22C55E),
                      labelStyle: TextStyle(color: selected ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.w600),
                      onSelected: (_) => setState(() => _gentleWakeDuration = s),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 24),
              // Wake Challenge picker
              Text('Wake Challenge', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 10),
              DropdownButtonFormField<ChallengeType?>(
                value: _challengeType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Math (default)')),
                  ...ChallengeType.values.map((t) => DropdownMenuItem(value: t, child: Text(ChallengeService.label(t)))),
                ],
                onChanged: (v) => setState(() => _challengeType = v),
              ),
              const SizedBox(height: 20),

              // ── Quest Mode toggle ──────────────────────────────────────
              Row(children: [
                const Icon(Icons.rocket_launch_rounded,
                    color: Color(0xFF6366F1), size: 20),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Wake Quest Mode',
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const Text('Chain multiple challenges in order',
                        style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                  ],
                )),
                Switch(
                  value: _questMode,
                  onChanged: (v) => setState(() {
                    _questMode = v;
                    if (v && _questSteps.isEmpty) {
                      _questSteps = [
                        ChallengeType.shakeToWake,
                        ChallengeType.trivia,
                      ];
                    }
                  }),
                  thumbColor: const WidgetStatePropertyAll(Colors.white),
                  trackColor: WidgetStateProperty.resolveWith<Color?>(
                    (s) => s.contains(WidgetState.selected)
                        ? const Color(0xFF6366F1)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
              ]),
              if (_questMode) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.of(context).push<List<ChallengeType>>(
                      MaterialPageRoute(
                        builder: (_) =>
                            QuestBuilderScreen(initialSteps: _questSteps),
                      ),
                    );
                    if (result != null && mounted) {
                      setState(() => _questSteps = result);
                    }
                  },
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: Text(_questSteps.isEmpty
                      ? 'Build Quest'
                      : _questSteps
                          .map((t) => ChallengeService.label(t))
                          .join(' → ')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6366F1),
                    side: const BorderSide(color: Color(0xFF6366F1)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],

              // ── QR Spot (shown when barcodeScan is selected or in quest) ──
              if (_challengeType == ChallengeType.barcodeScan ||
                  (_questMode &&
                      _questSteps.contains(ChallengeType.barcodeScan))) ...[
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final code =
                        await Navigator.of(context).push<String>(
                      MaterialPageRoute(
                          builder: (_) => const QrSpotSetupScreen()),
                    );
                    if (code != null && mounted) {
                      setState(() => _savedQrCode = code);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Row(children: [
                    const Icon(Icons.qr_code_rounded,
                        color: Color(0xFF10B981), size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dismiss Spot',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        Text(
                          _savedQrCode != null
                              ? 'QR spot registered'
                              : 'Scan a sticker to lock the dismiss spot',
                          style: TextStyle(
                            fontSize: 13,
                            color: _savedQrCode != null
                                ? const Color(0xFF10B981)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    )),
                    Icon(
                      _savedQrCode != null
                          ? Icons.check_circle_rounded
                          : Icons.chevron_right_rounded,
                      color: _savedQrCode != null
                          ? const Color(0xFF10B981)
                          : const Color(0xFFCBD5E1),
                    ),
                  ]),
                ),
              ],

              // ── Step goal (shown when stepCounter is selected or in quest) ──
              if (_challengeType == ChallengeType.stepCounter ||
                  (_questMode &&
                      _questSteps.contains(ChallengeType.stepCounter))) ...[
                const SizedBox(height: 16),
                Row(children: [
                  const Icon(Icons.directions_walk_rounded,
                      color: Color(0xFF10B981), size: 20),
                  const SizedBox(width: 10),
                  Text('Steps to dismiss: $_stepGoal',
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ]),
                Slider(
                  value: _stepGoal.toDouble(),
                  min: 10,
                  max: 100,
                  divisions: 18,
                  label: '$_stepGoal steps',
                  activeColor: const Color(0xFF10B981),
                  onChanged: (v) => setState(() => _stepGoal = v.round()),
                ),
              ],

              const SizedBox(height: 24),
              // Voice Memo
              VoiceMemoRecorder(
                initialPath: _voiceMemoPath,
                onMemoSaved: (path) => setState(() => _voiceMemoPath = path),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _voiceQuickAddController,
                decoration: InputDecoration(
                  hintText:
                      'Voice Quick Add text, e.g. wake me at 6:20 for gym tomorrow',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  suffixIcon: TextButton(
                    onPressed: _applyVoiceQuickAdd,
                    child: const Text('Apply'),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    'Set Alarm',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: _setAlarm,
                    onChanged: (value) => setState(() => _setAlarm = value),
                    thumbColor: MaterialStatePropertyAll(Colors.white),
                    trackColor: MaterialStateProperty.resolveWith<Color?>((states) =>
                        states.contains(MaterialState.selected)
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFE2E8F0)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveAlarm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF020617),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 62),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: const Text(
                    'Set Alarm',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _profileLabel(DayTypeProfile profile) {
    switch (profile) {
      case DayTypeProfile.workday:
        return 'Workday';
      case DayTypeProfile.gym:
        return 'Gym';
      case DayTypeProfile.weekend:
        return 'Weekend';
      case DayTypeProfile.travel:
        return 'Travel';
    }
  }

  void _applyProfile(DayTypeProfile profile) {
    final defaults = SmartAlarmService.defaultsForProfile(profile);
    setState(() {
      _profile = profile;
      _hour = _formatHour(defaults.time.hour);
      _minute = defaults.time.minute;
      _isAm = defaults.time.hour < 12;
      _repeatDays
        ..clear()
        ..addAll(defaults.repeatDays);
      _labelController.text = defaults.label;
      _tag = defaults.tag;
    });
  }

  String _suggestedBedtimeLabel() {
    final hour24 = _isAm ? (_hour % 12) : (_hour % 12) + 12;
    final bedtime = SmartAlarmService.suggestBedtime(
      wakeTime: TimeOfDay(hour: hour24, minute: _minute),
      sleepHours: _sleepGoalHours,
    );
    return '${_formatHour(bedtime.hour)}:${bedtime.minute.toString().padLeft(2, '0')} ${bedtime.hour >= 12 ? 'PM' : 'AM'}';
  }

  String _soundLabel() {
    switch (_sound) {
      case 'rotate':
        return 'Rotate Daily';
      case 'default':
      default:
        return 'Default Ringtone';
    }
  }

  void _cycleSound() {
    if (_sound == 'default') {
      _requirePremium(PremiumFeature.rotatingAlarmSounds).then((allowed) {
        if (!allowed || !mounted) {
          return;
        }

        setState(() => _sound = 'rotate');
      });
      return;
    }

    setState(() => _sound = 'default');
  }

  void _applyVoiceQuickAdd() {
    final parsed = SmartAlarmService.parseQuickAdd(
      _voiceQuickAddController.text,
    );
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not parse quick add text.')),
      );
      return;
    }

    setState(() {
      _hour = _formatHour(parsed.hour24);
      _minute = parsed.minute;
      _isAm = parsed.hour24 < 12;
      _labelController.text = parsed.label;
      _tag = parsed.dayOffset > 0
          ? 'Quick add for tomorrow'
          : 'Quick add for today';
      if (parsed.dayOffset > 0) {
        final tomorrow = DateTime.now().add(const Duration(days: 1)).weekday;
        _repeatDays
          ..clear()
          ..add(tomorrow);
      }
    });
  }

  int _formatHour(int hour24) {
    final normalized = hour24 % 12;
    return normalized == 0 ? 12 : normalized;
  }

  Widget _buildTimePicker(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _pickerNumber(
          value: _hour,
          min: 1,
          max: 12,
          onChanged: (value) => setState(() => _hour = value),
        ),
        const SizedBox(width: 16),
        Text(
          ':',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontSize: 78,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 16),
        _pickerNumber(
          value: _minute,
          min: 0,
          max: 59,
          onChanged: (value) => setState(() => _minute = value),
        ),
        const SizedBox(width: 20),
        Column(
          children: [
            _periodButton(
              label: 'AM',
              active: _isAm,
              onTap: () => setState(() => _isAm = true),
            ),
            const SizedBox(height: 8),
            _periodButton(
              label: 'PM',
              active: !_isAm,
              onTap: () => setState(() => _isAm = false),
            ),
          ],
        ),
      ],
    );
  }

  Widget _pickerNumber({
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      children: [
        IconButton(
          onPressed: () {
            final next = value + 1 > max ? min : value + 1;
            onChanged(next);
          },
          icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 28),
        ),
        Text(
          value.toString().padLeft(2, '0'),
          style: const TextStyle(fontSize: 66, fontWeight: FontWeight.w700),
        ),
        IconButton(
          onPressed: () {
            final next = value - 1 < min ? max : value - 1;
            onChanged(next);
          },
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
        ),
      ],
    );
  }

  Widget _periodButton({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: active ? Colors.black : const Color(0xFFB0B0B0),
        ),
      ),
    );
  }

  Future<void> _saveAlarm() async {
    try {
      final hour24 = _isAm ? (_hour % 12) : (_hour % 12) + 12;

      await SmartAlarmService.saveTeenSleepProfile(
        targetSleepHours: _sleepGoalHours,
      );

      await ref
          .read(alarmsMapProvider.notifier)
          .addAlarm(
            time: TimeOfDay(hour: hour24, minute: _minute),
            label: _labelController.text.trim().isEmpty
                ? 'Work Morning'
                : _labelController.text.trim(),
            repeatDays: _repeatDays.toList()..sort(),
            isEnabled: _setAlarm,
            tag: _tag,
            sound: _sound,
            personality: _personality,
            gentleWake: _gentleWake,
            gentleWakeDurationSeconds: _gentleWakeDuration,
            challengeType: _challengeType,
            voiceMemoPath: _voiceMemoPath,
            stepGoal: _stepGoal,
            savedQrCode: _savedQrCode,
            questMode: _questMode,
            questSteps: _questMode ? _questSteps : null,
          );

      if (!mounted) {
        return;
      }

      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error saving alarm: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save alarm: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<bool> _requirePremium(PremiumFeature feature) async {
    if (await PremiumService.canUse(feature)) {
      return true;
    }

    if (!mounted) {
      return false;
    }

    return PremiumService.showLifetimePaywall(context, feature);
  }
}
