// ==============================================================================
// NIRVANA - 7-Day Activity View Widget
// Description: Simple, non-clinical visualization displaying daily completed
// games and reminders for the past week.
// ==============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
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

        final maxTotal = days.map((d) => d.totalActivities).fold<int>(1, math.max);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '7-Day Activity View',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ElderColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      const _LegendIndicator(color: ElderColors.primary, label: 'Games'),
                      const SizedBox(width: 12),
                      _LegendIndicator(color: Colors.amber[700]!, label: 'Reminders'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 140,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: days.map((day) {
                    final gamesHeightFraction = (day.gamesCompleted / maxTotal).clamp(0.0, 1.0);
                    final remindersHeightFraction = (day.remindersCompleted / maxTotal).clamp(0.0, 1.0);

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${day.totalActivities}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Stacked bar
                            Column(
                              children: [
                                Container(
                                  height: (80.0 * remindersHeightFraction).toDouble(),
                                  width: 18,
                                  decoration: BoxDecoration(
                                    color: Colors.amber[700],
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                  ),
                                ),
                                Container(
                                  height: (80.0 * gamesHeightFraction).toDouble(),
                                  width: 18,
                                  decoration: const BoxDecoration(
                                    color: ElderColors.primary,
                                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              day.dayLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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
      loading: () => const SizedBox(height: 160, child: Center(child: CircularProgressIndicator())),
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
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
