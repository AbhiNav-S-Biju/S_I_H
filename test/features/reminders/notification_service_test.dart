// ==============================================================================
// NIRVANA - Notification Service Unit Tests
// Description: Tests reminder scheduling, cancellation, and action dispatching
// (Done, Snooze 15 min, Later today) without requiring real hardware.
// ==============================================================================

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirvana/features/reminders/models/reminder.dart';
import 'package:nirvana/features/reminders/models/reminder_action.dart';
import 'package:nirvana/features/reminders/models/reminder_log.dart';
import 'package:nirvana/features/reminders/repositories/reminder_repository.dart';
import 'package:nirvana/features/reminders/services/notification_service.dart';

class MockReminderRepository implements IReminderRepository {
  final List<String> completedCalls = [];
  final List<String> snoozedCalls = [];
  final List<String> laterTodayCalls = [];

  final Map<String, Reminder> store = {};

  @override
  Future<Reminder> createReminder(Reminder reminder) async {
    store[reminder.id] = reminder;
    return reminder;
  }

  @override
  Future<void> completeReminder(String reminderId, {String? patientId}) async {
    completedCalls.add(reminderId);
    if (store.containsKey(reminderId)) {
      store[reminderId] = store[reminderId]!.copyWith(isCompleted: true);
    }
  }

  @override
  Future<void> snoozeReminder(
    String reminderId, {
    Duration delay = const Duration(minutes: 15),
    String? patientId,
  }) async {
    snoozedCalls.add(reminderId);
    if (store.containsKey(reminderId)) {
      store[reminderId] = store[reminderId]!.copyWith(
        snoozedUntil: DateTime.now().add(delay),
      );
    }
  }

  @override
  Future<void> dismissReminderLaterToday(
    String reminderId, {
    String? patientId,
    DateTime? scheduledLater,
  }) async {
    laterTodayCalls.add(reminderId);
    if (store.containsKey(reminderId)) {
      store[reminderId] = store[reminderId]!.copyWith(
        snoozedUntil:
            scheduledLater ?? DateTime.now().add(const Duration(hours: 4)),
      );
    }
  }

  @override
  Future<void> deleteReminder(String reminderId, {String? patientId}) async {
    store.remove(reminderId);
  }

  @override
  Future<List<Reminder>> getActiveReminders(String patientId) async =>
      store.values.toList();

  @override
  Future<Reminder?> getReminderById(String reminderId) async =>
      store[reminderId];

  @override
  Future<List<ReminderLog>> getReminderLogs(String patientId) async => [];

  @override
  Future<Reminder> updateReminder(Reminder reminder) async {
    store[reminder.id] = reminder;
    return reminder;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockReminderRepository mockRepository;
  late NotificationService notificationService;

  setUp(() {
    mockRepository = MockReminderRepository();
    notificationService = NotificationService(
      reminderRepository: mockRepository,
    );
  });

  group('NotificationService Action Dispatching Tests', () {
    test(
      'handles action_done and calls completeReminder on repository',
      () async {
        final reminder = Reminder(
          id: 'rem-done-test',
          patientId: 'pat-1',
          title: 'Heart Medication',
          body: '1 tablet with water',
          scheduledAt: DateTime.now(),
          createdAt: DateTime.now(),
          notificationId: 501,
        );
        await mockRepository.createReminder(reminder);

        final response = NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotificationAction,
          actionId: NotificationActionIds.done,
          payload: 'rem-done-test',
        );

        await notificationService.handleNotificationResponse(response);

        expect(mockRepository.completedCalls, contains('rem-done-test'));
      },
    );

    test(
      'handles action_snooze_15 and calls snoozeReminder on repository',
      () async {
        final reminder = Reminder(
          id: 'rem-snooze-test',
          patientId: 'pat-1',
          title: 'Eye Drops',
          body: '2 drops in left eye',
          scheduledAt: DateTime.now(),
          createdAt: DateTime.now(),
          notificationId: 502,
        );
        await mockRepository.createReminder(reminder);

        final response = NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotificationAction,
          actionId: NotificationActionIds.snooze15,
          payload: 'rem-snooze-test',
        );

        await notificationService.handleNotificationResponse(response);

        expect(mockRepository.snoozedCalls, contains('rem-snooze-test'));
      },
    );

    test(
      'handles action_later_today and calls dismissReminderLaterToday on repository',
      () async {
        final reminder = Reminder(
          id: 'rem-later-test',
          patientId: 'pat-1',
          title: 'Gentle Stretches',
          body: '10 min chair yoga',
          scheduledAt: DateTime.now(),
          createdAt: DateTime.now(),
          notificationId: 503,
        );
        await mockRepository.createReminder(reminder);

        final response = NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotificationAction,
          actionId: NotificationActionIds.laterToday,
          payload: 'rem-later-test',
        );

        await notificationService.handleNotificationResponse(response);

        expect(mockRepository.laterTodayCalls, contains('rem-later-test'));
      },
    );

    test('gracefully ignores null or empty payload', () async {
      const response = NotificationResponse(
        notificationResponseType:
            NotificationResponseType.selectedNotificationAction,
        actionId: NotificationActionIds.done,
        payload: null,
      );

      await notificationService.handleNotificationResponse(response);

      expect(mockRepository.completedCalls.isEmpty, isTrue);
    });
  });
}
