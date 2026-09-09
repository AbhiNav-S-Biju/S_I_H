// ==============================================================================
// NIRVANA - Caregiver Patient Onboarding Widget Tests
// Description: Tests multi-step patient registration wizard, validation,
// visual comfort settings, routine reminder configuration, and submission.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nirvana/features/caregiver/caregiver.dart';

class MockCaregiverRepository implements ICaregiverRepository {
  final CaregiverProfile profile = const CaregiverProfile(
    id: 'cg-mock-01',
    email: 'caregiver@nirvana.care',
    fullName: 'Jane Doe',
  );

  final List<PatientSummary> patients = [];

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
  Future<CaregiverProfile?> getCurrentCaregiver() async => profile;

  @override
  Future<PatientSummary> createPatient({
    required CreatePatientInput input,
    String? caregiverId,
  }) async {
    final patient = PatientSummary(
      id: 'patient-test-01',
      fullName: input.fullName,
      preferredName: input.preferredName,
      relationship: input.relationship,
      primaryCaregiverId: caregiverId ?? profile.id,
      emergencyContactPhone: input.emergencyContactPhone,
    );
    patients.add(patient);
    return patient;
  }

  @override
  Future<List<PatientSummary>> getAssignedPatients(String caregiverId) async =>
      patients;

  @override
  Future<List<CaregiverGameRecord>> getGameHistory(String patientId) async => [];

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
        statusLabel: 'All synchronized',
      );
}

void main() {
  late MockCaregiverRepository mockRepo;

  setUp(() {
    mockRepo = MockCaregiverRepository();
  });

  Widget createTestWidget() {
    final router = GoRouter(
      initialLocation: '/caregiver/onboarding',
      routes: [
        GoRoute(
          path: '/caregiver/onboarding',
          builder: (context, state) => const CaregiverPatientOnboardingScreen(),
        ),
        GoRoute(
          path: '/caregiver/dashboard',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Caregiver Dashboard Screen')),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        caregiverRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('Caregiver Patient Onboarding Wizard Tests', () {
    testWidgets('renders step 1 with Patient Information fields', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Add Loved One'), findsOneWidget);
      expect(find.text('Patient Information'), findsOneWidget);
      expect(find.byKey(const Key('patient_full_name_field')), findsOneWidget);
      expect(find.byKey(const Key('patient_preferred_name_field')), findsOneWidget);
      expect(find.byKey(const Key('patient_emergency_phone_field')), findsOneWidget);
      expect(find.text('Relationship to Caregiver *'), findsOneWidget);
    });

    testWidgets('validates required name field before proceeding to step 2', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final continueButton = find.byKey(const Key('patient_onboarding_next_button'));
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter the patient\'s name'), findsOneWidget);
      expect(find.text('Visual & Comfort Preferences'), findsNothing);
    });

    testWidgets('navigates through all steps and completes patient creation', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Step 1: Fill patient info
      await tester.enterText(
        find.byKey(const Key('patient_full_name_field')),
        'Eleanor Vance',
      );
      await tester.enterText(
        find.byKey(const Key('patient_preferred_name_field')),
        'Ellie',
      );
      await tester.enterText(
        find.byKey(const Key('patient_emergency_phone_field')),
        '+1 555-9876',
      );
      await tester.pumpAndSettle();

      // Step 1 -> Step 2
      final nextButton = find.byKey(const Key('patient_onboarding_next_button'));
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      expect(find.text('Visual & Comfort Preferences'), findsOneWidget);
      expect(find.text('High Contrast Mode'), findsOneWidget);
      expect(find.text('Audio Prompt Guidance'), findsOneWidget);

      // Step 2 -> Step 3
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      expect(find.text('Daily Routine & Reminders'), findsOneWidget);
      expect(find.text('Morning Medication'), findsOneWidget);
      expect(find.text('Afternoon Hydration'), findsOneWidget);

      // Step 3 -> Step 4
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      expect(find.text('Pair Patient Device'), findsOneWidget);
      expect(find.text('Finish & Save Patient'), findsOneWidget);

      // Finish & Save
      await tester.tap(find.text('Finish & Save Patient'));
      await tester.pumpAndSettle();

      // Verify success dialog
      expect(find.text('Patient Onboarded!'), findsOneWidget);
      expect(find.text('Go to Dashboard'), findsOneWidget);

      // Tap Go to Dashboard
      await tester.tap(find.text('Go to Dashboard'));
      await tester.pumpAndSettle();

      expect(find.text('Caregiver Dashboard Screen'), findsOneWidget);
    });
  });
}
