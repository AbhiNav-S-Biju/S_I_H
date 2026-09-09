// ==============================================================================
// NIRVANA - Patient Home Screen
// Description: The primary landing page for elderly patients after device pairing.
// Claymorphic wellness design with soft dual shadows, pastel tiles, large typography,
// and accessible touch surfaces.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/app/widgets/widgets.dart';
import 'package:nirvana/database/hive_database.dart';
import 'package:nirvana/features/patient/providers/patient_pairing_providers.dart';
import 'package:nirvana/features/reminders/providers/reminder_providers.dart';

class PatientHomeScreen extends ConsumerWidget {
  const PatientHomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    await HiveDatabase.clearPatientSession();
    if (context.mounted) context.go('/');
  }

  String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(localPatientSessionProvider);
    final preferredName = session?.preferredName ?? 'Friend';
    final greeting = _timeGreeting();

    return Scaffold(
      backgroundColor: ElderColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----------------------------------------------------------------
              // Header: Warm Greeting & Avatar
              // ----------------------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 4.0,
                          ),
                          decoration: BoxDecoration(
                            color: ElderColors.pastelButtercup,
                            borderRadius: BorderRadius.circular(14.0),
                          ),
                          child: Text(
                            _formattedDate(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: ElderColors.amberDeep,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          greeting,
                          style: const TextStyle(
                            fontSize: 20,
                            color: ElderColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          preferredName,
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: ElderColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: ElderColors.primaryContainer,
                      shape: BoxShape.circle,
                      boxShadow: NirvanaShadows.float(
                        tint: ElderColors.primary,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.favorite_rounded,
                        size: 32,
                        color: ElderColors.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _logout(context),
                    tooltip: 'Log out',
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: ElderColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ----------------------------------------------------------------
              // Today's Wellness Motivation Card
              // ----------------------------------------------------------------
              _ClayWellnessCard(),
              const SizedBox(height: 20),

              // ----------------------------------------------------------------
              // Next Routine / Reminder Card
              // ----------------------------------------------------------------
              _UpcomingReminderCard(patientId: session?.patientId ?? ''),
              const SizedBox(height: 28),

              // ----------------------------------------------------------------
              // Quick Access Grid
              // ----------------------------------------------------------------
              const Text(
                'What would you like to do?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: ElderColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              _QuickAccessGrid(),
              const SizedBox(height: 28),

              // ----------------------------------------------------------------
              // Encouragement Message
              // ----------------------------------------------------------------
              SupportiveMessage(
                message:
                    'Remember: your caregiver is always just a touch away, $preferredName.',
                icon: Icons.lightbulb_rounded,
                backgroundColor: ElderColors.pastelSage,
                accentColor: ElderColors.forestDeep,
              ),
              const SizedBox(height: 20),
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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }
}

// ==============================================================================
// Claymorphic Wellness Motivation Card
// ==============================================================================

class _ClayWellnessCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: ElderColors.primary,
        borderRadius: BorderRadius.circular(ElderTheme.cardBorderRadius),
        boxShadow: ElderColors.buttonShadow(color: ElderColors.primary),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'DAILY MOMENT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'You are doing wonderfully! 🌟',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Keep up your daily activities. Every little step brings peace and joy.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: const Icon(Icons.spa_rounded, size: 32, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// Quick Access Grid with Claymorphic Tiles
// ==============================================================================

class _QuickAccessGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tiles = [
      _ClayQuickTile(
        icon: Icons.extension_rounded,
        label: 'Memory Games',
        tag: 'BRAIN GYM',
        color: ElderColors.primary,
        bgColor: ElderColors.pastelLavender,
        onTap: () => context.push('/patient/games'),
      ),
      _ClayQuickTile(
        icon: Icons.alarm_rounded,
        label: 'My Reminders',
        tag: 'ROUTINES',
        color: ElderColors.skyDeep,
        bgColor: ElderColors.pastelSky,
        onTap: () => context.push('/patient/reminders'),
      ),
      _ClayQuickTile(
        icon: Icons.photo_album_rounded,
        label: 'Family Photos',
        tag: 'MEMORIES',
        color: ElderColors.coralDeep,
        bgColor: ElderColors.pastelPeach,
        onTap: () {},
      ),
      _ClayQuickTile(
        icon: Icons.settings_rounded,
        label: 'Settings',
        tag: 'PREFERENCES',
        color: ElderColors.amberDeep,
        bgColor: ElderColors.pastelButtercup,
        onTap: () => context.push('/patient/settings'),
      ),
      _ClayQuickTile(
        icon: Icons.record_voice_over_rounded,
        label: 'Ask NIRVANA',
        tag: 'AI COMPANION',
        color: ElderColors.primary,
        bgColor: ElderColors.pastelLavender,
        onTap: () => context.push('/ask-nirvana'),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.96,
      children: tiles,
    );
  }
}

class _ClayQuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tag;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ClayQuickTile({
    required this.icon,
    required this.label,
    required this.tag,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ElderTheme.cardBorderRadius),
        border: Border.all(color: ElderColors.borderLight, width: 1.5),
        boxShadow: ElderColors.clayShadow(),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(ElderTheme.cardBorderRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(ElderTheme.cardBorderRadius),
          onTap: onTap,
          splashColor: color.withValues(alpha: 0.15),
          highlightColor: color.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                        boxShadow: NirvanaShadows.float(tint: color),
                      ),
                      child: Icon(icon, size: 28, color: color),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: ElderColors.textMuted.withValues(alpha: 0.5),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 3.0,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(NirvanaRadii.pill),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: ElderColors.textPrimary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==============================================================================
// Upcoming Routine / Reminder Card
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
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(ElderTheme.cardBorderRadius),
            border: Border.all(color: ElderColors.borderLight, width: 1.5),
            boxShadow: ElderColors.clayShadow(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: ElderColors.pastelSky,
                      shape: BoxShape.circle,
                      boxShadow: ElderColors.clayShadow(
                        color: ElderColors.pastelSky,
                      ),
                    ),
                    child: const Icon(
                      Icons.alarm_rounded,
                      size: 24,
                      color: ElderColors.skyDeep,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Next Routine',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: ElderColors.skyDeep,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: ElderColors.skyDeep,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: ElderColors.buttonShadow(
                        color: ElderColors.skyDeep,
                      ),
                    ),
                    child: Text(
                      formattedTime,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                nextReminder.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: ElderColors.textPrimary,
                ),
              ),
              if (nextReminder.body.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  nextReminder.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    color: ElderColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: LargeActionButton(
                      label: 'Mark Done',
                      icon: Icons.check_circle_rounded,
                      variant: LargeActionButtonVariant.sage,
                      minHeight: 52,
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
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LargeActionButton(
                      label: 'View All',
                      variant: LargeActionButtonVariant.secondary,
                      minHeight: 52,
                      onPressed: () => context.push('/patient/reminders'),
                    ),
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
