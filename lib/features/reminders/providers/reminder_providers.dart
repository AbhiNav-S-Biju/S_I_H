// ==============================================================================
// NIRVANA - Reminder Riverpod Providers
// Description: Riverpod dependency injection for Reminders, Hive persistence,
// and Notification services.
// ==============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/sync_engine.dart';
import '../../../database/hive_database.dart';
import '../models/reminder.dart';
import '../models/reminder_log.dart';
import '../repositories/hive_reminder_repository.dart';
import '../repositories/reminder_repository.dart';
import '../services/notification_service.dart';

/// Reminder repository provider (offline-first)
final reminderRepositoryProvider = Provider<IReminderRepository>((ref) {
  final syncEngine = ref.watch(syncEngineProvider);
  return HiveReminderRepository(
    remindersBox: HiveDatabase.remindersBox,
    reminderLogsBox: HiveDatabase.reminderLogsBox,
    syncEngine: syncEngine,
  );
});

/// Notification service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final repo = ref.watch(reminderRepositoryProvider);
  return NotificationService(reminderRepository: repo);
});

/// Stream / Future provider of active reminders for a given patient ID
final activeRemindersProvider =
    FutureProvider.family<List<Reminder>, String>((ref, patientId) async {
  final repo = ref.watch(reminderRepositoryProvider);
  return repo.getActiveReminders(patientId);
});

/// Future provider of reminder logs for a given patient ID
final reminderLogsProvider =
    FutureProvider.family<List<ReminderLog>, String>((ref, patientId) async {
  final repo = ref.watch(reminderRepositoryProvider);
  return repo.getReminderLogs(patientId);
});
