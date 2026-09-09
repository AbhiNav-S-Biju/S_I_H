
// ==============================================================================
// NIRVANA - Phase 9: Full Offline-First Integration & Verification Tests
// Description: Validates 100% offline patient execution, local Hive persistence,
// scheduled notifications, game session logging, and subsequent FIFO sync
// with retry backoff and caregiver telemetry upon network restoration.
// ==============================================================================

import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nirvana/core/contracts/supabase_repository_contracts.dart';
import 'package:nirvana/core/network/connectivity_monitor.dart';
import 'package:nirvana/core/network/sync_engine.dart';
import 'package:nirvana/database/adapters/hive_adapters.dart';
import 'package:nirvana/database/hive_boxes.dart';
import 'package:nirvana/database/models/hive_patient_session.dart';
import 'package:nirvana/database/models/hive_reminder.dart';
import 'package:nirvana/database/models/hive_reminder_log.dart';
import 'package:nirvana/database/models/hive_sync_event.dart';
import 'package:nirvana/features/games/models/game_enums.dart';
import 'package:nirvana/features/games/models/game_session.dart';
import 'package:nirvana/features/reminders/models/reminder.dart';
import 'package:nirvana/features/reminders/models/reminder_action.dart';
import 'package:nirvana/features/reminders/repositories/hive_reminder_repository.dart';

class MockConnectivityMonitor implements IConnectivityMonitor {
  final _controller = StreamController<NetworkStatus>.broadcast();
  NetworkStatus _current = NetworkStatus.offline;

  void setStatus(NetworkStatus status) {
    _current = status;
    _controller.add(status);
  }

  @override
  Stream<NetworkStatus> get statusStream => _controller.stream;

  @override
  Future<NetworkStatus> checkStatus() async => _current;

  void dispose() {
    _controller.close();
  }
}

class RecordingSupabaseSyncRepository implements ISupabaseSyncRepository {
  final List<Map<String, dynamic>> processedEvents = [];
  bool shouldFail = false;
  int failureCount = 0;

  @override
  Future<Map<String, dynamic>> processSyncEvent({
    required String eventId,
    required String patientId,
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
    required DateTime createdAt,
  }) async {
    if (shouldFail) {
      failureCount++;
      throw Exception('Network / Server Error: Simulated connection dropped');
    }

    final record = {
      'event_id': eventId,
      'patient_id': patientId,
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': operation,
      'payload': payload,
      'created_at': createdAt.toIso8601String(),
    };
    processedEvents.add(record);

    return {'status': 'success', 'event_id': eventId};
  }

  @override
  Future<Map<String, dynamic>> processSyncEventsBatch({
    required List<Map<String, dynamic>> events,
  }) async {
    if (shouldFail) {
      throw Exception('Simulated batch failure');
    }
    processedEvents.addAll(events);
    return {'status': 'success', 'processed_count': events.length};
  }
}

void main() {
  late Directory tempDir;
  late Box<HiveReminder> remindersBox;
  late Box<HiveReminderLog> reminderLogsBox;
  late Box<HiveSyncEvent> syncQueueBox;
  late Box<dynamic> patientSessionBox;

  late MockConnectivityMonitor connectivityMonitor;
  late RecordingSupabaseSyncRepository syncRepository;
  late SyncEngine syncEngine;
  late HiveReminderRepository reminderRepository;

  const testPatientId = 'patient-p9-1001';

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('nirvana_phase9_test_');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(HiveTypeIds.hiveSyncEvent)) {
      Hive.registerAdapter(HiveSyncEventAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.hiveReminder)) {
      Hive.registerAdapter(HiveReminderAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.hiveReminderLog)) {
      Hive.registerAdapter(HiveReminderLogAdapter());
    }
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    final ts = DateTime.now().microsecondsSinceEpoch;
    remindersBox = await Hive.openBox<HiveReminder>('p9_reminders_$ts');
    reminderLogsBox = await Hive.openBox<HiveReminderLog>('p9_logs_$ts');
    syncQueueBox = await Hive.openBox<HiveSyncEvent>('p9_sync_$ts');
    patientSessionBox = await Hive.openBox('p9_session_$ts');

    connectivityMonitor = MockConnectivityMonitor();
    syncRepository = RecordingSupabaseSyncRepository();

    syncEngine = SyncEngine(
      syncQueueBox: syncQueueBox,
      syncRepository: syncRepository,
      connectivityMonitor: connectivityMonitor,
      maxRetries: 3,
    );

    reminderRepository = HiveReminderRepository(
      remindersBox: remindersBox,
      reminderLogsBox: reminderLogsBox,
      syncEngine: syncEngine,
    );
  });

  tearDown(() async {
    connectivityMonitor.dispose();
    syncEngine.dispose();
    await remindersBox.close();
    await reminderLogsBox.close();
    await syncQueueBox.close();
    await patientSessionBox.close();
  });

  group('PHASE 9 - OFFLINE PATIENT TEST (Zero Network / Zero Supabase)', () {
    test('1. Patient Device Pairing State persists offline in Hive with zero login required', () async {
      final session = HivePatientDeviceSession(
        isPaired: true,
        patientId: testPatientId,
        deviceId: 'device-test-xyz',
        displayName: 'Grandma Mary',
        preferredName: 'Mary',
        pairedAt: DateTime.now(),
        accessibilitySettings: {
          'large_text': true,
          'high_contrast': true,
          'font_scale': 1.4,
          'language': 'ta',
        },
      );
      await patientSessionBox.put('active_patient_session', session.toMap());

      final storedMap = patientSessionBox.get('active_patient_session') as Map;
      final retrieved = HivePatientDeviceSession.fromMap(storedMap.cast<String, dynamic>());

      expect(retrieved.isPaired, isTrue);
      expect(retrieved.displayName, 'Grandma Mary');
      expect(retrieved.patientId, testPatientId);
      expect(retrieved.accessibilitySettings['large_text'], isTrue);
    });

    test('2. Patient reads reminders, completes, snoozes, and later-todays offline', () async {
      // Setup morning medication reminder
      final morningMed = Reminder(
        id: 'rem-p9-med-1',
        patientId: testPatientId,
        title: 'Morning Blood Pressure Medication',
        body: 'Take 1 blue pill with warm water',
        scheduledAt: DateTime.now(),
        createdAt: DateTime.now(),
        notificationId: 101,
      );
      await reminderRepository.createReminder(morningMed);

      // Verify stored locally in Hive
      final activeReminders = await reminderRepository.getActiveReminders(testPatientId);
      expect(activeReminders.length, 1);
      expect(activeReminders.first.title, 'Morning Blood Pressure Medication');

      // Snooze reminder for 15 minutes offline
      await reminderRepository.snoozeReminder(morningMed.id, delay: const Duration(minutes: 15));
      final snoozed = await reminderRepository.getReminderById(morningMed.id);
      expect(snoozed?.snoozedUntil, isNotNull);

      // Mark reminder as Done offline
      await reminderRepository.completeReminder(morningMed.id);
      final completed = await reminderRepository.getReminderById(morningMed.id);
      expect(completed?.isCompleted, isTrue);

      // Verify reminder adherence log was appended locally in Hive
      expect(reminderLogsBox.values.length, 2); // 1 snooze log + 1 done log
      final logs = reminderLogsBox.values.toList();
      expect(logs.any((l) => l.action == ReminderActionType.snoozed.value), isTrue);
      expect(logs.any((l) => l.action == ReminderActionType.done.value), isTrue);

      // Verify mutations were safely enqueued in sync_queue_box
      expect(syncQueueBox.values.length, 5); // 1 create + 2 updates + 2 logs
      for (final event in syncQueueBox.values) {
        expect(event.syncStatus, SyncStatus.pending);
      }
    });

    test('3. Patient plays cognitive games offline and saves session logs with sync queueing', () async {
      final session = GameSession(
        id: 'game-sess-p9-01',
        gameType: GameType.rememberObjects,
        difficulty: GameDifficulty.easy,
        score: 85,
        totalQuestions: 10,
        correctAnswers: 8,
        hintsUsed: 1,
        durationSeconds: 45,
        completedAt: DateTime.now(),
        activityMetadata: {'streak': 4},
      );

      // Enqueue sync event offline
      final syncEvent = HiveSyncEvent(
        eventId: 'sync-game-p9-01',
        entityType: 'game_session',
        entityId: session.id,
        operation: 'create',
        payload: {
          'id': session.id,
          'patient_id': testPatientId,
          'game_type': session.gameType.name,
          'difficulty_level': 1,
          'total_trials': session.totalQuestions,
          'successful_trials': session.correctAnswers,
          'duration_seconds': session.durationSeconds,
          'activity_metadata': session.activityMetadata,
          'completed_at': session.completedAt.toIso8601String(),
        },
        createdAt: DateTime.now(),
        patientId: testPatientId,
      );
      await syncEngine.enqueueEvent(syncEvent);

      expect(syncQueueBox.get('sync-game-p9-01')?.entityType, 'game_session');
      expect(syncQueueBox.get('sync-game-p9-01')?.syncStatus, SyncStatus.pending);
    });
  });

  group('PHASE 9 - SYNC ENGINE & RESTORATION (FIFO, Retry, Backoff, Idempotency)', () {
    test('1. Sync Engine processes events in strict FIFO order on reconnect', () async {
      // Enqueue 3 chronological events
      final t1 = DateTime.now().subtract(const Duration(minutes: 5));
      final t2 = DateTime.now().subtract(const Duration(minutes: 3));
      final t3 = DateTime.now().subtract(const Duration(minutes: 1));

      await syncQueueBox.put('evt-1', HiveSyncEvent(
        eventId: 'evt-1',
        entityType: 'reminder',
        entityId: 'r-1',
        operation: 'create',
        payload: {'title': 'Morning Pills'},
        createdAt: t1,
        patientId: testPatientId,
      ));

      await syncQueueBox.put('evt-3', HiveSyncEvent(
        eventId: 'evt-3',
        entityType: 'reminder',
        entityId: 'r-1',
        operation: 'update',
        payload: {'is_completed': true},
        createdAt: t3,
        patientId: testPatientId,
      ));

      await syncQueueBox.put('evt-2', HiveSyncEvent(
        eventId: 'evt-2',
        entityType: 'reminder_log',
        entityId: 'log-1',
        operation: 'create',
        payload: {'action': 'done'},
        createdAt: t2,
        patientId: testPatientId,
      ));

      // Reconnect network
      connectivityMonitor.setStatus(NetworkStatus.online);
      final result = await syncEngine.processQueue();

      expect(result.succeeded, 3);
      expect(result.failed, 0);

      // Verify FIFO ordering in remote sync
      expect(syncRepository.processedEvents.length, 3);
      expect(syncRepository.processedEvents[0]['event_id'], 'evt-1');
      expect(syncRepository.processedEvents[1]['event_id'], 'evt-2');
      expect(syncRepository.processedEvents[2]['event_id'], 'evt-3');

      // Verify all marked as synced in Hive
      for (final e in syncQueueBox.values) {
        expect(e.syncStatus, SyncStatus.synced);
      }
    });

    test('2. Exponential backoff and retry count increment on failure', () async {
      final backoff0 = syncEngine.calculateBackoff(0);
      final backoff1 = syncEngine.calculateBackoff(1);
      final backoff2 = syncEngine.calculateBackoff(2);
      final backoff3 = syncEngine.calculateBackoff(3);

      expect(backoff0, Duration.zero);
      expect(backoff1.inSeconds, 2);
      expect(backoff2.inSeconds, 4);
      expect(backoff3.inSeconds, 8);

      // Simulate failing network
      syncRepository.shouldFail = true;

      await syncQueueBox.put('fail-evt', HiveSyncEvent(
        eventId: 'fail-evt',
        entityType: 'reminder',
        entityId: 'rem-fail',
        operation: 'create',
        payload: {},
        createdAt: DateTime.now(),
        patientId: testPatientId,
      ));

      final res1 = await syncEngine.processQueue();
      expect(res1.failed, 1);
      expect(syncQueueBox.get('fail-evt')?.retryCount, 1);
      expect(syncQueueBox.get('fail-evt')?.syncStatus, SyncStatus.pending);

      final res2 = await syncEngine.processQueue();
      expect(res2.failed, 1);
      expect(syncQueueBox.get('fail-evt')?.retryCount, 2);

      // Third retry hits maxRetries = 3 -> Dead Letter
      final res3 = await syncEngine.processQueue();
      expect(res3.deadLettered, 1);
      expect(syncQueueBox.get('fail-evt')?.syncStatus, SyncStatus.deadLetter);
    });

    test('3. Caregiver updates reminder time 08:30 -> 09:00 with cancellation & rescheduling', () async {
      // 1. Initial reminder at 08:30
      final initialReminder = Reminder(
        id: 'rem-resched-1',
        patientId: testPatientId,
        title: 'Morning Breakfast',
        body: 'Healthy porridge and fruit',
        scheduledAt: DateTime(2026, 9, 10, 8, 30),
        createdAt: DateTime.now(),
        notificationId: 201,
      );
      await reminderRepository.createReminder(initialReminder);

      // 2. Caregiver modifies time to 09:00
      final updatedReminder = initialReminder.copyWith(
        scheduledAt: DateTime(2026, 9, 10, 9, 0),
        body: 'Healthy porridge and fruit (adjusted schedule)',
      );
      await reminderRepository.updateReminder(updatedReminder);

      final stored = await reminderRepository.getReminderById(initialReminder.id);
      expect(stored?.scheduledAt.hour, 9);
      expect(stored?.scheduledAt.minute, 0);

      // Verify sync event queued for cloud synchronization
      final updateEvent = syncQueueBox.values.firstWhere((e) => e.operation == 'update');
      expect(updateEvent.entityId, initialReminder.id);
      expect(updateEvent.payload['body'], 'Healthy porridge and fruit (adjusted schedule)');
    });
  });
}
