// ==============================================================================
// NIRVANA - Caregiver Dashboard Screen
// Description: Main portal screen for caregivers and families to monitor
// daily routines, game activity, reminder adherence, and sync status with
// claymorphic design and elder-grade readability.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/app/widgets/widgets.dart';
import 'package:nirvana/app/widgets/clay_3d/clay_3d.dart';
import 'package:nirvana/features/caregiver/providers/caregiver_providers.dart';
import 'caregiver_dashboard_pages.dart';
import 'widgets/caregiver_bottom_navigation.dart';

class CaregiverDashboardScreen extends ConsumerStatefulWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  ConsumerState<CaregiverDashboardScreen> createState() =>
      _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState
    extends ConsumerState<CaregiverDashboardScreen> {
  int _selectedIndex = 0;

  static const _titles = [
    'Caregiver Dashboard',
    'Recent Alerts & Activities',
    'Reminder Status & Recent Activity',
  ];

  void _refreshData() {
    ref.invalidate(assignedPatientsProvider);
    ref.invalidate(caregiverNotificationsProvider);
    ref.invalidate(selectedPatientGameHistoryProvider);
    ref.invalidate(selectedPatientRemindersProvider);
    ref.invalidate(selectedPatientSevenDayActivityProvider);
    ref.invalidate(caregiverSyncStatusProvider);
  }

  Future<void> _logout() async {
    await ref.read(caregiverAuthProvider.notifier).logout();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(caregiverAuthProvider);
    final caregiver = authState.value;
    final unreadCount = ref.watch(unreadCaregiverNotificationsCountProvider);

    return Scaffold(
      backgroundColor: ElderColors.backgroundClay,
      body: ClayBackdrop3D(
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 12.0,
                ),
                child: Row(
                  children: [
                    LargeIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: 'Back to Landing',
                      backgroundColor: Colors.white,
                      iconColor: ElderColors.textPrimary,
                      size: 52.0,
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/');
                        }
                      },
                    ),
                    const SizedBox(width: 14.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _titles[_selectedIndex],
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: ElderColors.textPrimary,
                            ),
                          ),
                          Text(
                            caregiver != null
                                ? 'Welcome, ${caregiver.fullName}'
                                : 'NIRVANA Care',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: ElderColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Add Loved One Action
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_add_rounded,
                          color: ElderColors.clayLavender,
                          size: 22,
                        ),
                      ),
                      tooltip: 'Add Loved One',
                      onPressed: () => context.push('/caregiver/onboarding'),
                    ),
                    // Refresh Action
                    IconButton(
                      icon: Badge(
                        isLabelVisible: unreadCount > 0,
                        label: Text('$unreadCount'),
                        backgroundColor: ElderColors.clayPeach,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0A000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.refresh_rounded,
                            color: ElderColors.textPrimary,
                            size: 22,
                          ),
                        ),
                      ),
                      tooltip: 'Refresh Data',
                      onPressed: _refreshData,
                    ),
                    // Sign Out Action
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: Color(0xFFE11D48),
                          size: 22,
                        ),
                      ),
                      tooltip: 'Sign Out',
                      onPressed: _logout,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: const [
                    CaregiverHomePage(),
                    CaregiverAlertsPage(),
                    CaregiverRemindersPage(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CaregiverBottomNavigation(
        selectedIndex: _selectedIndex,
        onSelected: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
