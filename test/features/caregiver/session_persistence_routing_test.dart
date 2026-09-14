// ==============================================================================
// NIRVANA - Session Persistence & Startup Routing Tests
// Description: Verifies that an already-authenticated caregiver session
// restored from persistence bypasses the Welcome screen and lands on the
// caregiver dashboard, and that logout returns to Welcome.
//
// These cover validation flows:
//   B/C/D. Authenticated session restored -> dashboard (no Welcome flash)
//   E.     Explicit logout               -> Welcome
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirvana/app/router/app_router.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/features/caregiver/caregiver.dart';
import 'package:nirvana/features/onboarding/providers/onboarding_provider.dart';
import 'package:nirvana/l10n/app_localizations.dart';

/// A repository that simulates a *restored* caregiver session: the persisted
/// Supabase session is read back and returns a valid profile on startup.
class _RestoredSessionCaregiverRepository implements ICaregiverRepository {
  _RestoredSessionCaregiverRepository({required this.persisted});

  final CaregiverProfile? persisted;
  CaregiverProfile? _current;
  bool loggedOut = false;

  static const profile = CaregiverProfile(
    id: 'cg-restored',
    email: 'caregiver@nirvana.care',
    fullName: 'Sarah Jenkins',
    role: 'primary_caregiver',
  );

  @override
  Future<CaregiverProfile?> getCurrentCaregiver() async {
    _current ??= loggedOut ? null : persisted;
    return _current;
  }

  @override
  Future<CaregiverProfile> login({
    required String email,
    required String password,
  }) async {
    _current = profile;
    return profile;
  }

  @override
  Future<CaregiverProfile> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async => profile;

  @override
  Future<void> logout() async {
    loggedOut = true;
    _current = null;
  }

  @override
  Future<List<PatientSummary>> getAssignedPatients(String caregiverId) async =>
      const [
        PatientSummary(
          id: 'p-01',
          fullName: 'Elena Rostova',
          relationship: 'Mother',
          primaryCaregiverId: 'cg-restored',
        ),
      ];

  @override
  Future<PatientSummary> createPatient({
    required CreatePatientInput input,
    String? caregiverId,
  }) async => PatientSummary(
    id: 'p-new',
    fullName: input.fullName,
    preferredName: input.preferredName,
    relationship: input.relationship,
    primaryCaregiverId: caregiverId ?? profile.id,
  );

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
  ) async => CaregiverReminderRecord(
    id: 'r-1',
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

  @override
  Future<CaregiverReminderRecord> updateReminder(
    String reminderId,
    CreateOrUpdateReminderInput input,
  ) async => CaregiverReminderRecord(
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

/// Pumps several frames so async session restore + redirect settle, without
/// relying on [pumpAndSettle] (the dashboard runs long-lived animations and
/// realtime streams that never "settle").
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget _createApp(_RestoredSessionCaregiverRepository repository) {
  return ProviderScope(
    overrides: [
      onboardingCompletedProvider.overrideWith(
        (ref) => OnboardingNotifier(initialCompleted: true),
      ),
      caregiverRepositoryProvider.overrideWithValue(repository),
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

void main() {
  group('Session persistence startup routing', () {
    testWidgets(
      'B/C/D: restored caregiver session opens the dashboard, not Welcome',
      (WidgetTester tester) async {
        final repo = _RestoredSessionCaregiverRepository(
          persisted: _RestoredSessionCaregiverRepository.profile,
        );

        await tester.pumpWidget(_createApp(repo));
        await _settle(tester);

        // Should land directly on the caregiver dashboard.
        expect(find.text('Caregiver Dashboard'), findsOneWidget);
        expect(find.text('Welcome to NIRVANA'), findsNothing);
      },
    );

    testWidgets('A: no persisted session opens the Welcome screen', (
      WidgetTester tester,
    ) async {
      final repo = _RestoredSessionCaregiverRepository(persisted: null);

      await tester.pumpWidget(_createApp(repo));
      await _settle(tester);

      expect(find.text('Welcome to NIRVANA'), findsOneWidget);
      expect(find.text('Caregiver Dashboard'), findsNothing);
    });

    testWidgets('E: explicit logout returns to the Welcome screen', (
      WidgetTester tester,
    ) async {
      final repo = _RestoredSessionCaregiverRepository(
        persisted: _RestoredSessionCaregiverRepository.profile,
      );

      await tester.pumpWidget(_createApp(repo));
      await _settle(tester);

      expect(find.text('Caregiver Dashboard'), findsOneWidget);

      final logoutButton = find.byTooltip('Sign Out');
      expect(logoutButton, findsOneWidget);
      await tester.tap(logoutButton);
      await _settle(tester);

      expect(repo.loggedOut, isTrue);
      expect(find.text('Welcome to NIRVANA'), findsOneWidget);
      expect(find.text('Caregiver Dashboard'), findsNothing);
    });
  });
}
