import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alarm_plus/features/alarm/models/alarm_model.dart';
import 'package:alarm_plus/features/sleep/models/bedtime_schedule.dart';
import 'package:alarm_plus/features/alarm/services/alarm_providers.dart';
import 'package:alarm_plus/features/alarm/services/alarm_service.dart';
import 'package:alarm_plus/features/sleep/services/bedtime_service.dart';
import 'package:alarm_plus/features/focus/services/nap_service.dart';
import 'package:alarm_plus/core/services/premium_service.dart';
import 'package:alarm_plus/features/sleep/services/sleep_analytics_service.dart';
import 'package:alarm_plus/core/services/smart_alarm_service.dart';
import 'package:alarm_plus/shared/widgets/alarm_card.dart';
import 'package:alarm_plus/features/alarm/screens/alarms_screen.dart';
import 'package:alarm_plus/features/sleep/screens/bedtime_setup_screen.dart';
import 'package:alarm_plus/features/focus/screens/focus_timer_screen.dart';
import 'package:alarm_plus/features/missions/screens/morning_missions_screen.dart';
import 'package:alarm_plus/features/focus/screens/nap_timer_screen.dart';
import 'package:alarm_plus/features/sleep/screens/sleep_insights_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarmsAsync = ref.watch(alarmsListProvider);

    return SafeArea(
      child: alarmsAsync.when(
        data: (alarms) => ListView(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
          children: [
            Row(
              children: [
                Text(
                  'Alarm+',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 30,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AlarmsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 34),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Streak / XP hero widget
            FutureBuilder<(AlarmStats, int)>(
              future: Future.wait([
                SmartAlarmService.getStats(),
                SmartAlarmService.getXp(),
              ]).then((r) => (r[0] as AlarmStats, r[1] as int)),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox(height: 80);
                final (stats, xp) = snapshot.data!;
                return _StreakHeroWidget(
                  stats: stats,
                  xp: xp,
                  onTap: () =>
                      ref.read(currentTabIndexProvider.notifier).state = 1,
                );
              },
            ),
            const SizedBox(height: 16),
            // Morning Missions card
            FutureBuilder<List<dynamic>>(
              future: SmartAlarmService.getTodayMissions(),
              builder: (context, snap) {
                if (!snap.hasData) return const SizedBox.shrink();
                final missions = snap.data!;
                final completed = missions.where((m) => (m as dynamic).isCompleted == true).length;
                final total = missions.length;
                if (total == 0) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed(MorningMissionsScreen.routeName),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: completed == total ? const Color(0xFFF0FDF4) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: completed == total ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Text('🌅', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Morning Missions',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                              Text('$completed/$total completed · +${completed * 15} XP earned',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                            ],
                          ),
                        ),
                        Row(
                          children: List.generate(total, (i) => Container(
                            width: 10, height: 10,
                            margin: const EdgeInsets.only(left: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i < completed ? const Color(0xFF22C55E) : const Color(0xFFE2E8F0),
                            ),
                          )),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              'YOUR TODAY',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(letterSpacing: 2.8),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x070F172A),
                    blurRadius: 14,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: _buildTodayTiles(context, alarms),
              ),
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                Text(
                  'UPCOMING ALARMS',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(letterSpacing: 2.8),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AlarmsScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'View all',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...alarms
                .take(2)
                .map(
                  (alarm) => AlarmCard(
                    alarm: alarm,
                    onToggle: (value) => ref
                        .read(alarmsMapProvider.notifier)
                        .toggleAlarm(alarm.id, value),
                  ),
                ),
            FutureBuilder<SleepCoachSnapshot>(
              future: SmartAlarmService.buildSleepCoachSnapshot(alarms),
              builder: (context, snapshot) {
                final coach = snapshot.data;
                return FutureBuilder<bool>(
                  future: PremiumService.canUse(PremiumFeature.sleepCoachPro),
                  builder: (context, premiumSnapshot) {
                    final unlocked = premiumSnapshot.data ?? false;
                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F6),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFFECEFF3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.lightbulb_outline_rounded,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Smart Suggestion',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  unlocked
                                      ? (coach?.headline ??
                                            'Enable an alarm to generate your personalised sleep target.')
                                      : 'Unlock Lifetime Premium for ₹299 to get teen sleep debt, weekend drift guard, and bedtime coaching.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    unlocked
                                        ? (coach == null
                                              ? 'Sleep coach loading'
                                              : 'Consistency ${coach.consistencyScore}%')
                                        : 'Premium feature',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF475569),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 22),
            FutureBuilder<SleepCoachSnapshot>(
              future: SmartAlarmService.buildSleepCoachSnapshot(alarms),
              builder: (context, coachSnapshot) {
                final coach = coachSnapshot.data;
                return FutureBuilder<bool>(
                  future: PremiumService.canUse(PremiumFeature.sleepCoachPro),
                  builder: (context, premiumSnapshot) {
                    final unlocked = premiumSnapshot.data ?? false;
                    return FutureBuilder<PremiumSleepSnapshot>(
                      future: SmartAlarmService.buildPremiumSleepSnapshot(
                        alarms,
                      ),
                      builder: (context, premiumSleepSnapshot) {
                        final premiumSleep = premiumSleepSnapshot.data;
                        return Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mood + Sleep Check-In',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                unlocked
                                    ? (premiumSleep?.recoveryHeadline ??
                                          coach?.recommendation ??
                                          'Quick daily check-in can auto-adjust your next alarm.')
                                    : 'Check in for free. Unlock premium to auto-tune alarms, recovery days, and weekend drift guard.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          _showMoodCheckIn(context),
                                      child: const Text('Check In'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      unlocked && premiumSleep != null
                                          ? 'Recovery: ${premiumSleep.recoveryIntensity} · Drift ${premiumSleep.weekendDriftMinutes} min'
                                          : 'Wind-down: ${SmartAlarmService.windDownChecklist().first}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(letterSpacing: 0),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 22),
            // Sleep Insights summary card
            FutureBuilder<int>(
              future: SleepAnalyticsService.weeklyScore(),
              builder: (context, snap) {
                final score = snap.data ?? 0;
                final label = SleepAnalyticsService.scoreLabel(score);
                final color = score >= 80
                    ? const Color(0xFF22C55E)
                    : score >= 60
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFEF4444);
                return GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed(SleepInsightsScreen.routeName),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Text('😴', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Sleep Insights', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                              Text(
                                snap.hasData
                                    ? 'Weekly score $score · $label'
                                    : 'Tap to view your sleep trends',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                        if (snap.hasData)
                          Text(
                            '$score',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color),
                          ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Nap Timer card
            FutureBuilder<bool>(
              future: NapService.isNapActive(),
              builder: (context, napSnap) {
                final napActive = napSnap.data ?? false;
                return GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed(NapTimerScreen.routeName),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1e3a5f).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF1e3a5f).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Text('💤', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Nap Timer',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                              Text(
                                napActive
                                    ? 'Nap in progress · tap to manage'
                                    : '20 · 45 · 90 min presets',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: Color(0xFFCBD5E1), size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Sleep Diary card
            GestureDetector(
              onTap: () => Navigator.of(context).pushNamed('/sleep-diary'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Text('📓', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sleep Diary',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          Text('Log last night\'s sleep',
                              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: Color(0xFFCBD5E1), size: 20),
                  ],
                ),
              ),
            ),
            // Bedtime / Wind Down card
            FutureBuilder<BedtimeSchedule?>(
              future: BedtimeService.load(),
              builder: (context, snap) {
                final schedule = snap.data;
                return GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed(BedtimeSetupScreen.routeName),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0f172a).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Text('🌙', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Wind Down', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                              Text(
                                schedule != null && schedule.isEnabled
                                    ? 'Bedtime ${BedtimeService.nextBedtimeLabel(schedule)} · ${schedule.windDownMinutes}min wind-down'
                                    : 'Set up your bedtime routine',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/wake-routine');
                    },
                    icon: const Icon(Icons.wb_sunny_outlined),
                    label: const Text('Wake Routine'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pushNamed(FocusTimerScreen.routeName);
                    },
                    icon: const Icon(Icons.timer_outlined),
                    label: const Text('Start Focus'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ].animate(interval: 70.ms).fadeIn(duration: 240.ms).move(
            begin: const Offset(0, 8),
            end: Offset.zero,
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  List<Widget> _buildTodayTiles(BuildContext context, List<AlarmModel> alarms) {
    final today = DateTime.now().weekday; // 1=Mon … 7=Sun
    final now = DateTime.now();

    final todayAlarms = alarms.where((alarm) {
      if (!alarm.isEnabled) return false;
      if (alarm.repeatDays.isEmpty) {
        final next = alarm.nextDateTimeFrom(now);
        return next.year == now.year &&
            next.month == now.month &&
            next.day == now.day;
      }
      return alarm.repeatDays.contains(today);
    }).toList()
      ..sort(
        (a, b) => (a.time.hour * 60 + a.time.minute)
            .compareTo(b.time.hour * 60 + b.time.minute),
      );

    if (todayAlarms.isEmpty) {
      return [
        const _TimelineTile(
          time: '--:--',
          title: 'Rest day',
          subtitle: 'No alarms scheduled for today',
        ),
      ];
    }

    final tiles = <Widget>[];
    for (final alarm in todayAlarms.take(2)) {
      tiles.add(
        _TimelineTile(
          time: alarm.timeLabel,
          title: alarm.label.isEmpty ? 'Wake Alarm' : alarm.label,
          subtitle: '${alarm.periodLabel} · ${alarm.repeatLabel}',
        ),
      );
    }

    tiles.add(
      const _TimelineTile(
        time: '+25m',
        title: 'Focus Sprint',
        subtitle: 'Suggested after wake — tap Start Focus',
      ),
    );

    return tiles;
  }

  Future<void> _showMoodCheckIn(BuildContext context) async {
    var energy = 3.0;
    var mood = 3.0;
    var sleep = 3.0;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Morning Check-In'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sliderRow('Energy', energy, (v) => setState(() => energy = v)),
              _sliderRow('Mood', mood, (v) => setState(() => mood = v)),
              _sliderRow('Sleep', sleep, (v) => setState(() => sleep = v)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) {
      return;
    }

    await SmartAlarmService.saveMoodCheckIn(
      energy: energy.round(),
      mood: mood.round(),
      sleepQuality: sleep.round(),
    );

    // Check for newly unlocked badges after mood check-in
    final stats = await SmartAlarmService.getStats();
    final newBadges = await SmartAlarmService.checkAndUnlockBadges(stats);

    var tuned = false;
    try {
      final canTune = await PremiumService.canUse(
        PremiumFeature.adaptiveAlarmTuning,
      );
      if (canTune) {
        tuned = await AlarmService.autoAdjustNextAlarmFromMood(
          energy: energy.round(),
          sleepQuality: sleep.round(),
        );
      }
    } catch (_) {}

    if (!context.mounted) {
      return;
    }

    if (newBadges.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Badge unlocked: ${SmartAlarmService.badgeDisplayName(newBadges.first) ?? newBadges.first}!',
          ),
          backgroundColor: const Color(0xFF0F172A),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tuned
                ? 'Check-in saved. Next alarm tuned. +20 XP'
                : 'Check-in saved. +20 XP',
          ),
        ),
      );
    }
  }

  Widget _sliderRow(
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.round()} / 5'),
        Slider(
          value: value,
          min: 1,
          max: 5,
          divisions: 4,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _StreakHeroWidget extends StatelessWidget {
  const _StreakHeroWidget({
    required this.stats,
    required this.xp,
    required this.onTap,
  });

  final AlarmStats stats;
  final int xp;
  final VoidCallback onTap;

  String _fireEmoji(int streak) {
    if (streak >= 30) return '🔥🔥🔥';
    if (streak >= 7) return '🔥🔥';
    if (streak >= 3) return '🔥';
    return '⭐';
  }

  @override
  Widget build(BuildContext context) {
    final streak = stats.currentStreak;
    final label = SmartAlarmService.levelLabel(xp);
    final progress = SmartAlarmService.xpLevelProgress(xp);
    final toNext = SmartAlarmService.xpToNextLevel(xp);
    final isHot = streak >= 3;
    final nextMilestone = SmartAlarmService.getStreakMilestoneNext(streak);
    final milestoneProgress = streak / nextMilestone;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isHot
                ? [const Color(0xFFFFF7ED), const Color(0xFFFEF3C7)]
                : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isHot ? const Color(0xFFFED7AA) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(_fireEmoji(streak), style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$streak',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: isHot ? const Color(0xFFEA580C) : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'day streak',
                            style: TextStyle(
                              fontSize: 14,
                              color: isHot ? const Color(0xFFEA580C) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      Text(label,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isHot ? const Color(0xFFF97316) : const Color(0xFF22C55E)),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text('$xp XP · $toNext to next level',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$streak / $nextMilestone days to milestone',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: milestoneProgress.clamp(0.0, 1.0),
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FutureBuilder<int>(
                  future: SmartAlarmService.getStreakFreezesOwned(),
                  builder: (ctx, snap) {
                    final freezes = snap.data ?? 0;
                    if (freezes == 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Text('🧊 ×$freezes',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8))),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.time,
    required this.title,
    required this.subtitle,
  });

  final String time;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(
            time,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 14),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
