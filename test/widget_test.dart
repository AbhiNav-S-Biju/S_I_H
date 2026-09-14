import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirvana/features/caregiver/models/caregiver_models.dart';
import 'package:nirvana/features/caregiver/providers/caregiver_providers.dart';
import 'package:nirvana/features/caregiver/repositories/caregiver_repository.dart';
import 'package:nirvana/features/games/games.dart';
import 'package:nirvana/main.dart';

import 'package:nirvana/l10n/app_localizations.dart';

/// A caregiver repository that reports no signed-in session and never touches
/// Hive/Supabase, so the app's startup restore path runs cleanly in tests.
class _NoSessionCaregiverRepository implements ICaregiverRepository {
  @override
  Future<CaregiverProfile?> getCurrentCaregiver() async => null;

  @override
  Future<CaregiverProfile> login({
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<CaregiverProfile> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async => throw UnimplementedError();

  @override
  Future<void> logout() async {}

  @override
  Future<PatientSummary> createPatient({
    required CreatePatientInput input,
    String? caregiverId,
  }) async => throw UnimplementedError();

  @override
  Future<List<PatientSummary>> getAssignedPatients(String caregiverId) async =>
      const [];

  @override
  Future<List<CaregiverGameRecord>> getGameHistory(String patientId) async =>
      const [];

  @override
  Future<List<CaregiverReminderRecord>> getReminderStatus(
    String patientId,
  ) async => const [];

  @override
  Future<CaregiverReminderRecord> createReminder(
    CreateOrUpdateReminderInput input,
  ) async => throw UnimplementedError();

  @override
  Future<CaregiverReminderRecord> updateReminder(
    String reminderId,
    CreateOrUpdateReminderInput input,
  ) async => throw UnimplementedError();

  @override
  Future<void> toggleReminderActive(String reminderId, bool isActive) async {}

  @override
  Future<void> deleteReminder(String reminderId) async {}

  @override
  Future<List<DailyActivitySummary>> getSevenDayActivity(
    String patientId,
  ) async => const [];

  @override
  Future<CaregiverSyncInfo> getSyncStatus(String patientId) async =>
      const CaregiverSyncInfo(
        pendingEventsCount: 0,
        isOnline: true,
        statusLabel: 'All activities synchronized',
      );
}

void main() {
  testWidgets('App smoke test launches GamesHubScreen directly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GamesHubScreen(),
        ),
      ),
    );

    expect(find.text('Daily Activities'), findsOneWidget);
  });

  testWidgets('NirvanaApp smoke test launches with ProviderScope and router', (
    WidgetTester tester,
  ) async {
    // Override the caregiver repository so the app's startup session-restore
    // path does not require Hive/Supabase in the test environment. With no
    // signed-in session, the router should resolve to the Welcome screen.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          caregiverRepositoryProvider.overrideWithValue(
            _NoSessionCaregiverRepository(),
          ),
        ],
        child: const NirvanaApp(),
      ),
    );

    // The app starts on a splash gate while the persisted session is restored.
    // Pump a fixed number of frames rather than pumpAndSettle(), because the
    // splash spinner animates indefinitely and would otherwise never settle.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Welcome to NIRVANA'), findsOneWidget);
    expect(find.text('Patient Portal'), findsOneWidget);
    expect(find.text('Caregiver Portal'), findsOneWidget);
  });
}
