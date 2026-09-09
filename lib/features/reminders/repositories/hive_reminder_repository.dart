// ==============================================================================
// NIRVANA - Hive Reminder Repository Implementation
// Description: Fully offline-first repository. All reads and writes target local
// Hive boxes. Mutations generate idempotent sync events queued in SyncEngine.
// ==============================================================================

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/sync_engine.dart';
import '../../../database/models/hive_reminder.dart';
import '../../../database/models/hive_reminder_log.dart';
import '../../../database/models/hive_sync_event.dart';
import '../../caregiver/services/caregiver_event_notification_service.dart';
import '../models/reminder.dart';
import '../models/reminder_action.dart';
import '../models/reminder_log.dart';
import 'reminder_repository.dart';

class HiveReminderRepository implements IReminderRepository {
  final Box<HiveReminder> _remindersBox;
  final Box<HiveReminderLog> _reminderLogsBox;
  final SyncEngine _syncEngine;
  final CaregiverEventNotificationService? _eventNotificationService;
  final Uuid _uuid;

  HiveReminderRepository({
    required Box<HiveReminder> remindersBox,
    required Box<HiveReminderLog> reminderLogsBox,
    required SyncEngine syncEngine,
    CaregiverEventNotificationService? eventNotificationService,
    Uuid? uuid,
  }) : _remindersBox = remindersBox,
       _reminderLogsBox = reminderLogsBox,
       _syncEngine = syncEngine,
       _eventNotificationService = eventNotificationService,
       _uuid = uuid ?? const Uuid();

  @override
  Future<List<Reminder>> getActiveReminders(String patientId) async {
    final hiveReminders = _remindersBox.values.where((r) {
      final matchesPatient = patientId.isEmpty || r.patientId == patientId;
      return matchesPatient && r.isActive && !r.isCompleted;
    }).toList();

    // Sort by scheduled time ascending
    hiveReminders.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    return hiveReminders.map(Reminder.fromHive).toList();
  }

  @override
  Future<Reminder?> getReminderById(String reminderId) async {
    final hive = _remindersBox.get(reminderId);
    return hive != null ? Reminder.fromHive(hive) : null;
  }

  @override
  Future<Reminder> createReminder(Reminder reminder) async {
    final hiveModel = reminder.toHive();
    await _remindersBox.put(reminder.id, hiveModel);

    // Enqueue cloud sync event
    final syncEvent = HiveSyncEvent(
      eventId: _uuid.v4(),
      entityType: 'reminder',
      entityId: reminder.id,
      operation: 'create',
      payload: reminder.toMap(),
      createdAt: DateTime.now(),
      patientId: reminder.patientId,
    );
    await _syncEngine.enqueueEvent(syncEvent);

    return reminder;
  }

  @override
  Future<Reminder> updateReminder(Reminder reminder) async {
    final hiveModel = reminder.toHive();
    await _remindersBox.put(reminder.id, hiveModel);

    final syncEvent = HiveSyncEvent(
      eventId: _uuid.v4(),
      entityType: 'reminder',
      entityId: reminder.id,
      operation: 'update',
      payload: reminder.toMap(),
      createdAt: DateTime.now(),
      patientId: reminder.patientId,
    );
    await _syncEngine.enqueueEvent(syncEvent);

    return reminder;
  }

  @override
  Future<void> completeReminder(String reminderId, {String? patientId}) async {
    final hive = _remindersBox.get(reminderId);
    if (hive == null) return;

    final now = DateTime.now();
    hive.isCompleted = true;
    hive.completedAt = now;
    await hive.save();

    final pId = patientId ?? hive.patientId;

    // 1. Queue reminder update
    final reminderSyncEvent = HiveSyncEvent(
      eventId: _uuid.v4(),
      entityType: 'reminder',
      entityId: reminderId,
      operation: 'update',
      payload: Reminder.fromHive(hive).toMap(),
      createdAt: now,
      patientId: pId,
    );
    await _syncEngine.enqueueEvent(reminderSyncEvent);

    // 2. Log adherence action
    final logId = _uuid.v4();
    final log = HiveReminderLog(
      id: logId,
      reminderId: reminderId,
      patientId: pId,
      action: ReminderActionType.done.value,
      actionTimestamp: now,
      createdAt: now,
    );
    await _reminderLogsBox.put(logId, log);

    final logSyncEvent = HiveSyncEvent(
      eventId: _uuid.v4(),
      entityType: 'reminder_log',
      entityId: logId,
      operation: 'create',
      payload: log.toMap(),
      createdAt: now,
      patientId: pId,
    );
    await _syncEngine.enqueueEvent(logSyncEvent);

    // 3. Dispatch caregiver event notification
    _eventNotificationService?.notifyReminderCompleted(
      patientId: pId,
      reminderTitle: hive.title,
      reminderId: reminderId,
    );
  }

  @override
  Future<void> snoozeReminder(
    String reminderId, {
    Duration delay = const Duration(minutes: 15),
    String? patientId,
  }) async {
    final hive = _remindersBox.get(reminderId);
    if (hive == null) return;

    final now = DateTime.now();
    hive.snoozedUntil = now.add(delay);
    await hive.save();

    final pId = patientId ?? hive.patientId;

    // 1. Queue reminder update
    final reminderSyncEvent = HiveSyncEvent(
      eventId: _uuid.v4(),
      entityType: 'reminder',
      entityId: reminderId,
      operation: 'update',
      payload: Reminder.fromHive(hive).toMap(),
      createdAt: now,
      patientId: pId,
    );
    await _syncEngine.enqueueEvent(reminderSyncEvent);

    // 2. Log snooze action
    final logId = _uuid.v4();
    final log = HiveReminderLog(
      id: logId,
      reminderId: reminderId,
      patientId: pId,
      action: ReminderActionType.snoozed.value,
      actionTimestamp: now,
      createdAt: now,
      metadata: {'snooze_duration_seconds': delay.inSeconds},
    );
    await _reminderLogsBox.put(logId, log);

    final logSyncEvent = HiveSyncEvent(
      eventId: _uuid.v4(),
      entityType: 'reminder_log',
      entityId: logId,
      operation: 'create',
      payload: log.toMap(),
      createdAt: now,
      patientId: pId,
    );
    await _syncEngine.enqueueEvent(logSyncEvent);

    // 3. Dispatch caregiver event notification
    _eventNotificationService?.notifyReminderSnoozed(
      patientId: pId,
      reminderTitle: hive.title,
      snoozedUntil: hive.snoozedUntil ?? now.add(delay),
      reminderId: reminderId,
    );
  }

  @override
  Future<void> dismissReminderLaterToday(
    String reminderId, {
    String? patientId,
    DateTime? scheduledLater,
  }) async {
    final hive = _remindersBox.get(reminderId);
    if (hive == null) return;

    final now = DateTime.now();
    final later = scheduledLater ?? now.add(const Duration(hours: 4));
    hive.snoozedUntil = later;
    await hive.save();

    final pId = patientId ?? hive.patientId;

    // 1. Queue reminder update
    final reminderSyncEvent = HiveSyncEvent(
      eventId: _uuid.v4(),
      entityType: 'reminder',
      entityId: reminderId,
      operation: 'update',
      payload: Reminder.fromHive(hive).toMap(),
      createdAt: now,
      patientId: pId,
    );
    await _syncEngine.enqueueEvent(reminderSyncEvent);

    // 2. Log action
    final logId = _uuid.v4();
    final log = HiveReminderLog(
      id: logId,
      reminderId: reminderId,
      patientId: pId,
      action: ReminderActionType.laterToday.value,
      actionTimestamp: now,
      createdAt: now,
      metadata: {'rescheduled_to': later.toIso8601String()},
    );
    await _reminderLogsBox.put(logId, log);

    final logSyncEvent = HiveSyncEvent(
      eventId: _uuid.v4(),
      entityType: 'reminder_log',
      entityId: logId,
      operation: 'create',
      payload: log.toMap(),
      createdAt: now,
      patientId: pId,
    );
    await _syncEngine.enqueueEvent(logSyncEvent);

    // 3. Dispatch caregiver event notification
    _eventNotificationService?.notifyReminderSnoozed(
      patientId: pId,
      reminderTitle: hive.title,
      snoozedUntil: later,
      reminderId: reminderId,
    );
  }

  @override
  Future<void> deleteReminder(String reminderId, {String? patientId}) async {
    final hive = _remindersBox.get(reminderId);
    if (hive == null) return;

    hive.isActive = false;
    await hive.save();

    final pId = patientId ?? hive.patientId;
    final syncEvent = HiveSyncEvent(
      eventId: _uuid.v4(),
      entityType: 'reminder',
      entityId: reminderId,
      operation: 'delete',
      payload: {'id': reminderId, 'is_active': false},
      createdAt: DateTime.now(),
      patientId: pId,
    );
    await _syncEngine.enqueueEvent(syncEvent);
  }

  @override
  Future<List<ReminderLog>> getReminderLogs(String patientId) async {
    final hiveLogs = _reminderLogsBox.values.where((l) {
      return patientId.isEmpty || l.patientId == patientId;
    }).toList();

    hiveLogs.sort((a, b) => b.actionTimestamp.compareTo(a.actionTimestamp));
    return hiveLogs.map(ReminderLog.fromHive).toList();
  }
}
