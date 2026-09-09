// ==============================================================================
// NIRVANA - Patient Reminders Screen (3D Claymorphism)
// Description: Senior-accessible daily routine and reminder checklist.
// Features 3D volumetric progress banner, tactile reminder cards with dual-layer shadows,
// embossed status pills, and large tactile Done / Snooze action buttons.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/widgets/clay_3d/clay_3d.dart';
import '../../../database/hive_database.dart';
import '../../../features/caregiver/providers/caregiver_providers.dart';
import '../../../features/patient/providers/patient_pairing_providers.dart';
import '../../../features/reminders/models/reminder.dart';
import '../../../features/reminders/providers/reminder_providers.dart';

class PatientRemindersScreen extends ConsumerWidget {
  const PatientRemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(localPatientSessionProvider);
    final patientId = session?.patientId ?? HiveDatabase.pairedPatientId ?? '';

    final remindersAsync = ref.watch(activeRemindersProvider(patientId));

    return ClayScaffold3D(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Navigation Row
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/patient/home');
                  }
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Clay3DTheme.cardSurface,
                    shape: BoxShape.circle,
                    boxShadow: Clay3DTheme.cardShadow(blur: 8, offset: 3),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 24,
                      color: Clay3DTheme.textDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              ClaySlab3D(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                borderRadius: 18,
                child: Text(
                  'Daily Routines',
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Clay3DTheme.textDark,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => ref.invalidate(activeRemindersProvider(patientId)),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Clay3DTheme.cardSurface,
                    shape: BoxShape.circle,
                    boxShadow: Clay3DTheme.cardShadow(blur: 8, offset: 3),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.refresh_rounded,
                      size: 24,
                      color: Clay3DTheme.textDark,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          remindersAsync.when(
            data: (reminders) {
              final allReminders = HiveDatabase.remindersBox.values.where((r) {
                return (patientId.isEmpty || r.patientId == patientId) && r.isActive;
              }).map(Reminder.fromHive).toList();

              allReminders.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

              final completedCount = allReminders.where((r) => r.isCompleted).length;
              final totalCount = allReminders.length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Motivational 3D Progress Banner
                  _ClayProgressBanner3D(
                    completedCount: completedCount,
                    totalCount: totalCount,
                  ),
                  const SizedBox(height: 24),

                  // 2. Schedule Section Title
                  ClaySlab3D(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Today\'s Schedule',
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Clay3DTheme.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Reminders List
                  if (allReminders.isEmpty)
                    ClayCard3D(
                      padding: const EdgeInsets.all(24),
                      borderRadius: 24,
                      child: Column(
                        children: [
                          const Icon(
                            Icons.spa_rounded,
                            size: 48,
                            color: Clay3DTheme.lavender,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No reminders for today',
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Clay3DTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'You are all caught up. Have a peaceful, restful day! 🌸',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontSize: 14.5,
                              color: Clay3DTheme.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: allReminders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final reminder = allReminders[index];
                        return _ClayPatientReminderCard3D(
                          reminder: reminder,
                          patientId: patientId,
                        );
                      },
                    ),

                  const SizedBox(height: 32),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: Clay3DTheme.lavender),
              ),
            ),
            error: (e, _) => Center(
              child: Text(
                'Could not load routines: $e',
                style: GoogleFonts.nunito(color: Clay3DTheme.coral),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// 3D Progress Banner
// ==============================================================================
class _ClayProgressBanner3D extends StatelessWidget {
  final int completedCount;
  final int totalCount;

  const _ClayProgressBanner3D({
    required this.completedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = totalCount > 0 ? (completedCount / totalCount) : 1.0;
    final allDone = totalCount > 0 && completedCount >= totalCount;

    return ClayCard3D(
      padding: const EdgeInsets.all(22),
      borderRadius: 26,
      color: allDone ? const Color(0xFFE5F5EF) : Clay3DTheme.cardSurface,
      customShadows: Clay3DTheme.deepShadow(blur: 18, offset: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: allDone ? Clay3DTheme.tealLight : Clay3DTheme.lavenderLight,
                  shape: BoxShape.circle,
                  boxShadow: Clay3DTheme.cardShadow(blur: 8, offset: 3),
                ),
                child: Icon(
                  allDone ? Icons.celebration_rounded : Icons.checklist_rounded,
                  size: 26,
                  color: allDone ? const Color(0xFF1F5C5C) : const Color(0xFF5D4A8C),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  allDone
                      ? 'All caught up for today! 🎉'
                      : '$completedCount of $totalCount Completed',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Clay3DTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: const Color(0xFFE5DDD0),
              valueColor: AlwaysStoppedAnimation<Color>(
                allDone ? Clay3DTheme.teal : Clay3DTheme.lavender,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            allDone
                ? 'Great job keeping up with your health routines today.'
                : 'Take your time and complete each activity as scheduled.',
            style: GoogleFonts.nunito(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Clay3DTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// 3D Patient Reminder Card
// ==============================================================================
class _ClayPatientReminderCard3D extends ConsumerWidget {
  final Reminder reminder;
  final String patientId;

  const _ClayPatientReminderCard3D({
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

    Color iconBg = Clay3DTheme.tealLight;
    Color iconColor = const Color(0xFF1F5C5C);
    IconData icon = Icons.alarm_rounded;

    if (isCompleted) {
      iconBg = const Color(0xFFC8E6D9);
      iconColor = const Color(0xFF1B634B);
      icon = Icons.check_circle_rounded;
    } else if (isSnoozed) {
      iconBg = const Color(0xFFFDE8C0);
      iconColor = const Color(0xFF8C6212);
      icon = Icons.snooze_rounded;
    }

    return ClayCard3D(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      color: isCompleted ? const Color(0xFFEFF8F4) : Clay3DTheme.cardSurface,
      customShadows: Clay3DTheme.deepShadow(blur: 16, offset: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                  boxShadow: Clay3DTheme.cardShadow(blur: 8, offset: 3),
                ),
                child: Icon(icon, size: 26, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formattedTime,
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isCompleted ? Clay3DTheme.textMuted : Clay3DTheme.textDark,
                      ),
                    ),
                    if (isCompleted && reminder.completedAt != null)
                      Text(
                        'Completed today ✓',
                        style: GoogleFonts.nunito(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1B634B),
                        ),
                      )
                    else if (isSnoozed && reminder.snoozedUntil != null)
                      Text(
                        'Snoozed until ${_formatTimeOfDay(reminder.snoozedUntil!)}',
                        style: GoogleFonts.nunito(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF8C6212),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            reminder.title,
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isCompleted ? Clay3DTheme.textMuted : Clay3DTheme.textDark,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),

          if (reminder.body.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              reminder.body,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: isCompleted ? Clay3DTheme.textMuted : Clay3DTheme.textDark,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 16),

          if (!isCompleted) ...[
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ClayButton3D(
                    label: 'Done',
                    icon: Icons.check_rounded,
                    color: Clay3DTheme.teal,
                    minHeight: 48,
                    borderRadius: 18,
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
                              style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                            backgroundColor: const Color(0xFF1B634B),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ClayButton3D(
                    label: '15 min',
                    icon: Icons.snooze_rounded,
                    color: const Color(0xFFE5C067),
                    textColor: Clay3DTheme.textDark,
                    minHeight: 48,
                    borderRadius: 18,
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
                              style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            backgroundColor: const Color(0xFF8C6212),
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
            ClayPill3D(
              color: const Color(0xFFD3EFE3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check, size: 16, color: Color(0xFF1B634B)),
                  const SizedBox(width: 6),
                  Text(
                    'All completed for this schedule',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1B634B),
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
