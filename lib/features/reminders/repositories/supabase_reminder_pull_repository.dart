// ==============================================================================
// NIRVANA - Supabase Reminder Pull Repository
// Description: Downloads a patient's reminders from Supabase onto the paired
//   patient device and mirrors them into the local Hive box.
//
//   The patient device is unauthenticated (anon key) and the `reminders` table
//   RLS is `TO authenticated`, so it cannot read the table directly. Instead it
//   calls the SECURITY DEFINER `get_reminders_for_device` RPC, which authorizes
//   the calling device via `is_active_patient_device(...)`.
//
//   Caregiver-created reminders were previously only pushed from the caregiver
//   device and never pulled down, so the patient dashboard showed "0 of 0".
// ==============================================================================

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../database/hive_boxes.dart';
import '../../../database/hive_database.dart';
import '../../../database/models/hive_reminder.dart';
import '../models/reminder.dart';
import '../services/notification_service.dart';

class SupabaseReminderPullRepository {
  SupabaseReminderPullRepository({
    required SupabaseClient client,
    required String deviceId,
    NotificationService? notificationService,
  }) : _client = client,
       _deviceId = deviceId,
       _notificationService = notificationService;

  final SupabaseClient _client;
  final String _deviceId;
  final NotificationService? _notificationService;

  /// Fetches the patient's reminders and returns them as domain models.
  Future<List<Reminder>> fetchReminders(String patientId) async {
    final rows = await _client.rpc(
      'get_reminders_for_device',
      params: {'p_patient_id': patientId, 'p_device_id': _deviceId},
    );
    if (rows is! List) return const [];

    final reminders = <Reminder>[];
    for (final raw in rows) {
      final map = Map<String, dynamic>.from(raw as Map);
      try {
        reminders.add(_fromRow(map));
      } catch (e) {
        debugPrint('⚠️ Skipped reminder row ${map['id']}: $e');
      }
    }
    return reminders;
  }

  /// Downloads the patient's reminders and mirrors them into the local Hive box.
  ///
  /// Local-only state (completion / snooze) is preserved: a remote row never
  /// clears a reminder the elder has already completed on this device.
  /// Returns the resulting list of local reminders.
  Future<List<Reminder>> syncToLocal(String patientId) async {
    final remote = await fetchReminders(patientId);
    if (!Hive.isBoxOpen(HiveBoxes.reminders)) return remote;

    final box = HiveDatabase.remindersBox;
    final remoteIds = <String>{};

    for (final reminder in remote) {
      remoteIds.add(reminder.id);
      final existing = box.get(reminder.id);
      final merged = HiveReminder(
        id: reminder.id,
        patientId: reminder.patientId,
        title: reminder.title,
        body: reminder.body,
        scheduledAt: reminder.scheduledAt,
        isActive: reminder.isActive,
        // Never un-complete something done on this device.
        isCompleted: existing?.isCompleted ?? reminder.isCompleted,
        createdAt: existing?.createdAt ?? reminder.createdAt,
        completedAt: existing?.completedAt ?? reminder.completedAt,
        snoozedUntil: existing?.snoozedUntil ?? reminder.snoozedUntil,
        notificationId:
            existing?.notificationId ?? _notificationIdFor(reminder.id),
        recurrenceRule: reminder.recurrenceRule,
      );
      await box.put(merged.id, merged);
    }

    // Drop locally cached reminders that no longer exist on the server (e.g.
    // the caregiver deleted them), but keep any still-pending local creations.
    for (final local in box.values.toList()) {
      if (local.patientId == patientId && !remoteIds.contains(local.id)) {
        await box.delete(local.id);
      }
    }

    final result = box.values
        .where((r) => r.patientId == patientId)
        .map(Reminder.fromHive)
        .toList();

    // (Re)schedule local notifications for everything we just pulled.
    await _notificationService?.rescheduleAllForPatient(result);

    return result;
  }

  Reminder _fromRow(Map<String, dynamic> row) {
    final now = DateTime.now();
    final scheduledAt = _scheduledAtFromRow(row, now);
    final recurrence = (row['recurrence_days'] as List?)
        ?.map((e) => e.toString())
        .toList();
    return Reminder(
      id: row['id'] as String,
      patientId: row['patient_id'] as String,
      title: (row['title'] as String?) ?? 'Reminder',
      body: (row['description'] as String?) ?? '',
      scheduledAt: scheduledAt,
      isActive: (row['is_active'] as bool?) ?? true,
      isCompleted: false,
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? now,
      notificationId: _notificationIdFor(row['id'] as String),
      recurrenceRule: recurrence?.join(','),
    );
  }

  /// The server stores only a `TIME`; combine it with today's date. If that
  /// time has already passed today, roll it to tomorrow so the reminder still
  /// fires rather than being treated as stale.
  DateTime _scheduledAtFromRow(Map<String, dynamic> row, DateTime now) {
    final raw = row['schedule_time']?.toString() ?? '08:00:00';
    final parts = raw.split(':');
    final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '8') ?? 8;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    var scheduledAt = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduledAt.isBefore(now)) {
      scheduledAt = scheduledAt.add(const Duration(days: 1));
    }
    return scheduledAt;
  }

  static int _notificationIdFor(String reminderId) =>
      reminderId.hashCode.abs() % 100000;
}
