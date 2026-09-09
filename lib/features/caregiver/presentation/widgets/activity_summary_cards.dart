// ==============================================================================
// NIRVANA - Activity Summary Cards Widget
// Description: Metric cards displaying Games completed, Reminder completion,
// and Activities completed. Uses supportive non-clinical language and clay styling.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/app/widgets/widgets.dart';
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
            icon: Icons.extension_rounded,
            clayColor: ElderColors.clayLavender,
            subtitle: 'Sessions',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryMetricCard(
            title: 'Reminder completion',
            value: totalRemindersCount > 0
                ? '$remindersCompletedCount/$totalRemindersCount'
                : '$remindersCompletedCount',
            icon: Icons.check_circle_rounded,
            clayColor: ElderColors.claySage,
            subtitle: 'Today\'s routine',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryMetricCard(
            title: 'Activities completed',
            value: '$totalActivities',
            icon: Icons.auto_awesome_rounded,
            clayColor: ElderColors.clayButtercup,
            subtitle: 'Total done',
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
  final Color clayColor;
  final String subtitle;

  const _SummaryMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.clayColor,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ElderCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      backgroundColor: ElderColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: clayColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(NirvanaRadii.icon),
            ),
            child: Icon(icon, color: clayColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: ElderColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ElderColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: ElderColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
