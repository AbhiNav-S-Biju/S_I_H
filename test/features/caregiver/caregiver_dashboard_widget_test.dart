// ==============================================================================
// NIRVANA - Caregiver Dashboard & Login Widget Tests
// Description: Widget tests for Caregiver Login, Patient Selector, Metric Cards,
// 7-day Activity View, and Reminder / Game History Lists.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nirvana/features/caregiver/caregiver.dart';

class StubCaregiverRepository implements ICaregiverRepository {
  final CaregiverProfile profile = const CaregiverProfile(
    id: 'cg-01',
    email: 'caregiver@nirvana.care',
    fullName: 'Sarah Jenkins',
  );

  final List<PatientSummary> patients = const [
    PatientSummary(
      id: 'p-01',
      fullName: 'Elena Rostova',
      relationship: 'Mother',
      primaryCaregiverId: 'cg-01',
    ),
    PatientSummary(
      id: 'p-02',
      fullName: 'Arthur Pendelton',
      relationship: 'Father',
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
  Future<CaregiverProfile?> getCurrentCaregiver() async => profile;

  @override
  Future<PatientSummary> createPatient({
    required CreatePatientInput input,
    String? caregiverId,
  }) async {
    return PatientSummary(
      id: 'p-new-01',
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
  Future<List<CaregiverGameRecord>> getGameHistory(String patientId) async => [
    CaregiverGameRecord(
      id: 'g-1',
      gameTitle: 'Remember Objects',
      gameType: 'remember_objects',
      difficulty: 'easy',
      score: 350,
      durationSeconds: 15,
      correctCount: 3,
      totalCount: 3,
      playedAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  @override
  Future<List<CaregiverReminderRecord>> getReminderStatus(
    String patientId,
  ) async => [
    CaregiverReminderRecord(
      id: 'r-1',
      title: 'Morning Medicine',
      scheduledAt: DateTime.now(),
      isCompleted: true,
      completedAt: DateTime.now(),
      lastAction: 'done',
    ),
  ];

  @override
  Future<CaregiverReminderRecord> createReminder(
    CreateOrUpdateReminderInput input,
  ) async {
    return CaregiverReminderRecord(
      id: 'r-new',
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
  ) async => [
    DailyActivitySummary(
      date: DateTime.now(),
      dayLabel: 'Mon',
      gamesCompleted: 2,
      remindersCompleted: 3,
      totalActivities: 5,
    ),
    DailyActivitySummary(
      date: DateTime.now().subtract(const Duration(days: 1)),
      dayLabel: 'Sun',
      gamesCompleted: 1,
      remindersCompleted: 2,
      totalActivities: 3,
    ),
  ];

  @override
  Future<CaregiverSyncInfo> getSyncStatus(String patientId) async =>
      const CaregiverSyncInfo(
        pendingEventsCount: 0,
        isOnline: true,
        statusLabel: 'All activities synchronized',
      );
}

class StubPairingRepository implements IPairingRepository {
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

  @override
  Future<PatientContactInfo> getPatientContact(String patientId) async =>
      PatientContactInfo(
        patientId: patientId,
        patientName: 'Loved One',
        patientPhone: '+91 98765 43210',
      );

  @override
  Future<PasscodeSmsResult> sendPasscodeSms({
    required String patientId,
    required String code,
    String? pairingCodeId,
  }) async => const PasscodeSmsResult(
    status: PasscodeSmsStatus.sent,
    sentToMasked: '****3210',
  );
}

void main() {
  // Minimal GoRouter so context.go() / context.pop() work in widget tests.
  GoRouter buildRouter(Widget screen) {
    return GoRouter(
      initialLocation: '/caregiver/login',
      routes: [
        GoRoute(path: '/caregiver/login', builder: (_, __) => screen),
        GoRoute(
          path: '/caregiver/dashboard',
          builder: (_, __) => const CaregiverDashboardScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(body: Text('Home')),
        ),
      ],
    );
  }

  Widget buildRoutedWidget({
    required Widget screen,
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        pairingRepositoryProvider.overrideWithValue(StubPairingRepository()),
        ...overrides,
      ],
      child: Consumer(
        builder: (context, ref, _) =>
            MaterialApp.router(routerConfig: buildRouter(screen)),
      ),
    );
  }

  Widget buildTestableWidget({
    required Widget child,
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        pairingRepositoryProvider.overrideWithValue(StubPairingRepository()),
        ...overrides,
      ],
      child: MaterialApp(home: child),
    );
  }

  group('CaregiverLoginScreen Widget Tests', () {
    testWidgets('renders login fields and handles sign in action', (
      tester,
    ) async {
      final stubRepo = StubCaregiverRepository();

      // Use a routed widget so context.go('/caregiver/dashboard') works
      await tester.pumpWidget(
        buildRoutedWidget(
          screen: const CaregiverLoginScreen(),
          overrides: [caregiverRepositoryProvider.overrideWithValue(stubRepo)],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Caregiver & Family Portal'), findsOneWidget);
      expect(find.text('Welcome to Nirvana Care'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Sign In to Dashboard'), findsOneWidget);

      // Tap Sign in — navigates to /caregiver/dashboard via GoRouter
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

      // Should now be on the Caregiver Dashboard
      expect(find.text('Caregiver Dashboard'), findsOneWidget);
    });
  });

  group('CaregiverDashboardScreen Widget Tests', () {
    testWidgets(
      'renders patient selector, sync status, metrics, and activity charts',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final stubRepo = StubCaregiverRepository();

        await tester.pumpWidget(
          buildTestableWidget(
            child: const CaregiverDashboardScreen(),
            overrides: [
              caregiverRepositoryProvider.overrideWithValue(stubRepo),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // Header & Dashboard title
        expect(find.text('Caregiver Dashboard'), findsOneWidget);

        // Patient selector
        expect(find.text('Viewing Activity For'), findsOneWidget);
        expect(find.text('Elena Rostova (Mother)'), findsOneWidget);

        // Sync status card
        expect(find.textContaining('Sync status:'), findsOneWidget);
        expect(find.text('All activities synchronized'), findsOneWidget);

        // Metrics
        expect(find.text('Games completed'), findsOneWidget);
        expect(find.text('Reminder completion'), findsOneWidget);
        expect(find.text('Activities completed'), findsOneWidget);

        // 7-day activity chart
        expect(find.text('7-Day Activity View'), findsOneWidget);

        // Reminder & Game sections live on the Reminders tab.
        await tester.tap(find.text('Reminders').last);
        await tester.pumpAndSettle();
        expect(find.text('Reminder Status'), findsOneWidget);
        expect(find.text('Morning Medicine'), findsOneWidget);
        expect(find.text('Recent Activity'), findsOneWidget);
        expect(find.text('Remember Objects'), findsOneWidget);
      },
    );
  });
}
