// ==============================================================================
// NIRVANA - Database Models Unit Tests
// Description: Tests serialization, RPC conversion, and adapters for Hive models.
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:nirvana/database/models/hive_reminder.dart';
import 'package:nirvana/database/models/hive_reminder_log.dart';
import 'package:nirvana/database/models/hive_sync_event.dart';

void main() {
  group('HiveSyncEvent Model Tests', () {
    test('creates HiveSyncEvent with default values and generates valid RPC payload', () {
      final now = DateTime.utc(2026, 9, 8, 12, 0, 0);
      final event = HiveSyncEvent(
        eventId: 'test-event-uuid-1234',
        entityType: 'reminder',
        entityId: 'reminder-uuid-5678',
        operation: 'create',
        payload: {'title': 'Morning Medicine', 'is_active': true},
        createdAt: now,
        patientId: 'patient-uuid-9999',
      );

      expect(event.eventId, equals('test-event-uuid-1234'));
      expect(event.retryCount, equals(0));
      expect(event.syncStatus, equals(SyncStatus.pending));

      final rpcPayload = event.toRpcPayload();
      expect(rpcPayload['event_id'], equals('test-event-uuid-1234'));
      expect(rpcPayload['patient_id'], equals('patient-uuid-9999'));
      expect(rpcPayload['entity_type'], equals('reminder'));
      expect(rpcPayload['entity_id'], equals('reminder-uuid-5678'));
      expect(rpcPayload['operation'], equals('create'));
      expect(rpcPayload['payload'], equals({'title': 'Morning Medicine', 'is_active': true}));
      expect(rpcPayload['created_at'], equals('2026-09-08T12:00:00.000Z'));
    });

    test('sync status transitions properly', () {
      final event = HiveSyncEvent(
        eventId: 'e-1',
        entityType: 'reminder',
        entityId: 'r-1',
        operation: 'update',
        payload: {},
        createdAt: DateTime.now(),
        patientId: 'p-1',
      );

      expect(event.syncStatus, equals(SyncStatus.pending));
      event.syncStatus = SyncStatus.synced;
      expect(event.syncStatus, equals(SyncStatus.synced));

      event.syncStatus = SyncStatus.deadLetter;
      expect(event.syncStatus, equals(SyncStatus.deadLetter));
    });
  });

  group('HiveReminder Model Tests', () {
    test('converts HiveReminder to Map correctly', () {
      final scheduled = DateTime(2026, 9, 8, 8, 30);
      final created = DateTime(2026, 9, 8, 8, 0);
      final reminder = HiveReminder(
        id: 'rem-1',
        patientId: 'pat-1',
        title: 'Drink Water',
        body: 'Hydration check',
        scheduledAt: scheduled,
        createdAt: created,
        notificationId: 101,
        isActive: true,
        isCompleted: false,
        recurrenceRule: 'daily',
      );

      final map = reminder.toMap();
      expect(map['id'], equals('rem-1'));
      expect(map['patient_id'], equals('pat-1'));
      expect(map['title'], equals('Drink Water'));
      expect(map['notification_id'], equals(101));
      expect(map['is_active'], isTrue);
      expect(map['is_completed'], isFalse);
      expect(map['recurrence_rule'], equals('daily'));
    });
  });

  group('HiveReminderLog Model Tests', () {
    test('converts HiveReminderLog to Map correctly', () {
      final timestamp = DateTime(2026, 9, 8, 8, 35);
      final log = HiveReminderLog(
        id: 'log-1',
        reminderId: 'rem-1',
        patientId: 'pat-1',
        action: 'snoozed',
        actionTimestamp: timestamp,
        createdAt: timestamp,
        metadata: {'snooze_minutes': 15},
      );

      final map = log.toMap();
      expect(map['id'], equals('log-1'));
      expect(map['reminder_id'], equals('rem-1'));
      expect(map['patient_id'], equals('pat-1'));
      expect(map['action'], equals('snoozed'));
      expect(map['metadata'], equals({'snooze_minutes': 15}));
    });
  });
}
