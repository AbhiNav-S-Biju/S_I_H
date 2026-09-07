// ==============================================================================
// NIRVANA - Activity Summary Cards Widget
// Description: Metric cards displaying Games completed, Reminder completion,
// and Activities completed. Uses supportive non-clinical language.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/features/caregiver/providers/caregiver_providers.dart';

class ActivitySummaryCards extends ConsumerWidget {
  const ActivitySummaryCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamesAsync = ref.watch(selectedPatientGameHistoryProvider);
    final remindersAsync = ref.watch(selectedPatientRemindersProvider);

    final gamesCount = gamesAsync.maybeWhen(
      data: (games) => games.length,
      orElse: () => 0,
    );

    final remindersCompletedCount = remindersAsync.maybeWhen(
      data: (reminders) => reminders.where((r) => r.isCompleted).length,
      orElse: () => 0,
    );

    final totalRemindersCount = remindersAsync.maybeWhen(
      data: (reminders) => reminders.length,
      orElse: () => 0,
    );

    final totalActivities = gamesCount + remindersCompletedCount;

    return Row(
      children: [
        Expanded(
          child: _SummaryMetricCard(
            title: 'Games completed',
            value: '$gamesCount',
            icon: Icons.extension_outlined,
            color: ElderColors.primary,
            subtitle: 'Recent sessions',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryMetricCard(
            title: 'Reminder completion',
            value: totalRemindersCount > 0
                ? '$remindersCompletedCount / $totalRemindersCount'
                : '$remindersCompletedCount',
            icon: Icons.check_circle_outline,
            color: Colors.teal[700]!,
            subtitle: 'Today\'s routine',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryMetricCard(
            title: 'Activities completed',
            value: '$totalActivities',
            icon: Icons.auto_awesome_outlined,
            color: Colors.amber[800]!,
            subtitle: 'Total recorded',
          ),
        ),
      ],
    );
  }
}

class _SummaryMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _SummaryMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ElderColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
