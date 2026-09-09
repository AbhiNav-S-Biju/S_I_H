// ==============================================================================
// NIRVANA - Patient Home Screen
// Description: The primary landing page for elderly patients after device pairing.
// Shown on every launch once the device is paired — no login, no code entry.
// Displays a warm greeting, quick-access tiles, and time-aware messaging.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/database/hive_database.dart';
import 'package:nirvana/features/patient/providers/patient_pairing_providers.dart';
import 'package:nirvana/features/reminders/providers/reminder_providers.dart';

class PatientHomeScreen extends ConsumerWidget {
  const PatientHomeScreen({super.key});

  String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(localPatientSessionProvider);
    final preferredName = session?.preferredName ?? 'there';
    final greeting = _timeGreeting();

    return Scaffold(
      backgroundColor: ElderColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----------------------------------------------------------------
              // Header: Greeting
              // ----------------------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: TextStyle(
                            fontSize: 22,
                            color: ElderColors.textMuted,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          preferredName,
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: ElderColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: ElderColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 34,
                      color: ElderColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Date
              Text(
                _formattedDate(),
                style: TextStyle(fontSize: 17, color: ElderColors.textMuted),
              ),

              const SizedBox(height: 32),

              // ----------------------------------------------------------------
              // Today's Wellness Card
              // ----------------------------------------------------------------
              _WellnessCard(),
              const SizedBox(height: 20),

              // ----------------------------------------------------------------
              // Next Routine / Reminder Card
              // ----------------------------------------------------------------
              _UpcomingReminderCard(patientId: session?.patientId ?? ''),
              const SizedBox(height: 28),

              // ----------------------------------------------------------------
              // Quick Access Grid
              // ----------------------------------------------------------------
              Text(
                'What would you like to do?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: ElderColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              _QuickAccessGrid(),
              const SizedBox(height: 32),

              // ----------------------------------------------------------------
              // Encouragement Banner
              // ----------------------------------------------------------------
              _EncouragementBanner(name: preferredName),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _formattedDate() {
    final now = DateTime.now();
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }
}

// ==============================================================================
// Wellness Card — shows a soft motivational message
// ==============================================================================

class _WellnessCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ElderColors.primary, ElderColors.primary.withAlpha(200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ElderColors.primary.withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You\'re doing great! 🌟',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Keep up your daily activities.\nEvery little step counts.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_rounded,
              size: 36,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// Quick Access Grid
// ==============================================================================

class _QuickAccessGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tiles = [
      _QuickTile(
        icon: Icons.extension_rounded,
        label: 'Memory\nGames',
        color: const Color(0xFF7C3AED),
        bgColor: const Color(0xFFEDE9FE),
        onTap: () => context.push('/patient/games'),
      ),
      _QuickTile(
        icon: Icons.alarm_rounded,
        label: 'My\nReminders',
        color: const Color(0xFF0369A1),
        bgColor: const Color(0xFFE0F2FE),
        onTap: () => context.push('/patient/reminders'),
      ),
      _QuickTile(
        icon: Icons.photo_album_rounded,
        label: 'Family\nPhotos',
        color: const Color(0xFFB45309),
        bgColor: const Color(0xFFFEF3C7),
        onTap: () {}, // Future: context.go('/patient/photos')
      ),
      _QuickTile(
        icon: Icons.record_voice_over_rounded,
        label: 'Ask\nNIRVANA',
        color: ElderColors.primary,
        bgColor: ElderColors.primaryContainer,
        onTap: () => context.push('/ask-nirvana'),
      ),
      _QuickTile(
        icon: Icons.settings_rounded,
        label: 'Settings',
        color: ElderColors.textSecondary,
        bgColor: ElderColors.surfaceElevated,
        onTap: () => context.push('/patient/settings'),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.15,
      children: tiles,
    );
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _QuickTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        splashColor: color.withAlpha(30),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              const Spacer(),
              Text(
                label,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: color,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==============================================================================
// Upcoming Reminder Card
// ==============================================================================

class _UpcomingReminderCard extends ConsumerWidget {
  final String patientId;

  const _UpcomingReminderCard({required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectivePatientId = patientId.isNotEmpty
        ? patientId
        : (HiveDatabase.pairedPatientId ?? '');

    final remindersAsync = ref.watch(
      activeRemindersProvider(effectivePatientId),
    );

    return remindersAsync.when(
      data: (reminders) {
        if (reminders.isEmpty) {
          return const SizedBox.shrink();
        }

        final nextReminder = reminders.first;
        final hour = nextReminder.scheduledAt.hour;
        final minute = nextReminder.scheduledAt.minute;
        final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        final period = hour >= 12 ? 'PM' : 'AM';
        final minuteStr = minute.toString().padLeft(2, '0');
        final formattedTime = '$displayHour:$minuteStr $period';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0284C7).withValues(alpha: 0.08),
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.alarm,
                      size: 20,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Next Routine',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      formattedTime,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                nextReminder.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ElderColors.textPrimary,
                ),
              ),
              if (nextReminder.body.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  nextReminder.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final repo = ref.read(reminderRepositoryProvider);
                        final notif = ref.read(notificationServiceProvider);

                        await repo.completeReminder(
                          nextReminder.id,
                          patientId: effectivePatientId,
                        );
                        await notif.cancelReminder(nextReminder.notificationId);

                        ref.invalidate(
                          activeRemindersProvider(effectivePatientId),
                        );
                      },
                      icon: const Icon(Icons.check, size: 20),
                      label: const Text('Mark Done'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => context.push('/patient/reminders'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      foregroundColor: const Color(0xFF0284C7),
                      side: const BorderSide(color: Color(0xFF0284C7)),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('View All'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ==============================================================================
// Encouragement Banner
// ==============================================================================

class _EncouragementBanner extends StatelessWidget {
  final String name;
  const _EncouragementBanner({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ElderColors.primaryContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ElderColors.primary.withAlpha(50)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_rounded,
            color: ElderColors.primary,
            size: 32,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Remember: your caregiver is always just a call away, $name.',
              style: const TextStyle(
                fontSize: 16,
                color: ElderColors.onPrimaryContainer,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
