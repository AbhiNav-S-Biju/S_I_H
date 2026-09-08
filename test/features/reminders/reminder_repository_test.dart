// ==============================================================================
// NIRVANA - Hive Reminder Repository Unit Tests
// Description: Tests offline persistence, CRUD, completion, snoozing, and log
// generation with queued sync events.
// ==============================================================================

import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nirvana/core/network/connectivity_monitor.dart';
import 'package:nirvana/core/network/sync_engine.dart';
import 'package:nirvana/database/adapters/hive_adapters.dart';
import 'package:nirvana/database/hive_boxes.dart';
import 'package:nirvana/database/models/hive_reminder.dart';
import 'package:nirvana/database/models/hive_reminder_log.dart';
import 'package:nirvana/database/models/hive_sync_event.dart';
import 'package:nirvana/features/reminders/models/reminder.dart';
import 'package:nirvana/features/reminders/models/reminder_action.dart';
import 'package:nirvana/features/reminders/repositories/hive_reminder_repository.dart';
import 'package:nirvana/core/contracts/supabase_repository_contracts.dart';

class StubConnectivityMonitor implements IConnectivityMonitor {
  @override
  Stream<NetworkStatus> get statusStream => const Stream.empty();

  @override
  Future<NetworkStatus> checkStatus() async => NetworkStatus.offline;
}

class StubSupabaseSyncRepository implements ISupabaseSyncRepository {
  @override
  Future<Map<String, dynamic>> processSyncEvent({
    required String eventId,
    required String patientId,
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
    required DateTime createdAt,
  }) async => {'status': 'success'};

  @override
  Future<Map<String, dynamic>> processSyncEventsBatch({
    required List<Map<String, dynamic>> events,
  }) async => {'status': 'success'};
}

void main() {
  late Directory tempDir;
  late Box<HiveReminder> remindersBox;
  late Box<HiveReminderLog> reminderLogsBox;
  late Box<HiveSyncEvent> syncQueueBox;
  late SyncEngine syncEngine;
  late HiveReminderRepository repository;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('nirvana_repo_test_');
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
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    remindersBox = await Hive.openBox<HiveReminder>('reminders_$timestamp');
    reminderLogsBox = await Hive.openBox<HiveReminderLog>(
      'reminder_logs_$timestamp',
    );
    syncQueueBox = await Hive.openBox<HiveSyncEvent>('sync_queue_$timestamp');

    syncEngine = SyncEngine(
      syncQueueBox: syncQueueBox,
      syncRepository: StubSupabaseSyncRepository(),
      connectivityMonitor: StubConnectivityMonitor(),
    );

    repository = HiveReminderRepository(
      remindersBox: remindersBox,
      reminderLogsBox: reminderLogsBox,
      syncEngine: syncEngine,
    );
  });

  tearDown(() async {
    syncEngine.dispose();
    await remindersBox.close();
    await reminderLogsBox.close();
    await syncQueueBox.close();
  });

  group('HiveReminderRepository CRUD & Offline Tests', () {
    test('creates reminder offline in Hive and queues a sync event', () async {
      final reminder = Reminder(
        id: 'rem-uuid-1',
        patientId: 'pat-uuid-1',
        title: 'Morning Blood Pressure Check',
        body: 'Use the arm cuff',
        scheduledAt: DateTime(2026, 9, 8, 9, 0),
        createdAt: DateTime.now(),
        notificationId: 101,
      );

      final created = await repository.createReminder(reminder);

      expect(created.id, equals('rem-uuid-1'));
      expect(remindersBox.length, equals(1));
      expect(
        remindersBox.get('rem-uuid-1')?.title,
        equals('Morning Blood Pressure Check'),
      );

      // Check sync queue
      expect(syncQueueBox.length, equals(1));
      final queued = syncQueueBox.values.first;
      expect(queued.entityType, equals('reminder'));
      expect(queued.entityId, equals('rem-uuid-1'));
      expect(queued.operation, equals('create'));
      expect(queued.syncStatus, equals(SyncStatus.pending));
    });

    test(
      'getActiveReminders returns only active non-completed items',
      () async {
        final active = Reminder(
          id: 'rem-active',
          patientId: 'pat-1',
          title: 'Drink Water',
          body: '',
          scheduledAt: DateTime.now().add(const Duration(hours: 1)),
          createdAt: DateTime.now(),
          notificationId: 102,
          isActive: true,
          isCompleted: false,
        );

        final completed = Reminder(
          id: 'rem-done',
          patientId: 'pat-1',
          title: 'Breakfast pills',
          body: '',
          scheduledAt: DateTime.now().subtract(const Duration(hours: 2)),
          createdAt: DateTime.now(),
          notificationId: 103,
          isActive: true,
          isCompleted: true,
        );

        final deleted = Reminder(
          id: 'rem-del',
          patientId: 'pat-1',
          title: 'Old alert',
          body: '',
          scheduledAt: DateTime.now(),
          createdAt: DateTime.now(),
          notificationId: 104,
          isActive: false,
          isCompleted: false,
        );

        await repository.createReminder(active);
        await repository.createReminder(completed);
        await repository.createReminder(deleted);

        final list = await repository.getActiveReminders('pat-1');
        expect(list.length, equals(1));
        expect(list.first.id, equals('rem-active'));
      },
    );
  });

  group('HiveReminderRepository Action Tests (Done / Snooze / Later)', () {
    test(
      'completeReminder marks complete, writes adherence log with "done", and queues sync events',
      () async {
        final reminder = Reminder(
          id: 'rem-action-1',
          patientId: 'pat-1',
          title: 'Afternoon Vitamin D',
          body: '',
          scheduledAt: DateTime.now(),
          createdAt: DateTime.now(),
          notificationId: 201,
        );

        await repository.createReminder(reminder);
        await syncQueueBox.clear(); // Clear initial create event

        await repository.completeReminder('rem-action-1');

        // Verify reminder state
        final updated = remindersBox.get('rem-action-1')!;
        expect(updated.isCompleted, isTrue);
        expect(updated.completedAt, isNotNull);

        // Verify log entry
        expect(reminderLogsBox.length, equals(1));
        final log = reminderLogsBox.values.first;
        expect(log.reminderId, equals('rem-action-1'));
        expect(log.action, equals(ReminderActionType.done.value));

        // Verify sync events: 1 reminder update + 1 reminder_log create
        expect(syncQueueBox.length, equals(2));
        final events = syncQueueBox.values.toList();
        expect(
          events.any(
            (e) => e.entityType == 'reminder' && e.operation == 'update',
          ),
          isTrue,
        );
        expect(
          events.any(
            (e) => e.entityType == 'reminder_log' && e.operation == 'create',
          ),
          isTrue,
        );
      },
    );

    test(
      'snoozeReminder sets snoozedUntil (+15m), writes log, and queues sync events',
      () async {
        final reminder = Reminder(
          id: 'rem-snooze-1',
          patientId: 'pat-1',
          title: 'Eye drops',
          body: '',
          scheduledAt: DateTime.now(),
          createdAt: DateTime.now(),
          notificationId: 202,
        );

        await repository.createReminder(reminder);
        await syncQueueBox.clear();

        await repository.snoozeReminder(
          'rem-snooze-1',
          delay: const Duration(minutes: 15),
        );

        final updated = remindersBox.get('rem-snooze-1')!;
        expect(updated.isCompleted, isFalse);
        expect(updated.snoozedUntil, isNotNull);
        expect(updated.snoozedUntil!.isAfter(DateTime.now()), isTrue);

        final log = reminderLogsBox.values.first;
        expect(log.action, equals(ReminderActionType.snoozed.value));
        expect(log.metadata['snooze_duration_seconds'], equals(900));

        expect(syncQueueBox.length, equals(2));
      },
    );

    test(
      'dismissReminderLaterToday sets snoozedUntil (+4h), writes log, and queues sync events',
      () async {
        final reminder = Reminder(
          id: 'rem-later-1',
          patientId: 'pat-1',
          title: 'Walk in garden',
          body: '',
          scheduledAt: DateTime.now(),
          createdAt: DateTime.now(),
          notificationId: 203,
        );

        await repository.createReminder(reminder);
        await syncQueueBox.clear();

        await repository.dismissReminderLaterToday('rem-later-1');

        final updated = remindersBox.get('rem-later-1')!;
        expect(updated.snoozedUntil, isNotNull);
        expect(
          updated.snoozedUntil!.isAfter(
            DateTime.now().add(const Duration(hours: 3)),
          ),
          isTrue,
        );

        final log = reminderLogsBox.values.first;
        expect(log.action, equals(ReminderActionType.laterToday.value));
        expect(syncQueueBox.length, equals(2));
      },
    );

    test('deleteReminder sets isActive false and queues sync event', () async {
      final reminder = Reminder(
        id: 'rem-del-1',
        patientId: 'pat-1',
        title: 'Deprecated check',
        body: '',
        scheduledAt: DateTime.now(),
        createdAt: DateTime.now(),
        notificationId: 204,
      );

      await repository.createReminder(reminder);
      await syncQueueBox.clear();

      await repository.deleteReminder('rem-del-1');

      final stored = remindersBox.get('rem-del-1')!;
      expect(stored.isActive, isFalse);

      expect(syncQueueBox.length, equals(1));
      expect(syncQueueBox.values.first.operation, equals('delete'));
    });
  });
}
