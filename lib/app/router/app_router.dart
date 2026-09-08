// ==============================================================================
// NIRVANA - AppRouter
// Description: GoRouter navigation architecture linking Onboarding, Home,
// Games Hub, and Settings through an accessible ElderAppShell.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/caregiver/caregiver.dart';
import '../../features/games/games.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/providers/onboarding_provider.dart';
import '../../features/settings/presentation/language_selector_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../shell/elder_app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'root',
  );
  final homeNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'home',
  );
  final gamesNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'games',
  );
  final settingsNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'settings');

  final isOnboardingCompleted = ref.read(onboardingCompletedProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: isOnboardingCompleted ? '/home' : '/onboarding',
    redirect: (context, state) {
      final isCaregiverRoute = state.matchedLocation.startsWith('/caregiver');
      final isProtectedCaregiver = state.matchedLocation == '/caregiver/dashboard' ||
          state.matchedLocation == '/caregiver/onboarding' ||
          state.matchedLocation == '/caregiver/add-patient';
      // Read auth state at redirect time so it reflects the latest login/logout
      final authState = ref.read(caregiverAuthProvider);
      final isAuthenticated = authState.value != null;

      // Guard dashboard and onboarding — redirect to login if not authenticated
      if (isProtectedCaregiver && !isAuthenticated) {
        return '/caregiver/login';
      }

      // If already authenticated and trying to visit login/register, skip ahead
      if (isCaregiverRoute &&
          (state.matchedLocation == '/caregiver/login' ||
              state.matchedLocation == '/caregiver/register') &&
          isAuthenticated) {
        return '/caregiver/dashboard';
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
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CaregiverLoginScreen(),
      ),
      GoRoute(
        path: '/caregiver/register',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CaregiverRegisterScreen(),
      ),
      GoRoute(
        path: '/caregiver/onboarding',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CaregiverPatientOnboardingScreen(),
      ),
      GoRoute(
        path: '/caregiver/add-patient',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CaregiverPatientOnboardingScreen(),
      ),
      GoRoute(
        path: '/caregiver/dashboard',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CaregiverDashboardScreen(),
      ),

      // 3. Main Stateful Shell with Accessible Bottom Navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ElderAppShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            navigatorKey: homeNavigatorKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // Branch 1: Games Hub
          StatefulShellBranch(
            navigatorKey: gamesNavigatorKey,
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
            navigatorKey: settingsNavigatorKey,
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'language',
                    parentNavigatorKey: rootNavigatorKey,
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
