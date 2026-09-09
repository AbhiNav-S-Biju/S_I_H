// ==============================================================================
// NIRVANA - Patient Reminders Screen
// Description: Senior-accessible daily routine and reminder checklist.
// Operates 100% offline via Hive with automated SyncEngine background sync.
// Features large touch targets (>56dp), high-contrast text, and simple Done /
// Snooze / Later actions for elderly loved ones.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/database/hive_database.dart';
import 'package:nirvana/features/caregiver/providers/caregiver_providers.dart';
import 'package:nirvana/features/patient/providers/patient_pairing_providers.dart';
import 'package:nirvana/features/reminders/models/reminder.dart';
import 'package:nirvana/features/reminders/providers/reminder_providers.dart';

class PatientRemindersScreen extends ConsumerWidget {
  const PatientRemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(localPatientSessionProvider);
    final patientId = session?.patientId ?? HiveDatabase.pairedPatientId ?? '';

    // Watch reminders for this patient from the offline-first Hive repository
    final remindersAsync = ref.watch(activeRemindersProvider(patientId));

    return Scaffold(
      backgroundColor: ElderColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 28, color: ElderColors.textPrimary),
          tooltip: 'Back to Home',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/patient/home');
            }
          },
        ),
        title: const Text(
          'My Daily Reminders',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: ElderColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 26, color: ElderColors.textPrimary),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(activeRemindersProvider(patientId)),
          ),
        ],
      ),
      body: SafeArea(
        child: remindersAsync.when(
          data: (reminders) {
            // Also check all reminders in Hive box (including completed ones for today)
            final allReminders = HiveDatabase.remindersBox.values.where((r) {
              return (patientId.isEmpty || r.patientId == patientId) && r.isActive;
            }).map(Reminder.fromHive).toList();

            allReminders.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

            final completedCount = allReminders.where((r) => r.isCompleted).length;
            final totalCount = allReminders.length;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Motivational Progress Header
                  _ProgressBanner(
                    completedCount: completedCount,
                    totalCount: totalCount,
                  ),
                  const SizedBox(height: 24),

                  // 2. Reminders Header
                  Text(
                    'Today\'s Schedule',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: ElderColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. Reminders List
                  if (allReminders.isEmpty)
                    const _EmptyRemindersCard()
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: allReminders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final reminder = allReminders[index];
                        return _PatientReminderCard(
                          reminder: reminder,
                          patientId: patientId,
                        );
                      },
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load reminders: $e',
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==============================================================================
// Motivational Progress Banner
// ==============================================================================
class _ProgressBanner extends StatelessWidget {
  final int completedCount;
  final int totalCount;

  const _ProgressBanner({
    required this.completedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = totalCount > 0 ? (completedCount / totalCount) : 1.0;
    final allDone = totalCount > 0 && completedCount >= totalCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: allDone ? const Color(0xFFE8F5E9) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: allDone
              ? const Color(0xFF81C784)
              : Colors.grey.withValues(alpha: 0.2),
          width: allDone ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                allDone ? Icons.celebration : Icons.checklist_rounded,
                size: 28,
                color: allDone ? const Color(0xFF2E7D32) : ElderColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  allDone
                      ? 'All caught up for today! 🎉'
                      : '$completedCount of $totalCount Completed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: allDone
                        ? const Color(0xFF2E7D32)
                        : ElderColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.grey.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(
                allDone ? const Color(0xFF2E7D32) : ElderColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            allDone
                ? 'Great job keeping up with your health routines today.'
                : 'Take your time and complete each activity as scheduled.',
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// Patient Reminder Card
// ==============================================================================
class _PatientReminderCard extends ConsumerWidget {
  final Reminder reminder;
  final String patientId;

  const _PatientReminderCard({
    required this.reminder,
    required this.patientId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = reminder.isCompleted;
    final isSnoozed = reminder.snoozedUntil != null && !isCompleted;

    final hour = reminder.scheduledAt.hour;
    final minute = reminder.scheduledAt.minute;
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final period = hour >= 12 ? 'PM' : 'AM';
    final minuteStr = minute.toString().padLeft(2, '0');
    final formattedTime = '$displayHour:$minuteStr $period';

    return Container(
      decoration: BoxDecoration(
        color: isCompleted
            ? const Color(0xFFF1F8E9)
            : (isSnoozed ? const Color(0xFFFFF8E1) : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFFA5D6A7)
              : (isSnoozed
                  ? const Color(0xFFFFE082)
                  : Colors.grey.withValues(alpha: 0.2)),
          width: isCompleted || isSnoozed ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: Icon, Time, Status Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFFC8E6C9)
                      : (isSnoozed
                          ? const Color(0xFFFFECB3)
                          : ElderColors.primaryContainer),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_circle_rounded
                      : (isSnoozed ? Icons.snooze_rounded : Icons.alarm_rounded),
                  size: 30,
                  color: isCompleted
                      ? const Color(0xFF2E7D32)
                      : (isSnoozed
                          ? const Color(0xFFE65100)
                          : ElderColors.primary),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formattedTime,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: ElderColors.textPrimary,
                      ),
                    ),
                    if (isCompleted && reminder.completedAt != null)
                      Text(
                        'Completed today',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[800],
                        ),
                      )
                    else if (isSnoozed && reminder.snoozedUntil != null)
                      Text(
                        'Snoozed until ${_formatTimeOfDay(reminder.snoozedUntil!)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber[900],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Title
          Text(
            reminder.title,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: isCompleted ? Colors.grey[700] : ElderColors.textPrimary,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),

          // Description / instructions
          if (reminder.body.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              reminder.body,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 18),

          // Action Buttons
          if (!isCompleted) ...[
            Row(
              children: [
                // DONE BUTTON (Big green accessible button)
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final repo = ref.read(reminderRepositoryProvider);
                      final notif = ref.read(notificationServiceProvider);

                      await repo.completeReminder(
                        reminder.id,
                        patientId: patientId,
                      );
                      await notif.cancelReminder(reminder.notificationId);

                      ref.invalidate(activeRemindersProvider(patientId));
                      ref.invalidate(selectedPatientRemindersProvider);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Wonderful! "${reminder.title}" marked as complete. 🌟',
                              style: const TextStyle(fontSize: 16),
                            ),
                            backgroundColor: const Color(0xFF2E7D32),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_rounded, size: 28),
                    label: const Text(
                      'Done',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // SNOOZE BUTTON
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final repo = ref.read(reminderRepositoryProvider);
                      await repo.snoozeReminder(
                        reminder.id,
                        delay: const Duration(minutes: 15),
                        patientId: patientId,
                      );

                      ref.invalidate(activeRemindersProvider(patientId));
                      ref.invalidate(selectedPatientRemindersProvider);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Snoozed "${reminder.title}" for 15 minutes. ⏰',
                              style: const TextStyle(fontSize: 15),
                            ),
                            backgroundColor: const Color(0xFFE65100),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.snooze_rounded, size: 20),
                    label: const Text(
                      '15 min',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE65100),
                      side: const BorderSide(color: Color(0xFFE65100), width: 1.5),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, size: 18, color: Color(0xFF2E7D32)),
                  SizedBox(width: 6),
                  Text(
                    'All completed for this schedule',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatTimeOfDay(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final period = hour >= 12 ? 'PM' : 'AM';
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $period';
  }
}

// ==============================================================================
// Empty State
// ==============================================================================
class _EmptyRemindersCard extends StatelessWidget {
  const _EmptyRemindersCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ElderColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bedtime_outlined,
              size: 40,
              color: ElderColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No reminders for today',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ElderColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You are all caught up. Have a peaceful, restful day! 🌸',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}
