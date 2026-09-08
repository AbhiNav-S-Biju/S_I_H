// ==============================================================================
// NIRVANA - ReminderLog Domain Model
// Description: Pure Dart model representing a patient interaction log (Done,
// Snoozed, Later Today) for caregiver adherence tracking.
// ==============================================================================

import '../../../database/models/hive_reminder_log.dart';

class ReminderLog {
  final String id;
  final String reminderId;
  final String patientId;
  final String action;
  final DateTime actionTimestamp;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const ReminderLog({
    required this.id,
    required this.reminderId,
    required this.patientId,
    required this.action,
    required this.actionTimestamp,
    required this.createdAt,
    this.metadata = const {},
  });

  factory ReminderLog.fromHive(HiveReminderLog hive) {
    return ReminderLog(
      id: hive.id,
      reminderId: hive.reminderId,
      patientId: hive.patientId,
      action: hive.action,
      actionTimestamp: hive.actionTimestamp,
      createdAt: hive.createdAt,
      metadata: hive.metadata,
    );
  }

  HiveReminderLog toHive() {
    return HiveReminderLog(
      id: id,
      reminderId: reminderId,
      patientId: patientId,
      action: action,
      actionTimestamp: actionTimestamp,
      createdAt: createdAt,
      metadata: metadata,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'reminder_id': reminderId,
    'patient_id': patientId,
    'action': action,
    'action_timestamp': actionTimestamp.toUtc().toIso8601String(),
    'created_at': createdAt.toUtc().toIso8601String(),
    'metadata': metadata,
  };
}
