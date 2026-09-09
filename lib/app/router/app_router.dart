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
import '../../features/ask_nirvana/ask_nirvana.dart';
import '../../features/caregiver/caregiver.dart';
import '../../features/games/games.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/landing/landing.dart';
import '../../features/patient/patient.dart';
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

  // Landing page is always the initial route — portal selection
  const initialLocation = '/';

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
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
      // 0. Landing / Portal Selection
      GoRoute(
        path: '/',
        builder: (context, state) => const LandingScreen(),
      ),

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

      // 3. Patient Device Flow (Full screen — no elder shell)
      GoRoute(
        path: '/patient/welcome',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PatientWelcomeScreen(),
      ),
      GoRoute(
        path: '/patient/pairing',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PatientPairingScreen(),
      ),
      GoRoute(
        path: '/patient/success',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PatientPairingSuccessScreen(),
      ),
      GoRoute(
        path: '/patient/home',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PatientHomeScreen(),
      ),
      GoRoute(
        path: '/patient/games',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => GamesHubScreen(
          onSessionCompleted: (session) async {
            debugPrint('Patient Games — Session Completed: $session');

            final pairedId = HiveDatabase.pairedPatientId ??
                HiveDatabase.currentPatientSession?.patientId;

            if (pairedId != null && pairedId.isNotEmpty) {
              await ref
                  .read(gameSessionRepositoryProvider)
                  .recordGameSession(
                    session: session,
                    patientId: pairedId,
                  );

              await ref
                  .read(caregiverEventNotificationServiceProvider)
                  .notifyGameCompleted(
                    patientId: pairedId,
                    gameTitle: session.gameType.displayName,
                    score: session.score,
                    correctAnswers: session.correctAnswers,
                    totalQuestions: session.totalQuestions,
                    gameSessionId: session.id,
                  );
            }
          },
        ),
      ),
      GoRoute(
        path: '/patient/reminders',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PatientRemindersScreen(),
      ),
      GoRoute(
        path: '/patient/settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'language',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) => const LanguageSelectorScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'language',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) => const LanguageSelectorScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/ask-nirvana',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AskNirvanaScreen(),
      ),

      // 4. Main Stateful Shell with Accessible Bottom Navigation (Home & Games)
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
                  onSessionCompleted: (session) async {
                    debugPrint('Activity Session Completed: $session');

                    // Determine active patient ID:
                    // 1. Selected patient in Caregiver View (if active)
                    // 2. Paired patient session in Hive (if paired elder device)
                    // 3. First assigned patient if available
                    final selected = ref.read(selectedPatientProvider);
                    final pairedId = HiveDatabase.pairedPatientId ??
                        HiveDatabase.currentPatientSession?.patientId;
                    final assigned = ref.read(assignedPatientsProvider).value;

                    final effectivePatientId = selected?.id ??
                        pairedId ??
                        (assigned != null && assigned.isNotEmpty
                            ? assigned.first.id
                            : null);

                    if (effectivePatientId != null &&
                        effectivePatientId.isNotEmpty) {
                      await ref
                          .read(gameSessionRepositoryProvider)
                          .recordGameSession(
                            session: session,
                            patientId: effectivePatientId,
                          );

                      // Dispatch caregiver event notification
                      await ref
                          .read(caregiverEventNotificationServiceProvider)
                          .notifyGameCompleted(
                            patientId: effectivePatientId,
                            gameTitle: session.gameType.displayName,
                            score: session.score,
                            correctAnswers: session.correctAnswers,
                            totalQuestions: session.totalQuestions,
                            gameSessionId: session.id,
                          );

                      // Invalidate caregiver dashboard telemetry providers
                      ref.invalidate(selectedPatientGameHistoryProvider);
                      ref.invalidate(selectedPatientSevenDayActivityProvider);
                      ref.invalidate(caregiverSyncStatusProvider);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  // Attach listener for caregiver push notification tap deep linking
  final pushService = ref.watch(caregiverPushNotificationServiceProvider);
  final tapSub = pushService.onNotificationTapped.listen((payload) {
    debugPrint(
      '👉 Caregiver notification tapped: ${payload.notificationType} for patient: ${payload.patientId}',
    );
    final authState = ref.read(caregiverAuthProvider);
    if (authState.value != null) {
      if (payload.patientId != null && payload.patientId!.isNotEmpty) {
        final assigned = ref.read(assignedPatientsProvider).value;
        if (assigned != null) {
          final matched = assigned.where((p) => p.id == payload.patientId);
          if (matched.isNotEmpty) {
            ref.read(selectedPatientProvider.notifier).state = matched.first;
          }
        }
      }
      ref.invalidate(caregiverNotificationsProvider);
      ref.invalidate(caregiverNotificationsStreamProvider);
      router.go('/caregiver/dashboard');
    } else {
      router.go('/caregiver/login');
    }
  });

  ref.onDispose(() {
    tapSub.cancel();
  });

  return router;
});
