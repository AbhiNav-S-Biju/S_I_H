import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/features/caregiver/providers/caregiver_providers.dart';
import 'package:nirvana/features/caregiver/presentation/widgets/activity_summary_cards.dart';
import 'package:nirvana/features/caregiver/presentation/widgets/caregiver_notifications_panel.dart';
import 'package:nirvana/features/caregiver/presentation/widgets/game_history_list.dart';
import 'package:nirvana/features/caregiver/presentation/widgets/patient_device_panel.dart';
import 'package:nirvana/features/caregiver/presentation/widgets/patient_selector_widget.dart';
import 'package:nirvana/features/caregiver/presentation/widgets/reminder_status_list.dart';
import 'package:nirvana/features/caregiver/presentation/widgets/seven_day_activity_chart.dart';
import 'package:nirvana/features/caregiver/presentation/widgets/sync_status_card.dart';
import 'package:nirvana/features/location_help/location_help.dart';

class CaregiverHomePage extends StatelessWidget {
  const CaregiverHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CaregiverScrollPage(
      children: [
        PatientSelectorWidget(),
        SizedBox(height: 14),
        // "Patient Needs Help" — renders only while a help request is live.
        NeedsHelpBanner(),
        PatientLocationSection(),
        SyncStatusCard(),
        SizedBox(height: 14),
        PatientDevicePanel(),
        SizedBox(height: 18),
        ActivitySummaryCards(),
        SizedBox(height: 18),
        SevenDayActivityChart(),
        SizedBox(height: 24),
      ],
    );
  }
}

class CaregiverAlertsPage extends StatelessWidget {
  const CaregiverAlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CaregiverScrollPage(
      children: [CaregiverNotificationsPanel(), SizedBox(height: 24)],
    );
  }
}

class CaregiverRemindersPage extends StatelessWidget {
  const CaregiverRemindersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CaregiverScrollPage(
      children: [
        _PageSectionTitle(icon: Icons.alarm_rounded, title: 'Reminder Status'),
        SizedBox(height: 10),
        ReminderStatusList(),
        SizedBox(height: 24),
        _PageSectionTitle(
          icon: Icons.history_rounded,
          title: 'Recent Activity',
        ),
        SizedBox(height: 10),
        GameHistoryList(),
        SizedBox(height: 24),
      ],
    );
  }
}

class _CaregiverScrollPage extends ConsumerWidget {
  final List<Widget> children;

  const _CaregiverScrollPage({required this.children});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      color: ElderColors.clayLavender,
      onRefresh: () async {
        ref.invalidate(assignedPatientsProvider);
        ref.invalidate(caregiverNotificationsProvider);
        ref.invalidate(selectedPatientGameHistoryProvider);
        ref.invalidate(selectedPatientRemindersProvider);
        ref.invalidate(selectedPatientSevenDayActivityProvider);
        ref.invalidate(caregiverSyncStatusProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: children,
      ),
    );
  }
}

class _PageSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _PageSectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: ElderColors.clayLavender),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: ElderColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
