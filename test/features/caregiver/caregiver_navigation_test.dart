// ==============================================================================
// NIRVANA - Caregiver Navigation & Routing Tests
// Description: Validates GoRouter navigation between Onboarding, Home,
// Caregiver Portal Entry, Caregiver Login, Caregiver Dashboard, and Logout.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirvana/app/router/app_router.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/features/caregiver/caregiver.dart';
import 'package:nirvana/features/onboarding/providers/onboarding_provider.dart';
import 'package:nirvana/l10n/app_localizations.dart';

class MockCaregiverRepository implements ICaregiverRepository {
  final CaregiverProfile profile = const CaregiverProfile(
    id: 'cg-01',
    email: 'caregiver@nirvana.care',
    fullName: 'Sarah Jenkins',
    role: 'primary_caregiver',
  );

  final List<PatientSummary> patients = const [
    PatientSummary(
      id: 'p-01',
      fullName: 'Elena Rostova',
      relationship: 'Mother',
      primaryCaregiverId: 'cg-01',
    ),
  ];

  @override
  Future<CaregiverProfile> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async => profile;

  @override
  Future<CaregiverProfile> login({
    required String email,
    required String password,
  }) async => profile;

  @override
  Future<void> logout() async {}

  @override
  Future<CaregiverProfile?> getCurrentCaregiver() async => null;

  @override
  Future<PatientSummary> createPatient({
    required CreatePatientInput input,
    String? caregiverId,
  }) async {
    return PatientSummary(
      id: 'p-nav-01',
      fullName: input.fullName,
      preferredName: input.preferredName,
      relationship: input.relationship,
      primaryCaregiverId: caregiverId ?? profile.id,
      emergencyContactPhone: input.emergencyContactPhone,
    );
  }

  @override
  Future<List<PatientSummary>> getAssignedPatients(String caregiverId) async =>
      patients;

  @override
  Future<List<CaregiverGameRecord>> getGameHistory(String patientId) async =>
      [];

  @override
  Future<List<CaregiverReminderRecord>> getReminderStatus(
    String patientId,
  ) async => [];

  @override
  Future<List<DailyActivitySummary>> getSevenDayActivity(
    String patientId,
  ) async => [];

  @override
  Future<CaregiverSyncInfo> getSyncStatus(String patientId) async =>
      const CaregiverSyncInfo(
        pendingEventsCount: 0,
        isOnline: true,
        statusLabel: 'All activities synchronized',
      );
}

void main() {
  Widget createTestApp({required bool onboardingCompleted}) {
    return ProviderScope(
      overrides: [
        onboardingCompletedProvider.overrideWith(
          (ref) => OnboardingNotifier(initialCompleted: onboardingCompleted),
        ),
        caregiverRepositoryProvider.overrideWithValue(
          MockCaregiverRepository(),
        ),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final router = ref.watch(appRouterProvider);
          return MaterialApp.router(
            theme: ElderTheme.buildStandardTheme(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          );
        },
      ),
    );
  }

  group('Caregiver GoRouter Navigation Tests', () {
    testWidgets('Test 1: First launch -> Onboarding -> Home', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp(onboardingCompleted: false));
      await tester.pumpAndSettle();

      // Starts at onboarding step 1
      expect(find.text('1 / 3'), findsOneWidget);
      expect(find.text('A Gentle Companion'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // Step 1 -> Step 2
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('2 / 3'), findsOneWidget);

      // Step 2 -> Step 3
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('3 / 3'), findsOneWidget);

      // Step 3 -> Finish -> Home
      await tester.tap(find.text('Enter Nirvana'));
      await tester.pumpAndSettle();

      // Home Screen verified
      expect(find.text("Today's Activities"), findsOneWidget);
      expect(find.text('Caregiver Portal'), findsOneWidget);
    });

    testWidgets('Test 2: Home -> Caregiver Portal -> Caregiver Login', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp(onboardingCompleted: true));
      await tester.pumpAndSettle();

      // On Home Screen
      expect(find.text("Today's Activities"), findsOneWidget);
      final caregiverButton = find.text('Caregiver Portal');
      expect(caregiverButton, findsOneWidget);

      // Tap Caregiver Portal
      await tester.ensureVisible(caregiverButton);
      await tester.tap(caregiverButton);
      await tester.pumpAndSettle();

      // Caregiver Login Screen displayed
      expect(find.text('Caregiver & Family Portal'), findsOneWidget);
      expect(find.text('Welcome to Nirvana Care'), findsOneWidget);
      expect(find.text('Sign In to Dashboard'), findsOneWidget);
    });

    testWidgets('Test 3: Successful caregiver login -> Caregiver Dashboard', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp(onboardingCompleted: true));
      await tester.pumpAndSettle();

      // Navigate to Caregiver Login
      await tester.ensureVisible(find.text('Caregiver Portal'));
      await tester.tap(find.text('Caregiver Portal'));
      await tester.pumpAndSettle();

      // Tap Sign In to Dashboard
      final signInButton = find.text('Sign In to Dashboard');
      await tester.ensureVisible(signInButton);
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      // Caregiver Dashboard Screen displayed
      expect(find.text('Caregiver Dashboard'), findsOneWidget);
      expect(find.text('Welcome, Sarah Jenkins'), findsOneWidget);
      expect(find.textContaining('Elena Rostova'), findsOneWidget);
    });

    testWidgets('Test 4: Logout -> Caregiver Login', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp(onboardingCompleted: true));
      await tester.pumpAndSettle();

      // Go to Login and Sign in
      await tester.ensureVisible(find.text('Caregiver Portal'));
      await tester.tap(find.text('Caregiver Portal'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign In to Dashboard'));
      await tester.pumpAndSettle();

      expect(find.text('Caregiver Dashboard'), findsOneWidget);

      // Tap Sign Out icon button
      final logoutButton = find.byTooltip('Sign Out');
      expect(logoutButton, findsOneWidget);
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      // Navigates back to Caregiver Login
      expect(find.text('Caregiver & Family Portal'), findsOneWidget);
      expect(find.text('Sign In to Dashboard'), findsOneWidget);
    });

    testWidgets(
      'Test 5: Back navigation from Caregiver Login returns to Home',
      (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp(onboardingCompleted: true));
        await tester.pumpAndSettle();

        // Home Screen
        expect(find.text("Today's Activities"), findsOneWidget);

        // Go to Caregiver Login
        await tester.ensureVisible(find.text('Caregiver Portal'));
        await tester.tap(find.text('Caregiver Portal'));
        await tester.pumpAndSettle();

        expect(find.text('Caregiver & Family Portal'), findsOneWidget);

        // Tap back button
        final backButton = find.byTooltip('Back to Home');
        expect(backButton, findsOneWidget);
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        // Returned safely to Home Screen
        expect(find.text("Today's Activities"), findsOneWidget);
        expect(find.text('Caregiver Portal'), findsOneWidget);
      },
    );
  });
}
