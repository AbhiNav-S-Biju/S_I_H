// ==============================================================================
// NIRVANA - Patient Reminders Screen
// Description: Senior-accessible daily routine and reminder checklist.
// Claymorphic wellness design with soft dual shadows, progress tracking,
// large touch targets (>64dp), and clear Done / Snooze / Later actions.
// Operates 100% offline via Hive with automated SyncEngine background sync.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/app/widgets/widgets.dart';
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

    final remindersAsync = ref.watch(activeRemindersProvider(patientId));

    return Scaffold(
      backgroundColor: ElderColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: LargeIconButton(
            icon: Icons.arrow_back_rounded,
            semanticLabel: 'Back to Home',
            size: 48,
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/patient/home');
              }
            },
          ),
        ),
        title: const Text(
          'Daily Routines',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: ElderColors.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: LargeIconButton(
              icon: Icons.refresh_rounded,
              semanticLabel: 'Refresh',
              size: 48,
              onPressed: () => ref.invalidate(activeRemindersProvider(patientId)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: remindersAsync.when(
          data: (reminders) {
            final allReminders = HiveDatabase.remindersBox.values.where((r) {
              return (patientId.isEmpty || r.patientId == patientId) && r.isActive;
            }).map(Reminder.fromHive).toList();

            allReminders.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

            final completedCount = allReminders.where((r) => r.isCompleted).length;
            final totalCount = allReminders.length;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Motivational Progress Header
                  _ClayProgressBanner(
                    completedCount: completedCount,
                    totalCount: totalCount,
                  ),
                  const SizedBox(height: 24),

                  // 2. Reminders Header
                  const Text(
                    'Today\'s Schedule',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: ElderColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. Reminders List
                  if (allReminders.isEmpty)
                    const _ClayEmptyRemindersCard()
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: allReminders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final reminder = allReminders[index];
                        return _ClayPatientReminderCard(
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
          loading: () => const LoadingState(message: 'Loading your routines...'),
          error: (e, _) => ErrorState(
            title: 'Could not load reminders',
            message: e.toString(),
            onRetry: () => ref.invalidate(activeRemindersProvider(patientId)),
          ),
        ),
      ),
    );
  }
}

// ==============================================================================
// Motivational Clay Progress Banner
// ==============================================================================

class _ClayProgressBanner extends StatelessWidget {
  final int completedCount;
  final int totalCount;

  const _ClayProgressBanner({
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
        color: allDone ? ElderColors.forestBg : ElderColors.surface,
        borderRadius: BorderRadius.circular(ElderTheme.cardBorderRadius),
        boxShadow: NirvanaShadows.card(tint: allDone ? ElderColors.forestDeep : null),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: allDone ? ElderColors.forestBg : ElderColors.primaryContainer,
                  shape: BoxShape.circle,
                  boxShadow: NirvanaShadows.float(
                    tint: allDone ? ElderColors.forestDeep : ElderColors.primary,
                  ),
                ),
                child: Icon(
                  allDone ? Icons.celebration_rounded : Icons.checklist_rounded,
                  size: 26,
                  color: allDone ? ElderColors.forestDeep : ElderColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  allDone
                      ? 'All caught up for today! 🎉'
                      : '$completedCount of $totalCount Completed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: allDone ? ElderColors.forestDeep : ElderColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(NirvanaRadii.pill),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: ElderColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                allDone ? ElderColors.forestDeep : ElderColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            allDone
                ? 'Great job keeping up with your health routines today.'
                : 'Take your time and complete each activity as scheduled.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: allDone ? ElderColors.forestDeep : ElderColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// Claymorphic Patient Reminder Card
// ==============================================================================

class _ClayPatientReminderCard extends ConsumerWidget {
  final Reminder reminder;
  final String patientId;

  const _ClayPatientReminderCard({
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

    Color cardBg = ElderColors.surface;
    Color iconBg = ElderColors.skyBg;
    Color iconColor = ElderColors.skyDeep;
    IconData icon = Icons.alarm_rounded;

    if (isCompleted) {
      cardBg = ElderColors.forestBg;
      iconBg = ElderColors.forestBg;
      iconColor = ElderColors.forestDeep;
      icon = Icons.check_circle_rounded;
    } else if (isSnoozed) {
      cardBg = ElderColors.amberBg;
      iconBg = ElderColors.amberBg;
      iconColor = ElderColors.amberDeep;
      icon = Icons.snooze_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(ElderTheme.cardBorderRadius),
        boxShadow: isCompleted ? NirvanaShadows.card(tint: ElderColors.forestDeep) : NirvanaShadows.card(),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: Icon bubble, Time, Status Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                  boxShadow: NirvanaShadows.float(tint: iconColor),
                ),
                child: Icon(icon, size: 28, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isCompleted ? ElderColors.textMuted : ElderColors.textPrimary,
                      ),
                    ),
                    if (isCompleted && reminder.completedAt != null)
                      const Text(
                        'Completed today ✓',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: ElderColors.forestDeep,
                        ),
                      )
                    else if (isSnoozed && reminder.snoozedUntil != null)
                      Text(
                        'Snoozed until ${_formatTimeOfDay(reminder.snoozedUntil!)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: ElderColors.amberDeep,
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
              fontWeight: FontWeight.w800,
              color: isCompleted ? ElderColors.textMuted : ElderColors.textPrimary,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),

          // Description
          if (reminder.body.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              reminder.body,
              style: TextStyle(
                fontSize: 15,
                color: isCompleted ? ElderColors.textMuted : ElderColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 18),

          // Action Buttons
          if (!isCompleted) ...[
            Row(
              children: [
                // DONE BUTTON
                Expanded(
                  flex: 3,
                  child: LargeActionButton(
                    label: 'Done',
                    icon: Icons.check_rounded,
                    variant: LargeActionButtonVariant.sage,
                    minHeight: 52,
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
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            backgroundColor: ElderColors.forestDeep,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),

                // SNOOZE BUTTON
                Expanded(
                  flex: 2,
                  child: LargeActionButton(
                    label: '15 min',
                    icon: Icons.snooze_rounded,
                    variant: LargeActionButtonVariant.buttercup,
                    minHeight: 52,
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
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                            backgroundColor: ElderColors.amberDeep,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: ElderColors.forestBg,
                borderRadius: BorderRadius.circular(NirvanaRadii.pill),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, size: 18, color: ElderColors.forestDeep),
                  SizedBox(width: 6),
                  Text(
                    'All completed for this schedule',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: ElderColors.forestDeep,
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

class _ClayEmptyRemindersCard extends StatelessWidget {
  const _ClayEmptyRemindersCard();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.spa_rounded,
      title: 'No reminders for today',
      message: 'You are all caught up. Have a peaceful, restful day! 🌸',
    );
  }
}

