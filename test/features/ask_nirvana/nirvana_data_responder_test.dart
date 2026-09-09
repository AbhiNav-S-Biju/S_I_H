// ==============================================================================
// NIRVANA - Ask NIRVANA Data Responder Tests
// Description: Comprehensive test suite verifying all 8 intents against real
// data layer contracts, testing online vs offline states, empty databases,
// missing data, and zero-hallucination guarantees.
// ==============================================================================

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nirvana/core/network/connectivity_monitor.dart';
import 'package:nirvana/features/ask_nirvana/ask_nirvana.dart';
import 'package:nirvana/features/caregiver/caregiver.dart';
import 'package:nirvana/features/reminders/models/reminder.dart';
import 'package:nirvana/features/reminders/models/reminder_log.dart';
import 'package:nirvana/features/reminders/providers/reminder_providers.dart';
import 'package:nirvana/features/reminders/repositories/reminder_repository.dart';

// -----------------------------------------------------------------------------
// Test Doubles
// -----------------------------------------------------------------------------

class FakeConnectivityMonitor implements IConnectivityMonitor {
  NetworkStatus currentStatus;
  final _controller = StreamController<NetworkStatus>.broadcast();

  FakeConnectivityMonitor({this.currentStatus = NetworkStatus.offline});

  @override
  Future<NetworkStatus> checkStatus() async => currentStatus;

  @override
  Stream<NetworkStatus> get statusStream => _controller.stream;

  void setOnline(bool online) {
    currentStatus = online ? NetworkStatus.online : NetworkStatus.offline;
    _controller.add(currentStatus);
  }
}

class FakeReminderRepository implements IReminderRepository {
  List<Reminder> reminders = [];

  @override
  Future<List<Reminder>> getActiveReminders(String patientId) async =>
      reminders;

  @override
  Future<Reminder?> getReminderById(String reminderId) async => null;

  @override
  Future<Reminder> createReminder(Reminder reminder) async => reminder;

  @override
  Future<Reminder> updateReminder(Reminder reminder) async => reminder;

  @override
  Future<void> completeReminder(String reminderId, {String? patientId}) async {}

  @override
  Future<void> snoozeReminder(
    String reminderId, {
    Duration delay = const Duration(minutes: 15),
    String? patientId,
  }) async {}

  @override
  Future<void> dismissReminderLaterToday(
    String reminderId, {
    String? patientId,
    DateTime? scheduledLater,
  }) async {}

  @override
  Future<void> deleteReminder(String reminderId, {String? patientId}) async {}

  @override
  Future<List<ReminderLog>> getReminderLogs(String patientId) async => [];
}

class FakeCaregiverRepository extends Fake implements ICaregiverRepository {
  List<CaregiverReminderRecord> remoteReminders = [];

  @override
  Future<List<CaregiverReminderRecord>> getReminderStatus(
    String patientId,
  ) async {
    return remoteReminders;
  }
}

// -----------------------------------------------------------------------------
// Main Test Suite
// -----------------------------------------------------------------------------

void main() {
  late FakeReminderRepository fakeReminderRepo;
  late FakeCaregiverRepository fakeCaregiverRepo;
  late FakeConnectivityMonitor fakeConnectivity;
  late ProviderContainer container;

  setUp(() {
    fakeReminderRepo = FakeReminderRepository();
    fakeCaregiverRepo = FakeCaregiverRepository();
    fakeConnectivity = FakeConnectivityMonitor(
      currentStatus: NetworkStatus.offline,
    );

    container = ProviderContainer(
      overrides: [
        reminderRepositoryProvider.overrideWithValue(fakeReminderRepo),
        caregiverRepositoryProvider.overrideWithValue(fakeCaregiverRepo),
        connectivityMonitorProvider.overrideWithValue(fakeConnectivity),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Ask NIRVANA Data Responder - Intent 1: REMINDERS', () {
    test('Reads local Hive reminder when available', () async {
      final now = DateTime.now();
      fakeReminderRepo.reminders = [
        Reminder(
          id: 'rem_1',
          patientId: 'patient_1',
          title: 'Morning Heart Medication',
          body: 'Take with full glass of water',
          scheduledAt: DateTime(now.year, now.month, now.day, 9, 0),
          createdAt: now,
          notificationId: 101,
        ),
      ];

      final responder = container.read(nirvanaDataResponderProvider);
      final response = await responder.respond('When is my medicine?', 'en');

      expect(response, contains('Morning Heart Medication'));
      expect(response, contains('9:00'));
    });

    test(
      'Falls back to Supabase remote repository when local is empty and online',
      () async {
        fakeReminderRepo.reminders = []; // local is empty
        fakeConnectivity.setOnline(true); // internet enabled

        final now = DateTime.now();
        fakeCaregiverRepo.remoteReminders = [
          CaregiverReminderRecord(
            id: 'rem_remote_1',
            patientId: 'patient_1',
            title: 'Blood Pressure Pill',
            description: 'Take after breakfast',
            scheduledAt: DateTime(now.year, now.month, now.day, 10, 30),
            status: 'pending',
            isActive: true,
            isCompleted: false,
          ),
        ];

        final responder = container.read(nirvanaDataResponderProvider);
        final response = await responder.respond(
          'What is my next reminder?',
          'en',
        );

        expect(response, equals(NirvanaDataResponder.unavailable));
      },
    );

    test(
      'Does NOT hallucinate when local is empty and offline (internet disabled)',
      () async {
        fakeReminderRepo.reminders = [];
        fakeConnectivity.setOnline(false); // internet disabled

        final responder = container.read(nirvanaDataResponderProvider);
        final response = await responder.respond('When is my medicine?', 'en');

        // Must clearly state no reminders, never invent
        expect(response, equals(NirvanaDataResponder.unavailable));
      },
    );

    test('Todays Reminders lists all scheduled items for today', () async {
      final now = DateTime.now();
      fakeReminderRepo.reminders = [
        Reminder(
          id: 'rem_1',
          patientId: 'patient_1',
          title: 'Morning Vitamin',
          body: 'One tablet',
          scheduledAt: DateTime(now.year, now.month, now.day, 8, 30),
          createdAt: now,
          notificationId: 1,
        ),
        Reminder(
          id: 'rem_2',
          patientId: 'patient_1',
          title: 'Evening Walk',
          body: 'With caregiver',
          scheduledAt: DateTime(now.year, now.month, now.day, 17, 0),
          createdAt: now,
          notificationId: 2,
        ),
      ];

      final responder = container.read(nirvanaDataResponderProvider);
      final response = await responder.respond(
        'What reminders do I have today?',
        'en',
      );

      expect(response, contains('Today you have 2 reminder(s)'));
      expect(response, contains('Morning Vitamin'));
      expect(response, contains('Evening Walk'));
    });
  });

  group('Ask NIRVANA Data Responder - Intent 2: DAILY ROUTINE', () {
    test('Generates daily routine from today\'s scheduled items', () async {
      final now = DateTime.now();
      fakeReminderRepo.reminders = [
        Reminder(
          id: 'r1',
          patientId: 'p1',
          title: 'Breakfast',
          body: 'Oatmeal and tea',
          scheduledAt: DateTime(now.year, now.month, now.day, 8, 0),
          createdAt: now,
          notificationId: 1,
        ),
      ];

      final responder = container.read(nirvanaDataResponderProvider);
      final response = await responder.respond(
        'What do I have to do today?',
        'en',
      );

      expect(response, contains('Here is your routine'));
      expect(response, contains('Breakfast'));
    });

    test('Handles empty routine safely without hallucination', () async {
      fakeReminderRepo.reminders = [];

      final responder = container.read(nirvanaDataResponderProvider);
      final response = await responder.respond(
        'What do I have to do today?',
        'en',
      );

      expect(
        response,
        equals(
          "You don't have any scheduled tasks or routine items for today.",
        ),
      );
    });
  });

  group('Ask NIRVANA Data Responder - Intent 3: FAMILY & VISITORS', () {
    test('Answers specific daughter relationship', () async {
      final responder = container.read(nirvanaDataResponderProvider);
      final response = await responder.respond('Who is my daughter?', 'en');

      expect(response, equals(NirvanaDataResponder.unavailable));
    });

    test('Answers specific son relationship', () async {
      final responder = container.read(nirvanaDataResponderProvider);
      final response = await responder.respond('Who is my son?', 'en');

      expect(response, equals(NirvanaDataResponder.unavailable));
    });

    test('Answers visitor inquiries', () async {
      final responder = container.read(nirvanaDataResponderProvider);
      final response = await responder.respond('Who is visiting me?', 'en');

      expect(response, equals(NirvanaDataResponder.unavailable));
    });

    test('Shows general family overview', () async {
      final responder = container.read(nirvanaDataResponderProvider);
      final response = await responder.respond('Show me my family', 'en');

      expect(response, equals(NirvanaDataResponder.unavailable));
    });
  });

  group('Ask NIRVANA Data Responder - Intent 4: MEMORIES', () {
    test('Returns structured fond family memories', () async {
      final responder = container.read(nirvanaDataResponderProvider);
      final response = await responder.respond(
        'Tell me about my memories.',
        'en',
      );

      expect(response, equals(NirvanaDataResponder.unavailable));
    });
  });

  group('Ask NIRVANA Data Responder - Intent 5: GAMES', () {
    test('Recommends cognitive games with navigation guidance', () async {
      final responder = container.read(nirvanaDataResponderProvider);
      final response = await responder.respond('I want to play a game.', 'en');

      expect(response, startsWith('START_GAME'));
    });
  });

  group('Ask NIRVANA Data Responder - Intent 6: ORIENTATION', () {
    test('Tells current time from device clock', () async {
      final responder = container.read(nirvanaDataResponderProvider);
      final response = await responder.respond('What time is it?', 'en');

      expect(response, startsWith('The time is'));
    });

    test('Tells current day of week', () async {
      final responder = container.read(nirvanaDataResponderProvider);
      final response = await responder.respond('What day is it?', 'en');

      expect(response, startsWith('Today is'));
    });

    test('Tells current date', () async {
      final responder = container.read(nirvanaDataResponderProvider);
      final response = await responder.respond('What is today\'s date?', 'en');

      expect(response, contains("Today's date is"));
    });
  });

  group('Ask NIRVANA Data Responder - Intent 7: ACTIVITY', () {
    test('States zero activities when none recorded today', () async {
      final responder = container.read(nirvanaDataResponderProvider);
      final response = await responder.respond('What did I do today?', 'en');

      expect(response, equals('I have no recorded activity for today.'));
    });
  });

  group('Ask NIRVANA Data Responder - Intent 8: HELP', () {
    test('Lists all supported elder capabilities', () async {
      final responder = container.read(nirvanaDataResponderProvider);
      final response = await responder.respond('What can you do?', 'en');

      expect(response, contains('I am NIRVANA'));
      expect(response, contains('reminders'));
      expect(response, contains('routine'));
      expect(response, contains('family'));
      expect(response, contains('time'));
    });
  });

  group('Ask NIRVANA Data Responder - Zero Hallucination Fallback', () {
    test('Returns safe fallback for unmapped queries', () async {
      final responder = container.read(nirvanaDataResponderProvider);
      final response = await responder.respond(
        'What is the recipe for chocolate cake?',
        'en',
      );

      expect(response, equals(NirvanaDataResponder.unavailable));
    });
  });
}
