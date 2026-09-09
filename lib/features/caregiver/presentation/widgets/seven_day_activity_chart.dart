// ==============================================================================
// NIRVANA - 7-Day Activity View Widget
// Description: Simple, non-clinical visualization displaying daily completed
// games and reminders for the past week with clay styling.
// ==============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/app/widgets/widgets.dart';
import 'package:nirvana/features/caregiver/providers/caregiver_providers.dart';

class SevenDayActivityChart extends ConsumerWidget {
  const SevenDayActivityChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(selectedPatientSevenDayActivityProvider);

    return activityAsync.when(
      data: (days) {
        if (days.isEmpty) {
          return const Center(child: Text('No activity data recorded yet.'));
        }

        final maxTotal = days
            .map((d) => d.totalActivities)
            .fold<int>(1, math.max);

        return ElderCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    '7-Day Activity View',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: ElderColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      _LegendIndicator(
                        color: ElderColors.clayLavender,
                        label: 'Games',
                      ),
                      SizedBox(width: 12),
                      _LegendIndicator(
                        color: ElderColors.claySage,
                        label: 'Reminders',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 150,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: days.map((day) {
                    final gamesHeightFraction = (day.gamesCompleted / maxTotal)
                        .clamp(0.0, 1.0);
                    final remindersHeightFraction =
                        (day.remindersCompleted / maxTotal).clamp(0.0, 1.0);

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${day.totalActivities}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: ElderColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Stacked rounded pill bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Column(
                                children: [
                                  Container(
                                    height: (80.0 * remindersHeightFraction)
                                        .toDouble(),
                                    width: 20,
                                    color: ElderColors.claySage,
                                  ),
                                  Container(
                                    height: (80.0 * gamesHeightFraction)
                                        .toDouble(),
                                    width: 20,
                                    color: ElderColors.clayLavender,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              day.dayLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: ElderColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator(color: ElderColors.clayLavender)),
      ),
      error: (e, _) => Text('Error loading 7-day activity: $e'),
    );
  }
}

class _LegendIndicator extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendIndicator({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: ElderColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
