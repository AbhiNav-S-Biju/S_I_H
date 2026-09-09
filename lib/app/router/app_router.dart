// ==============================================================================
// NIRVANA - AppRouter
// Description: GoRouter navigation architecture linking Onboarding, Home,
// Games Hub, Settings, Caregiver Portal, and Patient Device flow through
// an accessible ElderAppShell. Startup logic checks local pairing state
// to route already-paired patient devices directly to Patient Home.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../database/hive_database.dart';
import '../../features/caregiver/caregiver.dart';
import '../../features/games/games.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/providers/onboarding_provider.dart';
import '../../features/patient/patient.dart';
import '../../features/settings/presentation/language_selector_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../shell/elder_app_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _homeNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'home',
);
final GlobalKey<NavigatorState> _gamesNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'games',
);
final GlobalKey<NavigatorState> _settingsNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'settings');

final appRouterProvider = Provider<GoRouter>((ref) {
  // Check local pairing state synchronously — HiveDatabase is already open
  // before runApp() is called in main.dart.
  final isPatientDevicePaired = HiveDatabase.isDevicePaired;
  final isOnboardingCompleted = ref.read(onboardingCompletedProvider);

  // Priority: paired patient device > elder onboarding > onboarding
  final String initialLocation;
  if (isPatientDevicePaired) {
    initialLocation = '/patient/home';
  } else if (isOnboardingCompleted) {
    initialLocation = '/home';
  } else {
    initialLocation = '/onboarding';
  }

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: initialLocation,
    redirect: (context, state) {
      final authState = ref.read(caregiverAuthProvider);
      final loc = state.matchedLocation;

      final isCaregiverRoute = loc.startsWith('/caregiver');
      final isProtectedCaregiver = loc == '/caregiver/dashboard' ||
          loc == '/caregiver/onboarding' ||
          loc == '/caregiver/add-patient';
      final isAuthenticated = authState.value != null;

      // Guard caregiver dashboard — redirect to login if not authenticated
      if (isProtectedCaregiver && !isAuthenticated) {
        return '/caregiver/login';
      }

      // If already authenticated and visiting login/register, skip ahead
      if (isCaregiverRoute &&
          (loc == '/caregiver/login' || loc == '/caregiver/register') &&
          isAuthenticated) {
        return '/caregiver/dashboard';
      }

      // If device is already paired and navigating to patient welcome/pairing,
      // redirect straight to home
      if (HiveDatabase.isDevicePaired &&
          (loc == '/patient/welcome' || loc == '/patient/pairing')) {
        return '/patient/home';
      }

      return null; // no redirect
    },
    routes: [
      // 1. Onboarding Flow (Full screen)
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // 2. Caregiver Portal Routes (Full screen, outside elder shell)
      GoRoute(
        path: '/caregiver/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CaregiverLoginScreen(),
      ),
      GoRoute(
        path: '/caregiver/register',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CaregiverRegisterScreen(),
      ),
      GoRoute(
        path: '/caregiver/onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CaregiverPatientOnboardingScreen(),
      ),
      GoRoute(
        path: '/caregiver/add-patient',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CaregiverPatientOnboardingScreen(),
      ),
      GoRoute(
        path: '/caregiver/dashboard',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CaregiverDashboardScreen(),
      ),

      // 3. Patient Device Flow (Full screen — no elder shell)
      GoRoute(
        path: '/patient/welcome',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PatientWelcomeScreen(),
      ),
      GoRoute(
        path: '/patient/pairing',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PatientPairingScreen(),
      ),
      GoRoute(
        path: '/patient/success',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PatientPairingSuccessScreen(),
      ),
      GoRoute(
        path: '/patient/home',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PatientHomeScreen(),
      ),
      GoRoute(
        path: '/patient/reminders',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PatientRemindersScreen(),
      ),

      // 4. Main Stateful Shell with Accessible Bottom Navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ElderAppShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // Branch 1: Games Hub
          StatefulShellBranch(
            navigatorKey: _gamesNavigatorKey,
            routes: [
              GoRoute(
                path: '/games',
                builder: (context, state) => GamesHubScreen(
                  onSessionCompleted: (session) {
                    debugPrint('Activity Session Completed: $session');
                  },
                ),
              ),
            ],
          ),

          // Branch 2: Settings & Visual Comfort
          StatefulShellBranch(
            navigatorKey: _settingsNavigatorKey,
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'language',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const LanguageSelectorScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
