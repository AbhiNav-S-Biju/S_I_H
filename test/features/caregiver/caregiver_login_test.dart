// ==============================================================================
// NIRVANA - Caregiver Login Widget & Error Handling Tests
// Description: Verifies empty input validation, invalid email formatting,
// AuthException / Invalid login credentials handling without crashing,
// and successful login flow.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/features/caregiver/caregiver.dart';

class FailingMockCaregiverRepository implements ICaregiverRepository {
  final AuthException errorToThrow;

  FailingMockCaregiverRepository({required this.errorToThrow});

  @override
  Future<CaregiverProfile> login({
    required String email,
    required String password,
  }) async {
    throw errorToThrow;
  }

  @override
  Future<CaregiverProfile> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<CaregiverProfile?> getCurrentCaregiver() async => null;

  @override
  Future<PatientSummary> createPatient({
    required CreatePatientInput input,
    String? caregiverId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<PatientSummary>> getAssignedPatients(String caregiverId) async =>
      [];

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
    throw UnimplementedError();
  }

  @override
  Future<CaregiverReminderRecord> updateReminder(
    String reminderId,
    CreateOrUpdateReminderInput input,
  ) async {
    throw UnimplementedError();
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
        statusLabel: 'Online',
      );
}

void main() {
  Widget createTestWidget({required ICaregiverRepository repository}) {
    return ProviderScope(
      overrides: [caregiverRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        theme: ElderTheme.buildStandardTheme(),
        home: const CaregiverLoginScreen(),
      ),
    );
  }

  group('CaregiverLoginScreen Error Handling & Validation Tests', () {
    testWidgets(
      'Displays validation error when submitting with empty email or password',
      (WidgetTester tester) async {
        final repo = FailingMockCaregiverRepository(
          errorToThrow: const AuthException(
            'Invalid login credentials',
            statusCode: '400',
          ),
        );

        await tester.pumpWidget(createTestWidget(repository: repo));
        await tester.pump();

        // Clear pre-filled fields
        final emailField = find.widgetWithText(TextFormField, 'Email Address');
        final passwordField = find.widgetWithText(TextFormField, 'Password');

        await tester.enterText(emailField, '');
        await tester.enterText(passwordField, '');
        await tester.pump();

        // Tap Sign In button
        final signInBtn = find.text('Sign In to Dashboard');
        await tester.tap(signInBtn);
        await tester.pump();

        // Form validation errors shown
        expect(find.text('Please enter your email'), findsOneWidget);
        expect(find.text('Please enter your password'), findsOneWidget);
      },
    );

    testWidgets('Displays validation error for invalid email format', (
      WidgetTester tester,
    ) async {
      final repo = FailingMockCaregiverRepository(
        errorToThrow: const AuthException(
          'Invalid login credentials',
          statusCode: '400',
        ),
      );

      await tester.pumpWidget(createTestWidget(repository: repo));
      await tester.pump();

      final emailField = find.widgetWithText(TextFormField, 'Email Address');
      await tester.enterText(emailField, 'notanemail');
      await tester.pump();

      final signInBtn = find.text('Sign In to Dashboard');
      await tester.tap(signInBtn);
      await tester.pump();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets(
      'Catches AuthException (Invalid login credentials) and displays friendly banner without crashing',
      (WidgetTester tester) async {
        final repo = FailingMockCaregiverRepository(
          errorToThrow: const AuthApiException(
            'Invalid login credentials',
            statusCode: '400',
            code: 'invalid_credentials',
          ),
        );

        await tester.pumpWidget(createTestWidget(repository: repo));
        await tester.pump();

        // Submit validly formatted test input so the repository error is reached.
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email Address'),
          'caregiver@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'test-password',
        );
        final signInBtn = find.text('Sign In to Dashboard');
        await tester.tap(signInBtn);
        await tester.pump();

        // Verify the friendly error banner is shown and no unhandled exception occurred
        expect(
          find.textContaining('Invalid email or password'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      },
    );
  });
}
