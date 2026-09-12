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

    // Lay the metric cards out in a responsive row that collapses to a single
    // column only on genuinely tiny screens so the numbers never get squeezed.
    //
    // NOTE: [constraints.maxWidth] here is the CONTENT width, already reduced by
    // the dashboard ListView's horizontal padding (20px each side). A 360dp
    // phone therefore reports ~320px, so the threshold must be well below 360 —
    // otherwise three cards needlessly stack into a tall column on every common
    // phone. Three cards of ~100px only start to crowd below ~320px of content.
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 300;
        final cards = [
          _SummaryMetricCard(
            title: 'Games completed',
            value: '$gamesCount',
            icon: Icons.extension_rounded,
            clayColor: ElderColors.clayLavender,
            subtitle: 'Sessions',
          ),
          _SummaryMetricCard(
            title: 'Reminder completion',
            value: totalRemindersCount > 0
                ? '$remindersCompletedCount/$totalRemindersCount'
                : '$remindersCompletedCount',
            icon: Icons.check_circle_rounded,
            clayColor: ElderColors.claySage,
            subtitle: 'Today\'s routine',
          ),
          _SummaryMetricCard(
            title: 'Activities completed',
            value: '$totalActivities',
            icon: Icons.auto_awesome_rounded,
            clayColor: ElderColors.clayButtercup,
            subtitle: 'Total done',
          ),
        ];

        if (isNarrow) {
          return Column(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                cards[i],
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: cards[i]),
            ],
          ],
        );
      },
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      backgroundColor: ElderColors.surface,
      // Content-sized: the card grows taller if a title wraps, rather than
      // clipping the label. mainAxisSize.min + a tight cross-axis keeps the
      // three cards the same height when they sit in a Row.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: clayColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(NirvanaRadii.icon),
            ),
            child: Icon(icon, color: clayColor, size: 20),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: ElderColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          // Titles wrap to two lines at ~100px card width instead of being
          // truncated to an unreadable stub.
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: ElderColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.2,
              color: ElderColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
