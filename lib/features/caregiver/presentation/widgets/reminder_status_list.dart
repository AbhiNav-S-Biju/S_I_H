// ==============================================================================
// NIRVANA - Reminder Status List Widget
// Description: Displays active reminders and adherence logs for the selected loved one.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/features/caregiver/providers/caregiver_providers.dart';

class ReminderStatusList extends ConsumerWidget {
  const ReminderStatusList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(selectedPatientRemindersProvider);

    return remindersAsync.when(
      data: (reminders) {
        if (reminders.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.alarm_on_outlined, size: 40, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'No reminders scheduled for this loved one.',
                    style: TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
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
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reminders.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
            itemBuilder: (context, index) {
              final reminder = reminders[index];

              final isCompleted = reminder.isCompleted;
              final isSnoozed = reminder.snoozedUntil != null && !isCompleted;

              Color statusColor = isCompleted
                  ? Colors.green
                  : (isSnoozed ? Colors.amber[800]! : Colors.blueGrey);

              String statusLabel = isCompleted
                  ? 'Completed'
                  : (isSnoozed ? 'Snoozed' : 'Scheduled');

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: CircleAvatar(
                  backgroundColor: statusColor.withValues(alpha: 0.12),
                  child: Icon(
                    isCompleted
                        ? Icons.check
                        : (isSnoozed ? Icons.snooze : Icons.alarm),
                    color: statusColor,
                  ),
                ),
                title: Text(
                  reminder.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: ElderColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  _formatReminderSubtitle(reminder),
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Text('Error loading reminder status: $e'),
    );
  }

  static String _formatReminderSubtitle(dynamic reminder) {
    final sched = reminder.scheduledAt;
    final timeStr = '${sched.hour.toString().padLeft(2, '0')}:${sched.minute.toString().padLeft(2, '0')}';
    if (reminder.isCompleted && reminder.completedAt != null) {
      final comp = reminder.completedAt!;
      final compTime = '${comp.hour.toString().padLeft(2, '0')}:${comp.minute.toString().padLeft(2, '0')}';
      return 'Scheduled: $timeStr • Completed at $compTime';
    }
    return 'Scheduled for $timeStr';
  }
}
