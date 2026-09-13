// ==============================================================================
// NIRVANA - Reminder Riverpod Providers
// Description: Riverpod dependency injection for Reminders, Hive persistence,
// and Notification services.
// ==============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/network/sync_engine.dart';
import '../../../database/hive_database.dart';
import '../../caregiver/providers/caregiver_providers.dart';
import '../models/reminder.dart';
import '../models/reminder_log.dart';
import '../repositories/hive_reminder_repository.dart';
import '../repositories/reminder_repository.dart';
import '../repositories/supabase_reminder_pull_repository.dart';
import '../services/notification_service.dart';

/// Reminder repository provider (offline-first)
final reminderRepositoryProvider = Provider<IReminderRepository>((ref) {
  final syncEngine = ref.watch(syncEngineProvider);
  final eventService = ref.watch(caregiverEventNotificationServiceProvider);
  return HiveReminderRepository(
    remindersBox: HiveDatabase.remindersBox,
    reminderLogsBox: HiveDatabase.reminderLogsBox,
    syncEngine: syncEngine,
    eventNotificationService: eventService,
  );
});

/// Notification service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final repo = ref.watch(reminderRepositoryProvider);
  return NotificationService(reminderRepository: repo);
});

/// Repository used to pull a caregiver's reminders down onto this device.
/// Returns null when Supabase is not configured or the device is not paired.
final reminderPullRepositoryProvider =
    Provider<SupabaseReminderPullRepository?>((ref) {
  try {
    if (!SupabaseConfig.isConfigured || !HiveDatabase.isDevicePaired) {
      return null;
    }
    return SupabaseReminderPullRepository(
      client: Supabase.instance.client,
      deviceId: HiveDatabase.getOrCreateDeviceId(),
      notificationService: ref.watch(notificationServiceProvider),
    );
  } catch (_) {
    // Supabase is optional for offline patient devices.
    return null;
  }
});

/// Stream / Future provider of active reminders for a given patient ID
final activeRemindersProvider = FutureProvider.family<List<Reminder>, String>((
  ref,
  patientId,
) async {
  // Pull the caregiver's reminders down onto this patient device first, then
  // read from local storage so the dashboard reflects them. Falls back to the
  // local cache when offline or unpaired.
  final pull = ref.watch(reminderPullRepositoryProvider);
  if (pull != null && patientId.isNotEmpty) {
    try {
      await pull.syncToLocal(patientId);
    } catch (_) {
      // Offline-first: use whatever is cached locally.
    }
  }
  final repo = ref.watch(reminderRepositoryProvider);
  return repo.getActiveReminders(patientId);
});

/// Future provider of reminder logs for a given patient ID
final reminderLogsProvider = FutureProvider.family<List<ReminderLog>, String>((
  ref,
  patientId,
) async {
  final repo = ref.watch(reminderRepositoryProvider);
  return repo.getReminderLogs(patientId);
});
