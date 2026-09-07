// ==============================================================================
// NIRVANA - Reminder Domain Model
// Description: Pure Dart model representing a medication, hydration, or activity
// reminder for an elder patient. Independent of database implementation.
// ==============================================================================

import '../../../database/models/hive_reminder.dart';

class Reminder {
  final String id;
  final String patientId;
  final String title;
  final String body;
  final DateTime scheduledAt;
  final bool isActive;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? snoozedUntil;
  final int notificationId;
  final String? recurrenceRule;

  const Reminder({
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

  /// Factory from Hive persistent entity
  factory Reminder.fromHive(HiveReminder hive) {
    return Reminder(
      id: hive.id,
      patientId: hive.patientId,
      title: hive.title,
      body: hive.body,
      scheduledAt: hive.scheduledAt,
      isActive: hive.isActive,
      isCompleted: hive.isCompleted,
      createdAt: hive.createdAt,
      completedAt: hive.completedAt,
      snoozedUntil: hive.snoozedUntil,
      notificationId: hive.notificationId,
      recurrenceRule: hive.recurrenceRule,
    );
  }

  /// Converts domain entity into Hive persistent entity
  HiveReminder toHive() {
    return HiveReminder(
      id: id,
      patientId: patientId,
      title: title,
      body: body,
      scheduledAt: scheduledAt,
      isActive: isActive,
      isCompleted: isCompleted,
      createdAt: createdAt,
      completedAt: completedAt,
      snoozedUntil: snoozedUntil,
      notificationId: notificationId,
      recurrenceRule: recurrenceRule,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'patient_id': patientId,
        'title': title,
        'body': body,
        'scheduled_at': scheduledAt.toUtc().toIso8601String(),
        'is_active': isActive,
        'is_completed': isCompleted,
        'created_at': createdAt.toUtc().toIso8601String(),
        'completed_at': completedAt?.toUtc().toIso8601String(),
        'snoozed_until': snoozedUntil?.toUtc().toIso8601String(),
        'notification_id': notificationId,
        'recurrence_rule': recurrenceRule,
      };

  Reminder copyWith({
    String? id,
    String? patientId,
    String? title,
    String? body,
    DateTime? scheduledAt,
    bool? isActive,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? snoozedUntil,
    int? notificationId,
    String? recurrenceRule,
  }) {
    return Reminder(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      title: title ?? this.title,
      body: body ?? this.body,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      isActive: isActive ?? this.isActive,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      notificationId: notificationId ?? this.notificationId,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
    );
  }
}
