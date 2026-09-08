// ==============================================================================
// NIRVANA - Supabase Repository Contracts
// Description: Abstract repository interfaces defining how Flutter interacts with Supabase
// ==============================================================================

import 'dart:async';

/// 1. Profile Repository Contract (Caregivers)
abstract class ISupabaseProfileRepository {
  /// Fetches authenticated caregiver profile
  Future<Map<String, dynamic>?> getCurrentProfile(String userId);

  /// Updates profile preferences or contact details
  Future<void> updateProfile({
    required String userId,
    required Map<String, dynamic> updates,
  });
}

/// 2. Patient Repository Contract
abstract class ISupabasePatientRepository {
  /// Retrieves patient details assigned to current caregiver
  Future<Map<String, dynamic>?> getPatientById(String patientId);

  /// Lists all patients linked to the authenticated caregiver
  Future<List<Map<String, dynamic>>> getAccessiblePatients();

  /// Updates patient accessibility settings or contact info
  Future<void> updatePatientSettings({
    required String patientId,
    required Map<String, dynamic> settings,
  });
}

/// 3. Game Session Repository Contract (Non-Clinical Activity)
abstract class ISupabaseGameSessionRepository {
  /// Queries recent game activity logs for Caregiver Dashboard
  Future<List<Map<String, dynamic>>> getGameSessionsByPatient({
    required String patientId,
    DateTime? since,
    int limit = 100,
  });
}

/// 4. Reminder Repository Contract
abstract class ISupabaseReminderRepository {
  /// Retrieves active reminders for a patient
  Future<List<Map<String, dynamic>>> getActiveReminders(String patientId);

  /// Creates or updates a reminder (synchronized via sync engine or direct)
  Future<void> upsertReminder({
    required String patientId,
    required Map<String, dynamic> reminderData,
  });

  /// Soft deletes a reminder
  Future<void> softDeleteReminder({
    required String patientId,
    required String reminderId,
  });
}

/// 5. Reminder Log Repository Contract
abstract class ISupabaseReminderLogRepository {
  /// Queries adherence logs for past N days for caregiver summary
  Future<List<Map<String, dynamic>>> getReminderLogs({
    required String patientId,
    required DateTime startDate,
    required DateTime endDate,
  });
}

/// 6. Family Photo Repository Contract
abstract class ISupabaseFamilyPhotoRepository {
  /// Fetches all active family photos for "Who Is This?" and album
  Future<List<Map<String, dynamic>>> getFamilyPhotos(String patientId);

  /// Soft deletes a family photo
  Future<void> softDeletePhoto({
    required String patientId,
    required String photoId,
  });
}

/// 7. Sync Engine Repository Contract (Idempotent Transaction Ingestion)
abstract class ISupabaseSyncRepository {
  /// Submits a single mutation to the idempotent cloud RPC
  Future<Map<String, dynamic>> processSyncEvent({
    required String eventId,
    required String patientId,
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
    required DateTime createdAt,
  });

  /// Submits a batch of mutations for bulk sync after reconnecting
  Future<Map<String, dynamic>> processSyncEventsBatch({
    required List<Map<String, dynamic>> events,
  });
}

/// 8. Patient Device Repository Contract
abstract class ISupabasePatientDeviceRepository {
  /// Lists devices paired with patient
  Future<List<Map<String, dynamic>>> getDevices(String patientId);

  /// Revokes device access
  Future<void> revokeDevice(String deviceId);
}

/// 9. Patient Pairing Repository Contract
abstract class ISupabasePairingRepository {
  /// Generates a 6-digit one-time pairing code (valid for 15 mins)
  Future<String> generatePairingCode(String patientId, {int validityMinutes = 15});

  /// Validates a 6-digit pairing code and registers device server-side
  Future<Map<String, dynamic>> validateAndPairDevice({
    required String code,
    required String deviceId,
    String? deviceName,
  });
}

/// 10. Caregiver Notification Repository Contract
abstract class ISupabaseCaregiverNotificationRepository {
  /// Queries notifications for caregiver
  Future<List<Map<String, dynamic>>> getNotifications(String caregiverId, {bool unreadOnly = false});

  /// Marks notification as read
  Future<void> markAsRead(String notificationId);
}
