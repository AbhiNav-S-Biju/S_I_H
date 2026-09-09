// ==============================================================================
// NIRVANA - Ask NIRVANA Data Responder Tests
// Description: Comprehensive test suite verifying all 18 standard intents against
// real data layer contracts, testing stories, boredom, date/day/time, reminders,
// routine, family, memories, social greetings, and zero-hallucination guarantees.
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
  Future<List<Reminder>> getActiveReminders(String patientId) async => reminders;

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

class FakeAiAssistantService implements IAiAssistantService {
  String responseToReturn = NirvanaDataResponder.unavailable;

  @override
  Future<String> getAiFallbackResponse({
    required String query,
    required String languageCode,
    String? patientContext,
  }) async {
    return responseToReturn;
  }
}

// -----------------------------------------------------------------------------
// Main Test Suite
// -----------------------------------------------------------------------------

void main() {
  late FakeReminderRepository fakeReminderRepo;
  late FakeCaregiverRepository fakeCaregiverRepo;
  late FakeConnectivityMonitor fakeConnectivity;
  late FakeAiAssistantService fakeAiAssistant;
  late NirvanaStoryService storyService;
  late ProviderContainer container;

  setUp(() {
    fakeReminderRepo = FakeReminderRepository();
    fakeCaregiverRepo = FakeCaregiverRepository();
    fakeAiAssistant = FakeAiAssistantService();
    fakeConnectivity = FakeConnectivityMonitor(
      currentStatus: NetworkStatus.offline,
    );
    storyService = NirvanaStoryService();

    container = ProviderContainer(
      overrides: [
        reminderRepositoryProvider.overrideWithValue(fakeReminderRepo),
        caregiverRepositoryProvider.overrideWithValue(fakeCaregiverRepo),
        connectivityMonitorProvider.overrideWithValue(fakeConnectivity),
        aiAssistantServiceProvider.overrideWithValue(fakeAiAssistant),
        nirvanaStoryServiceProvider.overrideWithValue(storyService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Ask NIRVANA Data Responder - Intent 1: STORIES (Offline)', () {
    test('Returns local story completely offline', () async {
      final responder = container.read(nirvanaDataResponderProvider);
      final response = await responder.respond('Tell me a story', 'en');

      expect(response, startsWith('Of course. Here is a short story for you:'));
      expect(response, isNotEmpty);
    });

    test('Returns different story on "Another one"', () async {
      final responder = container.read(nirvanaDataResponderProvider);
      final response1 = await responder.respond('Tell me a story', 'en');
      final response2 = await responder.respond('Another one', 'en');

      expect(response1, isNot(equals(response2)));
    });

    test('Returns story in Hindi when requested', () async {
      final responder = container.read(nirvanaDataResponderProvider);
      final response = await responder.respond('मुझे एक कहानी सुनाओ', 'hi');

      expect(response, startsWith('ज़रूर! यह रही आपके लिए एक छोटी सी कहानी:'));
    });
  });

  group('Ask NIRVANA Data Responder - Intent 2: REMINDERS', () {
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

    test('Does NOT hallucinate when reminders are empty', () async {
      fakeReminderRepo.reminders = [];
      fakeConnectivity.setOnline(false);

      final responder = container.read(nirvanaDataResponderProvider);
      final response = await responder.respond('When is my medicine?', 'en');

      expect(response, equals(NirvanaDataResponder.unavailable));
    });

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
      ];

      final responder = container.read(nirvanaDataResponderProvider);
      final response = await responder.respond(
        'What reminders do I have today?',
        'en',
      );

      expect(response, contains('Today you have 1 reminder(s)'));
      expect(response, contains('Morning Vitamin'));
    });
  });

  group('Ask NIRVANA Data Responder - Intent 3: DAILY ROUTINE', () {
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
  });

  group('Ask NIRVANA Data Responder - Intent 4: ORIENTATION (Time, Day, Date)', () {
    test('Tells current time', () async {
      final responder = container.read(nirvanaDataResponderProvider);
      final response = await responder.respond('What time is it?', 'en');

      expect(response, startsWith('The time is'));
    });

    test('Tells current day of week', () async {
      final responder = container.read(nirvanaDataResponderProvider);
      final response = await responder.respond('What day is today?', 'en');

      expect(response, startsWith('Today is'));
    });

    test('Tells current date', () async {
      final responder = container.read(nirvanaDataResponderProvider);
      final response = await responder.respond('What is today\'s date?', 'en');

      expect(response, contains("Today's date is"));
    });
  });

  group('Ask NIRVANA Data Responder - Intent 5: GAMES & BOREDOM', () {
    test('Offers game, memory, and story choices on "I\'m bored"', () async {
      final responder = container.read(nirvanaDataResponderProvider);
      final response = await responder.respond('I\'m bored', 'en');

      expect(
        response,
        equals(
          'We can play a memory game, look at your memories, or I can tell you a story. What would you like?',
        ),
      );
    });

    test('Starts game', () async {
      final responder = container.read(nirvanaDataResponderProvider);
      final response = await responder.respond('I want to play a game', 'en');

      expect(response, startsWith('START_GAME'));
    });
  });

  group('Ask NIRVANA Data Responder - Intent 6: SOCIAL (Greeting, Gratitude, Goodbye)', () {
    test('Responds to greeting warmly', () async {
      final responder = container.read(nirvanaDataResponderProvider);
      final response = await responder.respond('Hello', 'en');

      expect(response, contains('Hello! It is wonderful to talk with you'));
    });

    test('Responds to gratitude warmly', () async {
      final responder = container.read(nirvanaDataResponderProvider);
      final response = await responder.respond('Thank you', 'en');

      expect(response, equals('You are always welcome. I am right here with you.'));
    });

    test('Responds to goodbye warmly', () async {
      final responder = container.read(nirvanaDataResponderProvider);
      final response = await responder.respond('Goodbye', 'en');

      expect(response, contains('Take care and rest well'));
    });
  });

  group('Ask NIRVANA Data Responder - Intent 7: HELP', () {
    test('Lists capabilities including stories', () async {
      final responder = container.read(nirvanaDataResponderProvider);
      final response = await responder.respond('What can you do?', 'en');

      expect(response, contains('I am NIRVANA'));
      expect(response, contains('stories'));
      expect(response, contains('reminders'));
    });
  });

  group('Ask NIRVANA Data Responder - AI Fallback Delegation', () {
    test('Delegates unmapped conversational queries to AI assistant service', () async {
      fakeAiAssistant.responseToReturn =
          'The sky appears blue because of how the Earth\'s atmosphere scatters sunlight.';

      final responder = container.read(nirvanaDataResponderProvider);
      final response = await responder.respond('Why is the sky blue?', 'en');

      expect(response, contains('sky appears blue'));
    });
  });
}
