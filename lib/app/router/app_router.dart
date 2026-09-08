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
  final isOnboardingCompleted = ref.read(onboardingCompletedProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: isOnboardingCompleted ? '/home' : '/onboarding',
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
        path: '/caregiver/dashboard',
        parentNavigatorKey: _rootNavigatorKey,
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
