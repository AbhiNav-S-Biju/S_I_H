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
  Future<CaregiverReminderRecord> createReminder(
    CreateOrUpdateReminderInput input,
  ) async {
    return CaregiverReminderRecord(
      id: 'r-mock',
      patientId: input.patientId,
      title: input.title,
      description: input.description,
      reminderType: input.reminderType,
      scheduleTime: input.scheduleTime,
      scheduledAt: DateTime.now(),
      recurrenceDays: input.recurrenceDays,
      isActive: input.isActive,
      isCompleted: false,
    );
  }

  @override
  Future<CaregiverReminderRecord> updateReminder(
    String reminderId,
    CreateOrUpdateReminderInput input,
  ) async {
    return CaregiverReminderRecord(
      id: reminderId,
      patientId: input.patientId,
      title: input.title,
      description: input.description,
      reminderType: input.reminderType,
      scheduleTime: input.scheduleTime,
      scheduledAt: DateTime.now(),
      recurrenceDays: input.recurrenceDays,
      isActive: input.isActive,
      isCompleted: false,
    );
  }

  @override
  Future<void> toggleReminderActive(String reminderId, bool isActive) async {}

  @override
  Future<void> deleteReminder(String reminderId) async {}

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

class MockPairingRepository implements IPairingRepository {
  @override
  Future<PairingCodeInfo> generatePairingCode(
    String patientId, {
    int validityMinutes = 15,
  }) async {
    return PairingCodeInfo(
      code: '123456',
      expiresAt: DateTime.now().add(Duration(minutes: validityMinutes)),
      patientId: patientId,
    );
  }

  @override
  Future<PatientDeviceSummary?> getLinkedDevice(String patientId) async => null;

  @override
  Future<void> revokeDevice(String deviceId) async {}
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
        pairingRepositoryProvider.overrideWithValue(MockPairingRepository()),
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
    testWidgets(
      'Test 1: First launch -> Landing -> Patient Portal -> Welcome Screen',
      (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp(onboardingCompleted: false));
        await tester.pumpAndSettle();

        // Starts at Landing Screen
        expect(find.text('Welcome to NIRVANA'), findsOneWidget);
        expect(find.text('Enter Patient Portal'), findsOneWidget);
        expect(find.text('Enter Caregiver Portal'), findsOneWidget);

        // Tap Enter Patient Portal -> Goes to Patient Welcome (device not paired)
        final patientBtn = find.text('Enter Patient Portal');
        await tester.ensureVisible(patientBtn);
        await tester.tap(patientBtn);
        await tester.pumpAndSettle();

        // Verified Patient Welcome Screen
        expect(find.text("Let's connect this device"), findsOneWidget);
        expect(find.text('NIRVANA'), findsOneWidget);
      },
    );

    testWidgets('Test 2: Landing -> Caregiver Portal -> Caregiver Login', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp(onboardingCompleted: true));
      await tester.pumpAndSettle();

      // On Landing Screen
      expect(find.text('Welcome to NIRVANA'), findsOneWidget);
      final caregiverButton = find.text('Enter Caregiver Portal');
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

      // Navigate to Caregiver Login from Landing
      final caregiverBtn = find.text('Enter Caregiver Portal');
      await tester.ensureVisible(caregiverBtn);
      await tester.tap(caregiverBtn);
      await tester.pumpAndSettle();

      // Tap Sign In to Dashboard
      final signInButton = find.text('Sign In to Dashboard');
      await tester.ensureVisible(signInButton);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email Address'),
        'caregiver@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'test-password',
      );
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      // Caregiver Dashboard Screen displayed
      expect(find.text('Caregiver Dashboard'), findsOneWidget);
      expect(find.text('Welcome, Sarah Jenkins'), findsOneWidget);
      expect(find.textContaining('Elena Rostova'), findsOneWidget);
    });

    testWidgets('Test 4: Logout -> Landing Screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp(onboardingCompleted: true));
      await tester.pumpAndSettle();

      // Go to Login and Sign in
      final caregiverBtn = find.text('Enter Caregiver Portal');
      await tester.ensureVisible(caregiverBtn);
      await tester.tap(caregiverBtn);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email Address'),
        'caregiver@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'test-password',
      );
      await tester.tap(find.text('Sign In to Dashboard'));
      await tester.pumpAndSettle();

      expect(find.text('Caregiver Dashboard'), findsOneWidget);

      // Tap Sign Out icon button
      final logoutButton = find.byTooltip('Sign Out');
      expect(logoutButton, findsOneWidget);
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      // Navigates directly back to Landing Screen
      expect(find.text('Welcome to NIRVANA'), findsOneWidget);
      expect(find.text('Enter Caregiver Portal'), findsOneWidget);
    });

    testWidgets(
      'Test 5: Back navigation from Caregiver Login returns to Landing Screen',
      (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp(onboardingCompleted: true));
        await tester.pumpAndSettle();

        // Landing Screen
        expect(find.text('Welcome to NIRVANA'), findsOneWidget);

        // Go to Caregiver Login
        final caregiverBtn = find.text('Enter Caregiver Portal');
        await tester.ensureVisible(caregiverBtn);
        await tester.tap(caregiverBtn);
        await tester.pumpAndSettle();

        expect(find.text('Caregiver & Family Portal'), findsOneWidget);

        // Tap back button
        final backButton = find.byTooltip('Back to Landing');
        expect(backButton, findsOneWidget);
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        // Returned safely to Landing Screen
        expect(find.text('Welcome to NIRVANA'), findsOneWidget);
        expect(find.text('Enter Patient Portal'), findsOneWidget);
      },
    );
  });
}
