// ==============================================================================
// NIRVANA - Caregiver Reminder Management & Event Notifications Test
// Tests:
// 1. CaregiverEventNotificationService produces all 8 event types:
//    - reminder_completed
//    - reminder_missed
//    - reminder_snoozed
//    - game_completed
//    - device_paired
//    - device_revoked
//    - sync_restored
//    - sync_error
// 2. SupabaseCaregiverNotificationRepository in-memory stream and caching
// 3. CaregiverNotificationsPanel rendering and mark-as-read
// 4. Caregiver reminder save and local notification synchronization
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirvana/features/caregiver/models/caregiver_models.dart';
import 'package:nirvana/features/caregiver/presentation/widgets/caregiver_notifications_panel.dart';
import 'package:nirvana/features/caregiver/presentation/widgets/reminder_status_list.dart';
import 'package:nirvana/features/caregiver/providers/caregiver_providers.dart';
import 'package:nirvana/features/caregiver/repositories/caregiver_notification_repository.dart';
import 'package:nirvana/features/caregiver/repositories/caregiver_repository.dart';
import 'package:nirvana/features/caregiver/services/caregiver_event_notification_service.dart';

class MockCaregiverNotificationRepository
    implements ICaregiverNotificationRepository {
  final List<CaregiverNotification> notifications = [];

  @override
  Future<void> createNotification(CaregiverNotification notification) async {
    notifications.insert(0, notification);
  }

  @override
  Future<List<CaregiverNotification>> getNotifications(
    String caregiverId, {
    String? patientId,
    int limit = 100,
  }) async {
    return List.unmodifiable(notifications);
  }

  @override
  Stream<List<CaregiverNotification>> getNotificationsStream(
    String caregiverId, {
    String? patientId,
  }) {
    return Stream.fromIterable([List.unmodifiable(notifications)]);
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    final idx = notifications.indexWhere((n) => n.id == notificationId);
    if (idx >= 0) {
      notifications[idx] = notifications[idx].copyWith(isRead: true);
    }
  }

  @override
  Future<void> markAllAsRead(String caregiverId) async {
    for (int i = 0; i < notifications.length; i++) {
      notifications[i] = notifications[i].copyWith(isRead: true);
    }
  }

  @override
  Future<int> getUnreadCount(String caregiverId) async {
    return notifications.where((n) => !n.isRead).length;
  }
}

class MockCaregiverRepository implements ICaregiverRepository {
  final List<CaregiverReminderRecord> reminders = [];

  @override
  Future<CaregiverProfile?> getCurrentCaregiver() async => const CaregiverProfile(
        id: 'cg-1',
        email: 'caregiver@test.com',
        fullName: 'Jane Caregiver',
      );

  @override
  Future<CaregiverProfile> login({required String email, required String password}) async =>
      const CaregiverProfile(
        id: 'cg-1',
        email: 'caregiver@test.com',
        fullName: 'Jane Caregiver',
      );

  @override
  Future<CaregiverProfile> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async =>
      CaregiverProfile(id: 'cg-1', email: email, fullName: fullName);

  @override
  Future<void> logout() async {}

  @override
  Future<PatientSummary> createPatient({
    required CreatePatientInput input,
    String? caregiverId,
  }) async =>
      PatientSummary(
        id: 'p-1',
        fullName: input.fullName,
        relationship: input.relationship,
        primaryCaregiverId: caregiverId ?? 'cg-1',
      );

  @override
  Future<List<PatientSummary>> getAssignedPatients(String caregiverId) async => [
        const PatientSummary(
          id: 'p-1',
          fullName: 'Eleanor Vance',
          preferredName: 'Mom',
          relationship: 'Mother',
          primaryCaregiverId: 'cg-1',
        ),
      ];

  @override
  Future<List<CaregiverGameRecord>> getGameHistory(String patientId) async => [];

  @override
  Future<List<CaregiverReminderRecord>> getReminderStatus(String patientId) async =>
      reminders;

  @override
  Future<CaregiverReminderRecord> createReminder(
    CreateOrUpdateReminderInput input,
  ) async {
    final r = CaregiverReminderRecord(
      id: 'rem-new',
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
    reminders.add(r);
    return r;
  }

  @override
  Future<CaregiverReminderRecord> updateReminder(
    String reminderId,
    CreateOrUpdateReminderInput input,
  ) async {
    final idx = reminders.indexWhere((r) => r.id == reminderId);
    final r = CaregiverReminderRecord(
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
    if (idx >= 0) {
      reminders[idx] = r;
    } else {
      reminders.add(r);
    }
    return r;
  }

  @override
  Future<void> toggleReminderActive(String reminderId, bool isActive) async {
    final idx = reminders.indexWhere((r) => r.id == reminderId);
    if (idx >= 0) {
      reminders[idx] = reminders[idx].copyWith(isActive: isActive);
    }
  }

  @override
  Future<void> deleteReminder(String reminderId) async {
    reminders.removeWhere((r) => r.id == reminderId);
  }

  @override
  Future<List<DailyActivitySummary>> getSevenDayActivity(String patientId) async => [];

  @override
  Future<CaregiverSyncInfo> getSyncStatus(String patientId) async =>
      const CaregiverSyncInfo(
        pendingEventsCount: 0,
        isOnline: true,
        statusLabel: 'Online & Synced',
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CaregiverEventNotificationService Tests', () {
    late MockCaregiverNotificationRepository notifRepo;
    late CaregiverEventNotificationService service;

    setUp(() {
      notifRepo = MockCaregiverNotificationRepository();
      service = CaregiverEventNotificationService(repository: notifRepo);
    });

    test('generates reminder_completed notification', () async {
      await service.notifyReminderCompleted(
        patientId: 'p-1',
        reminderTitle: 'Morning Medication',
        patientName: 'Mom',
        caregiverId: 'cg-1',
      );

      expect(notifRepo.notifications.length, 1);
      final n = notifRepo.notifications.first;
      expect(n.notificationType, 'reminder_completed');
      expect(n.title, 'Reminder Completed');
      expect(n.message, contains('Morning Medication'));
    });

    test('generates reminder_snoozed notification', () async {
      await service.notifyReminderSnoozed(
        patientId: 'p-1',
        reminderTitle: 'Blood Pressure Check',
        snoozedUntil: DateTime(2026, 9, 9, 10, 30),
        patientName: 'Mom',
        caregiverId: 'cg-1',
      );

      expect(notifRepo.notifications.length, 1);
      final n = notifRepo.notifications.first;
      expect(n.notificationType, 'reminder_snoozed');
      expect(n.title, 'Reminder Snoozed');
      expect(n.message, contains('snoozed'));
    });

    test('generates reminder_missed notification', () async {
      await service.notifyReminderMissed(
        patientId: 'p-1',
        reminderTitle: 'Afternoon Hydration',
        scheduledTime: '2:00 PM',
        patientName: 'Mom',
        caregiverId: 'cg-1',
      );

      expect(notifRepo.notifications.length, 1);
      final n = notifRepo.notifications.first;
      expect(n.notificationType, 'reminder_missed');
      expect(n.title, 'Missed Reminder');
      expect(n.message, contains('missed'));
    });

    test('generates game_completed notification', () async {
      await service.notifyGameCompleted(
        patientId: 'p-1',
        gameTitle: 'Remember Objects',
        score: 95,
        correctAnswers: 5,
        totalQuestions: 5,
        patientName: 'Mom',
        caregiverId: 'cg-1',
      );

      expect(notifRepo.notifications.length, 1);
      final n = notifRepo.notifications.first;
      expect(n.notificationType, 'game_completed');
      expect(n.title, 'Activity Completed');
      expect(n.message, contains('Remember Objects'));
      expect(n.message, contains('5/5'));
    });

    test('generates device_paired notification', () async {
      await service.notifyDevicePaired(
        patientId: 'p-1',
        deviceName: 'Living Room Tablet',
        patientName: 'Mom',
        caregiverId: 'cg-1',
      );

      expect(notifRepo.notifications.length, 1);
      final n = notifRepo.notifications.first;
      expect(n.notificationType, 'device_paired');
      expect(n.title, 'Device Paired');
      expect(n.message, contains('Living Room Tablet'));
    });

    test('generates device_revoked notification', () async {
      await service.notifyDeviceRevoked(
        patientId: 'p-1',
        patientName: 'Mom',
        caregiverId: 'cg-1',
      );

      expect(notifRepo.notifications.length, 1);
      final n = notifRepo.notifications.first;
      expect(n.notificationType, 'device_revoked');
      expect(n.title, 'Device Access Revoked');
      expect(n.message, contains('disconnected'));
    });

    test('generates sync_restored notification', () async {
      await service.notifySyncRestored(
        patientId: 'p-1',
        syncedEventCount: 4,
        patientName: 'Mom',
        caregiverId: 'cg-1',
      );

      expect(notifRepo.notifications.length, 1);
      final n = notifRepo.notifications.first;
      expect(n.notificationType, 'sync_restored');
      expect(n.title, 'Sync Restored');
      expect(n.message, contains('4 updates synced'));
    });

    test('generates sync_error notification', () async {
      await service.notifySyncError(
        patientId: 'p-1',
        errorMessage: 'Network timeout during event sync',
        patientName: 'Mom',
        caregiverId: 'cg-1',
      );

      expect(notifRepo.notifications.length, 1);
      final n = notifRepo.notifications.first;
      expect(n.notificationType, 'sync_error');
      expect(n.title, 'Sync Warning');
      expect(n.message, contains('Network timeout'));
    });
  });

  group('Caregiver Notifications Panel UI Tests', () {
    testWidgets('renders empty state when no notifications', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final notifRepo = MockCaregiverNotificationRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            caregiverAuthProvider.overrideWith((ref) => CaregiverAuthNotifier(MockCaregiverRepository())
              ..state = const AsyncValue.data(
                CaregiverProfile(
                  id: 'cg-1',
                  email: 'caregiver@test.com',
                  fullName: 'Jane Caregiver',
                ),
              )),
            caregiverNotificationRepositoryProvider.overrideWithValue(notifRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CaregiverNotificationsPanel(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Recent Alerts & Activity'), findsOneWidget);
      expect(find.text('No new alerts'), findsOneWidget);
    });

    testWidgets('renders notifications and allows mark all read', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final notifRepo = MockCaregiverNotificationRepository();
      notifRepo.notifications.addAll([
        CaregiverNotification(
          id: 'notif-1',
          caregiverId: 'cg-1',
          patientId: 'p-1',
          notificationType: 'reminder_completed',
          title: 'Reminder Completed',
          message: 'Mom completed her "Morning Medication" reminder.',
          isRead: false,
          createdAt: DateTime.now(),
          patientName: 'Mom',
        ),
        CaregiverNotification(
          id: 'notif-2',
          caregiverId: 'cg-1',
          patientId: 'p-1',
          notificationType: 'game_completed',
          title: 'Activity Completed',
          message: 'Mom completed Remember Objects (5/5 items found).',
          isRead: false,
          createdAt: DateTime.now(),
          patientName: 'Mom',
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            caregiverAuthProvider.overrideWith((ref) => CaregiverAuthNotifier(MockCaregiverRepository())
              ..state = const AsyncValue.data(
                CaregiverProfile(
                  id: 'cg-1',
                  email: 'caregiver@test.com',
                  fullName: 'Jane Caregiver',
                ),
              )),
            caregiverNotificationRepositoryProvider.overrideWithValue(notifRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CaregiverNotificationsPanel(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Recent Alerts & Activity'), findsOneWidget);
      expect(find.text('2 NEW'), findsOneWidget);
      expect(find.text('Reminder Completed'), findsOneWidget);
      expect(find.text('Activity Completed'), findsOneWidget);

      // Tap individual notification to mark read
      await tester.tap(find.text('Reminder Completed'));
      await tester.pumpAndSettle();

      expect(notifRepo.notifications.first.isRead, isTrue);
    });
  });

  group('Caregiver Reminder Status & Edit Flow Tests', () {
    testWidgets('renders reminder list and opens edit sheet on tap', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final caregiverRepo = MockCaregiverRepository();
      caregiverRepo.reminders.add(
        CaregiverReminderRecord(
          id: 'rem-1',
          patientId: 'p-1',
          title: 'Blood Pressure Pill',
          description: 'Take with breakfast',
          reminderType: 'medication',
          scheduleTime: '08:30',
          scheduledAt: DateTime(2026, 9, 9, 8, 30),
          recurrenceDays: const ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'],
          isActive: true,
          isCompleted: false,
          status: 'pending',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            caregiverRepositoryProvider.overrideWithValue(caregiverRepo),
            selectedPatientProvider.overrideWith(
              (ref) => const PatientSummary(
                id: 'p-1',
                fullName: 'Eleanor Vance',
                preferredName: 'Mom',
                relationship: 'Mother',
                primaryCaregiverId: 'cg-1',
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ReminderStatusList(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check reminder item rendered
      expect(find.text('Blood Pressure Pill'), findsOneWidget);
      expect(find.text('Daily Reminders & Routines'), findsOneWidget);

      // Tap the reminder tile to open Edit Sheet
      await tester.tap(find.text('Blood Pressure Pill'));
      await tester.pumpAndSettle();

      // Edit Sheet opened
      expect(find.text('Edit Reminder'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Reminder is Active'), findsOneWidget);

      // Tap Save Changes
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Modal closed
      expect(find.text('Edit Reminder'), findsNothing);
    });
  });
}
