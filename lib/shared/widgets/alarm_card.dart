import 'package:flutter/material.dart';

import 'package:alarm_plus/features/alarm/models/alarm_model.dart';

class AlarmCard extends StatelessWidget {
  const AlarmCard({super.key, required this.alarm, required this.onToggle});

  final AlarmModel alarm;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final color = alarm.isEnabled
        ? const Color(0xFF0F172A)
        : const Color(0xFF94A3B8);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 66,
                        fontWeight: FontWeight.w400,
                        color: color,
                        height: 0.95,
                      ),
                      children: [
                        TextSpan(text: alarm.timeLabel),
                        TextSpan(
                          text: ' ${alarm.periodLabel}',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontSize: 40,
                            fontWeight: FontWeight.w400,
                            color: color.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Switch(
                value: alarm.isEnabled,
                onChanged: onToggle,
                thumbColor: MaterialStateProperty.resolveWith<Color?>((states) =>
                    states.contains(MaterialState.selected)
                        ? Colors.white
                        : const Color(0xFFE2E8F0)),
                trackColor: MaterialStateProperty.resolveWith<Color?>((states) =>
                    states.contains(MaterialState.selected)
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFF1F5F9)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (alarm.tag.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    alarm.tag,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Text(
                alarm.repeatLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
