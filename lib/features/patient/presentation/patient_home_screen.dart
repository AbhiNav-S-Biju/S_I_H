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
import 'package:nirvana/app/theme/nirvana_responsive.dart';
import 'package:nirvana/app/widgets/clay_3d/clay_3d.dart';
import 'package:nirvana/app/widgets/widgets.dart';
import 'package:nirvana/database/hive_database.dart';
import 'package:nirvana/features/location_help/location_help.dart';
import 'package:nirvana/features/patient/providers/patient_pairing_providers.dart';
import 'package:nirvana/features/reminders/models/reminder.dart';
import 'package:nirvana/features/reminders/providers/reminder_providers.dart';
import 'package:nirvana/l10n/app_localizations.dart';
import 'package:nirvana/l10n/l10n_extension.dart';

import 'widgets/patient_dashboard_widgets.dart';

/// The patient-facing home dashboard.
///
/// Layout contract (see the dashboard spec Â§3): the scrollable body lives in a
/// [SingleChildScrollView] inside a [SafeArea], and the floating SOS control is
/// anchored to the *viewport* via a [Stack], never placed inside the scroll
/// content. Every card derives its size from constraints, so no width/height is
/// hardcoded and nothing overflows from 320px to 480px at up to 130% text scale.
class PatientHomeScreen extends ConsumerStatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen> {
  /// Scroll threshold (px) past which the SOS pill collapses to a circle.
  static const double _sosCollapseThreshold = 40.0;

  final ScrollController _scrollController = ScrollController();
  bool _sosCollapsed = false;

  /// Guards the one-shot "reminder due" popup so it does not re-fire on rebuild.
  bool _duePopupChecked = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowDueReminder());
  }

  /// Shows an in-app notification popup if a reminder is due right now.
  ///
  /// The system local notification handles the app-backgrounded case; this
  /// covers the app being open on the dashboard so the elder still gets a clear,
  /// large, popup prompt (consistent with the app's accessible design).
  Future<void> _maybeShowDueReminder() async {
    if (_duePopupChecked || !mounted) return;
    _duePopupChecked = true;

    final patientId = ref.read(localPatientSessionProvider)?.patientId;
    if (patientId == null || patientId.isEmpty) return;

    try {
      final reminders = await ref.read(
        activeRemindersProvider(patientId).future,
      );
      if (!mounted || reminders.isEmpty) return;

      final now = DateTime.now();
      // Treat anything due within the last hour and not yet completed as due
      // now, matching the reminder repository's catch-up window.
      bool isDueReminder(Reminder r) {
        final effectiveTime = r.snoozedUntil ?? r.scheduledAt;
        return r.isActive &&
            !r.isCompleted &&
            effectiveTime.isBefore(now) &&
            now.difference(effectiveTime) < const Duration(hours: 1);
      }

      final due = reminders.where(isDueReminder).firstOrNull;
      if (due == null || !mounted) return;

      final l10n = context.l10n;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(
            Icons.notifications_active_rounded,
            size: 40,
            color: ElderColors.skyDeep,
          ),
          title: Text(due.title),
          content: Text(
            due.body.isNotEmpty ? due.body : l10n.reminderDueFallbackBody,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.reminderDueDialogLater),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.reminderDueDialogViewRoutines),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Could not evaluate due reminders: $e');
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// Collapses the SOS control once the body scrolls past a small threshold.
  /// Only flips state when the boolean actually changes, so this never spams
  /// rebuilds while scrolling.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final shouldCollapse =
        _scrollController.offset > _sosCollapseThreshold;
    if (shouldCollapse != _sosCollapsed && mounted) {
      setState(() => _sosCollapsed = shouldCollapse);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final l10n = context.l10n;
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.logoutDialogTitle),
        content: Text(l10n.logoutDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.logoutButton),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    await HiveDatabase.clearPatientSession();
    if (context.mounted) context.go('/');
  }

  String _timeGreeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.goodMorningGreeting;
    if (hour < 17) return l10n.goodAfternoonGreeting;
    return l10n.goodEveningGreeting;
  }

  /// The six launcher entries for the icon grid. Kept as a method so the grid
  /// stays a dumb layout widget and navigation lives in the screen.
  List<AppIconItem> _launcherItems(AppLocalizations l10n) {
    return [
      AppIconItem(
        icon: Icons.extension_rounded,
        label: l10n.gamesNavLabel,
        gradient: ElderColors.clayGradPurple,
        onTap: () => context.push('/patient/games'),
      ),
      AppIconItem(
        icon: Icons.alarm_rounded,
        label: l10n.remindersNavLabel,
        gradient: ElderColors.clayGradTeal,
        onTap: () => context.push('/patient/reminders'),
      ),
      AppIconItem(
        icon: Icons.photo_album_rounded,
        label: l10n.photosNavLabel,
        gradient: ElderColors.clayGradCoral,
        onTap: () => context.push('/patient/family-photos'),
      ),
      AppIconItem(
        icon: Icons.record_voice_over_rounded,
        label: l10n.askNavLabel,
        gradient: ElderColors.clayGradSky,
        onTap: () => context.push('/ask-nirvana'),
      ),
      AppIconItem(
        icon: Icons.lock_person_rounded,
        label: l10n.accountsNavLabel,
        gradient: ElderColors.clayGradSage,
        onTap: () => context.push('/patient/social-accounts'),
      ),
      AppIconItem(
        icon: Icons.settings_rounded,
        label: l10n.settingsNavLabel,
        gradient: ElderColors.clayGradGold,
        onTap: () => context.push('/patient/settings'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = ref.watch(localPatientSessionProvider);
    final preferredName =
        session?.preferredName.isNotEmpty == true
            ? session!.preferredName
            : l10n.friendlyFallbackName;
    final greeting = _timeGreeting(l10n);

    // The SOS control clears the system gesture bar by tracking the real bottom
    // inset rather than a hardcoded offset (spec Â§3 & Â§4).
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final pagePadding = NirvanaSpacing.pageHorizontal(context);

    return Scaffold(
      backgroundColor: ElderColors.clayBackground,
      body: ClayBackdrop3D(
        child: SafeArea(
          // Stack keeps the SOS control anchored to the viewport, ABOVE the
          // scroll content, so it stays reachable at any scroll offset.
          child: Stack(
            children: [
              // -------------------------------------------------------------
              // SCROLLABLE BODY â€” content-sized, never height-constrained.
              // Bottom padding reserves room so the last card is never hidden
              // behind the floating SOS pill.
              // -------------------------------------------------------------
              SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(
                  pagePadding,
                  NirvanaSpacing.pageVertical,
                  pagePadding,
                  // 96 = SOS height (60) + breathing room so nothing hides
                  // behind it, plus the live bottom inset.
                  96.0 + bottomInset,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // -------------------------------------------------------
                    // Header â€” date pill + greeting/name + clay icon buttons.
                    // -------------------------------------------------------
                    PatientHeader(
                      dateLabel: _formattedDate(),
                      greeting: greeting,
                      patientName: preferredName,
                      onFavorite: () => context.push('/patient/family-photos'),
                      onLogout: () => _logout(context),
                    ),
                    const SizedBox(height: 22.0),

                    // -------------------------------------------------------
                    // Daily moment â€” purple gradient clay card.
                    // -------------------------------------------------------
                    DailyMomentCard(
                      eyebrow: l10n.dailyMomentEyebrow,
                      headline: l10n.dailyMomentHeadline,
                      supportingText: l10n.dailyMomentSupportingText,
                      icon: Icons.wb_sunny_rounded,
                    ),
                    const SizedBox(height: 20.0),

                    // -------------------------------------------------------
                    // Next routine / reminder (existing data-driven card).
                    // -------------------------------------------------------
                    _UpcomingReminderCard(patientId: session?.patientId ?? ''),

                    // -------------------------------------------------------
                    // Launcher section.
                    // -------------------------------------------------------
                    Text(
                      l10n.whatWouldYouLikeToDo,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 20.0,
                            fontWeight: FontWeight.w900,
                            color: ElderColors.clayInk,
                          ),
                    ),
                    const SizedBox(height: 16.0),
                    AppIconGrid(items: _launcherItems(l10n)),
                    const SizedBox(height: 24.0),

                    // -------------------------------------------------------
                    // Caregiver reassurance â€” sage clay banner.
                    // -------------------------------------------------------
                    CaregiverBanner(
                      message: l10n.caregiverReassuranceMessage,
                    ),
                    const SizedBox(height: 8.0),
                  ],
                ),
              ),

              // -------------------------------------------------------------
              // FLOATING SOS â€” bottom-right, above the scroll content. Offset
              // from the real bottom inset so it never collides with gesture
              // navigation on any device.
              // -------------------------------------------------------------
              Positioned(
                right: pagePadding,
                bottom: 16.0 + bottomInset,
                child: FloatingSosButton(
                  collapsed: _sosCollapsed,
                  onPressed: () => startHelpFlow(context, ref),
                ),
              ),
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

    final l10n = context.l10n;
    return remindersAsync.when(
      data: (reminders) {
        if (reminders.isNotEmpty) {
          // Reconcile the device's scheduled alarms with the loaded reminders so
          // due reminders raise a system popup, even when they were created or
          // synced on another device.
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            try {
              await ref
                  .read(notificationServiceProvider)
                  .rescheduleAllForPatient(reminders);
            } catch (e) {
              debugPrint('⚠️ Could not schedule reminder notifications: $e');
            }
          });
        }
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
                  Expanded(
                    child: Text(
                      l10n.nextRoutineTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: ElderColors.skyDeep,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
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
              NirvanaButtonRow(
                spacing: 12,
                children: [
                  LargeActionButton(
                    label: l10n.markDoneButton,
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
                  LargeActionButton(
                    label: l10n.viewAllButton,
                    variant: LargeActionButtonVariant.secondary,
                    minHeight: 52,
                    onPressed: () => context.push('/patient/reminders'),
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
