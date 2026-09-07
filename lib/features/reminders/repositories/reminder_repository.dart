// ==============================================================================
// NIRVANA - Reminder Repository Interface
// Description: Contract for reminder operations. UI and feature code interact
// only through this interface without direct Hive or Supabase couplings.
// ==============================================================================

import '../models/reminder.dart';
import '../models/reminder_log.dart';

abstract class IReminderRepository {
  /// Fetches all active, non-deleted reminders for a patient
  Future<List<Reminder>> getActiveReminders(String patientId);

  /// Fetches a specific reminder by ID
  Future<Reminder?> getReminderById(String reminderId);

  /// Creates a new reminder locally and queues for cloud synchronization
  Future<Reminder> createReminder(Reminder reminder);

  /// Updates an existing reminder locally and queues for cloud sync
  Future<Reminder> updateReminder(Reminder reminder);

  /// Marks a reminder as completed, logs the action, and queues for sync
  Future<void> completeReminder(String reminderId, {String? patientId});

  /// Snoozes a reminder by specified duration (default: 15 min) and logs action
  Future<void> snoozeReminder(
    String reminderId, {
    Duration delay = const Duration(minutes: 15),
    String? patientId,
  });

  /// Reschedules reminder for later today (e.g. evening or +4 hours) and logs action
  Future<void> dismissReminderLaterToday(
    String reminderId, {
    String? patientId,
    DateTime? scheduledLater,
  });

  /// Soft-deletes / cancels a reminder
  Future<void> deleteReminder(String reminderId, {String? patientId});

  /// Retrieves local reminder adherence logs for a patient
  Future<List<ReminderLog>> getReminderLogs(String patientId);
}
