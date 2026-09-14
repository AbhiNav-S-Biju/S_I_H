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
import '../../features/family_photos/presentation/family_photos_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/landing/landing.dart';
import '../../features/patient/patient.dart';
import '../../features/settings/presentation/language_selector_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/social_accounts/presentation/social_media_accounts_screen.dart';
import '../shell/elder_app_shell.dart';
import 'restoring_session_screen.dart';
import 'session_restore_gate.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
  final gamesNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'games');

  // Always start at the splash gate; the redirect below resolves the correct
  // destination (Welcome, caregiver dashboard, or patient home) once the
  // persisted session has been restored. This avoids flashing Welcome on
  // cold start for already-authenticated users.
  const initialLocation = '/startup';

  // Refresh the redirect whenever the auth/session state changes so that a
  // session restored *after* first frame still routes correctly.
  final refreshListenable = ref.watch(sessionRefreshListenableProvider);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final loc = state.matchedLocation;

      final authState = ref.read(caregiverAuthProvider);
      final authNotifier = ref.read(caregiverAuthProvider.notifier);
      // Authenticated when a caregiver profile was restored / logged in.
      final isAuthenticated = authState.value != null;
      // Still restoring the persisted session (no value yet and not an error).
      final isRestoring = authNotifier.isRestoring &&
          !authState.hasValue &&
          !authState.hasError;

      final isStartup = loc == '/startup';
      final isCaregiverRoute = loc.startsWith('/caregiver');
      final isProtectedCaregiver =
          loc == '/caregiver/dashboard' ||
          loc == '/caregiver/onboarding' ||
          loc == '/caregiver/add-patient';

      // 1. While the session is still being restored, hold on the splash so we
      //    never flash the Welcome screen for an authenticated/paired user.
      if (isRestoring) {
        return isStartup ? null : '/startup';
      }

      // 2. Resolve the startup gate now that restore is complete.
      if (isStartup) {
        if (isAuthenticated) return '/caregiver/dashboard';
        if (HiveDatabase.isDevicePaired) return '/patient/home';
        return '/'; // No session at all -> Welcome
      }

      // 3. Guard caregiver dashboard — redirect to login if not authenticated
      if (isProtectedCaregiver && !isAuthenticated) {
        return '/caregiver/login';
      }

      // 4. If already authenticated and visiting login/register, skip ahead
      if (isCaregiverRoute &&
          (loc == '/caregiver/login' || loc == '/caregiver/register') &&
          isAuthenticated) {
        return '/caregiver/dashboard';
      }

      // 5. If a caregiver session exists, the root Landing ("Welcome to
      //    NIRVANA") must not be shown — send them to their dashboard.
      if (loc == '/' && isAuthenticated) {
        return '/caregiver/dashboard';
      }

      // 6. If the device is already paired, patient entry routes go straight to
      //    the patient dashboard for a zero-password launch.
      if (HiveDatabase.isDevicePaired &&
          (loc == '/patient/welcome' || loc == '/patient/pairing')) {
        return '/patient/home';
      }

      // 7. A paired patient visiting the bare root Landing is also routed to
      //    their dashboard instead of the Welcome portal picker.
      if (loc == '/' && HiveDatabase.isDevicePaired) {
        return '/patient/home';
      }

      return null; // no redirect
    },
    routes: [
      // Startup gate / splash — shown while the session is restored.
      GoRoute(
        path: '/startup',
        builder: (context, state) => const RestoringSessionScreen(),
      ),

      // 0. Landing / Portal Selection
      GoRoute(path: '/', builder: (context, state) => const LandingScreen()),

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
        path: '/patient/social-accounts',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SocialMediaAccountsScreen(),
      ),
      GoRoute(
        path: '/patient/games',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => GamesHubScreen(
          onSessionCompleted: (session) async {
            debugPrint('Patient Games — Session Completed: $session');

            final pairedId =
                HiveDatabase.pairedPatientId ??
                HiveDatabase.currentPatientSession?.patientId;

            if (pairedId != null && pairedId.isNotEmpty) {
              final deviceId = HiveDatabase.currentPatientSession?.deviceId;

              await ref
                  .read(gameSessionRepositoryProvider)
                  .recordGameSession(
                    session: session,
                    patientId: pairedId,
                    deviceId: deviceId,
                  );

              // A notification failure must never prevent the dashboard from
              // refreshing, so keep it isolated from the save/invalidate flow.
              try {
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
              } catch (e) {
                debugPrint('⚠️ Game completion notification failed: $e');
              }

              ref.invalidate(selectedPatientGameHistoryProvider);
              ref.invalidate(selectedPatientSevenDayActivityProvider);
              ref.invalidate(caregiverSyncStatusProvider);
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
        path: '/patient/family-photos',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const FamilyPhotosScreen(),
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
                    final pairedId =
                        HiveDatabase.pairedPatientId ??
                        HiveDatabase.currentPatientSession?.patientId;
                    final assigned = ref.read(assignedPatientsProvider).value;

                    final effectivePatientId =
                        selected?.id ??
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
                            deviceId:
                                HiveDatabase.currentPatientSession?.deviceId,
                          );

                      // Dispatch caregiver event notification. Isolated so a
                      // notification failure cannot block the dashboard refresh.
                      try {
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
                      } catch (e) {
                        debugPrint('⚠️ Game completion notification failed: $e');
                      }

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
