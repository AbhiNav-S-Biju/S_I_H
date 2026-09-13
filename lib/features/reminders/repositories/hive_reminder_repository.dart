// ==============================================================================
// NIRVANA - Hive Reminder Repository Implementation
// Description: Fully offline-first repository. All reads and writes target local
// Hive boxes. Mutations generate idempotent sync events queued in SyncEngine.
// ==============================================================================

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/network/sync_engine.dart';
import '../../../database/hive_database.dart';
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

  /// Reports a reminder action to Supabase from a paired patient device.
  ///
  /// The device is unauthenticated, so it cannot write `reminder_logs` or
  /// `caregiver_notifications` directly. `record_reminder_action_for_device` is
  /// a SECURITY DEFINER RPC that verifies the device pairing, writes the log and
  /// fans the event out to every linked caregiver — this is what actually
  /// updates the caregiver portal when the elder completes an alarm.
  Future<void> _reportActionToCloud({
    required String patientId,
    required String reminderId,
    required String logId,
    required String action,
    required DateTime actionTimestamp,
    required String reminderTitle,
    DateTime? snoozedUntil,
  }) async {
    if (!SupabaseConfig.isConfigured || !HiveDatabase.isDevicePaired) return;
    try {
      await Supabase.instance.client.rpc(
        'record_reminder_action_for_device',
        params: {
          'p_patient_id': patientId,
          'p_device_id': HiveDatabase.getOrCreateDeviceId(),
          'p_reminder_id': reminderId,
          'p_log_id': logId,
          'p_action': action,
          'p_action_timestamp': actionTimestamp.toUtc().toIso8601String(),
          'p_reminder_title': reminderTitle,
          'p_snoozed_until': snoozedUntil?.toUtc().toIso8601String(),
        },
      );
      debugPrint('☁️ Reported reminder action "$action" to caregiver portal.');
    } catch (e) {
      // Offline-first: the queued sync event will retry via the SyncEngine.
      debugPrint('⚠️ Could not report reminder action to Supabase: $e');
    }
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

    // 3. Dispatch caregiver event notification (local, best-effort)
    _eventNotificationService?.notifyReminderCompleted(
      patientId: pId,
      reminderTitle: hive.title,
      reminderId: reminderId,
    );

    // 4. Push the completion to the caregiver portal server-side (works even
    // for the unauthenticated patient device).
    await _reportActionToCloud(
      patientId: pId,
      reminderId: reminderId,
      logId: logId,
      action: ReminderActionType.done.value,
      actionTimestamp: now,
      reminderTitle: hive.title,
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

    // 4. Report the snooze to the caregiver portal server-side.
    await _reportActionToCloud(
      patientId: pId,
      reminderId: reminderId,
      logId: logId,
      action: ReminderActionType.snoozed.value,
      actionTimestamp: now,
      reminderTitle: hive.title,
      snoozedUntil: hive.snoozedUntil ?? now.add(delay),
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
