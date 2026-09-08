// ==============================================================================
// NIRVANA - HiveReminderLog Model
// Description: Locally persisted adherence log for reminder actions (done,
// snoozed, later today). Queued and synced to Supabase when online.
// ==============================================================================

import 'package:hive/hive.dart';

class HiveReminderLog extends HiveObject {
  String id; // UUID v4
  String reminderId; // UUID of target reminder
  String patientId;
  String action; // 'done' | 'snoozed' | 'later_today'
  DateTime actionTimestamp;
  DateTime createdAt;
  Map<String, dynamic> metadata;

  HiveReminderLog({
    required this.id,
    required this.reminderId,
    required this.patientId,
    required this.action,
    required this.actionTimestamp,
    required this.createdAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'reminder_id': reminderId,
    'patient_id': patientId,
    'action': action,
    'action_timestamp': actionTimestamp.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'metadata': metadata,
  };
}
