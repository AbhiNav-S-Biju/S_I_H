// ==============================================================================
// NIRVANA - Caregiver Dashboard Screen
// Description: Main portal screen for caregivers and families to monitor
// daily routines, game activity, reminder adherence, and sync status.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/features/caregiver/providers/caregiver_providers.dart';
import 'caregiver_login_screen.dart';
import 'widgets/activity_summary_cards.dart';
import 'widgets/game_history_list.dart';
import 'widgets/patient_selector_widget.dart';
import 'widgets/reminder_status_list.dart';
import 'widgets/seven_day_activity_chart.dart';
import 'widgets/sync_status_card.dart';

class CaregiverDashboardScreen extends ConsumerWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(caregiverAuthProvider);
    final caregiver = authState.value;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF9),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Caregiver Dashboard',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              caregiver != null ? 'Welcome, ${caregiver.fullName}' : 'NIRVANA Care',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.grey),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: ElderColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: () {
              ref.invalidate(assignedPatientsProvider);
              ref.invalidate(selectedPatientGameHistoryProvider);
              ref.invalidate(selectedPatientRemindersProvider);
              ref.invalidate(selectedPatientSevenDayActivityProvider);
              ref.invalidate(caregiverSyncStatusProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await ref.read(caregiverAuthProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const CaregiverLoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(assignedPatientsProvider);
            ref.invalidate(selectedPatientGameHistoryProvider);
            ref.invalidate(selectedPatientRemindersProvider);
            ref.invalidate(selectedPatientSevenDayActivityProvider);
            ref.invalidate(caregiverSyncStatusProvider);
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            children: const [
              // 1. Patient Selector (Only assigned patients)
              PatientSelectorWidget(),
              SizedBox(height: 14),

              // 2. Sync Status Card
              SyncStatusCard(),
              SizedBox(height: 18),

              // 3. Activity Summary Metrics
              ActivitySummaryCards(),
              SizedBox(height: 18),

              // 4. 7-Day Activity View
              SevenDayActivityChart(),
              SizedBox(height: 20),

              // 5. Reminder Status Section
              Text(
                'Reminder Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ElderColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              ReminderStatusList(),
              SizedBox(height: 20),

              // 6. Recent Activity / Game History Section
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ElderColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              GameHistoryList(),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
