import 'package:flutter/material.dart';

import 'package:alarm_plus/features/alarm/models/alarm_model.dart';

class AlarmCard extends StatelessWidget {
  const AlarmCard({
    super.key,
    required this.alarm,
    required this.onToggle,
    this.onDelete,
  });

  final AlarmModel alarm;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final card = _buildCard(context);
    if (onDelete == null) return card;

    return Dismissible(
      key: ValueKey(alarm.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 28),
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Alarm?'),
          content: Text(
            '${alarm.timeLabel} ${alarm.periodLabel}${alarm.label.isNotEmpty ? ' — ${alarm.label}' : ''} will be permanently removed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
      onDismissed: (_) => onDelete!(),
      child: card,
    );
  }

  Widget _buildCard(BuildContext context) {
    final color = alarm.isEnabled
        ? Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF0F172A)
        : const Color(0xFF94A3B8);

    final cardBg = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E293B)
        : Colors.white;
    final borderColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor),
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
                thumbColor: WidgetStateProperty.resolveWith<Color?>((states) =>
                    states.contains(WidgetState.selected)
                        ? Colors.white
                        : const Color(0xFFE2E8F0)),
                trackColor: WidgetStateProperty.resolveWith<Color?>((states) =>
                    states.contains(WidgetState.selected)
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
              const Spacer(),
              if (onDelete != null)
                GestureDetector(
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Alarm?'),
                        content: Text(
                          '${alarm.timeLabel} ${alarm.periodLabel}${alarm.label.isNotEmpty ? ' — ${alarm.label}' : ''} will be permanently removed.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) onDelete!();
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.delete_outline_rounded, color: Color(0xFFCBD5E1), size: 20),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
