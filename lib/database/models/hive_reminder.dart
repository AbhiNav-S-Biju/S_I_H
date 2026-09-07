// ==============================================================================
// NIRVANA - HiveReminder Model
// Description: Locally persisted reminder record. Source of truth on device.
// ==============================================================================

import 'package:hive/hive.dart';

class HiveReminder extends HiveObject {
  String id; // UUID v4
  String patientId;
  String title; // Human-readable label, e.g. "Take morning medication"
  String body; // Optional detail
  DateTime scheduledAt; // When to fire the notification
  bool isActive;
  bool isCompleted;
  DateTime createdAt;
  DateTime? completedAt;
  DateTime? snoozedUntil;
  int notificationId; // flutter_local_notifications id (int)
  String? recurrenceRule; // e.g. 'daily', 'weekly', null = one-shot

  HiveReminder({
    required this.id,
    required this.patientId,
    required this.title,
    required this.body,
    required this.scheduledAt,
    required this.createdAt,
    required this.notificationId,
    this.isActive = true,
    this.isCompleted = false,
    this.completedAt,
    this.snoozedUntil,
    this.recurrenceRule,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'patient_id': patientId,
        'title': title,
        'body': body,
        'scheduled_at': scheduledAt.toIso8601String(),
        'is_active': isActive,
        'is_completed': isCompleted,
        'created_at': createdAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'snoozed_until': snoozedUntil?.toIso8601String(),
        'notification_id': notificationId,
        'recurrence_rule': recurrenceRule,
      };
}
