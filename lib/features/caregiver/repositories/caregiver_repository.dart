// ==============================================================================
// NIRVANA - Caregiver Repository Interface
// Description: Contract defining data operations for Caregiver Portal.
// ==============================================================================

import '../models/caregiver_models.dart';

abstract class IFamilyPhotoReader {
  Future<List<Map<String, dynamic>>> getFamilyPhotos(String patientId);
}

abstract class ICaregiverRepository {
  /// Registers a new caregiver via Supabase Auth, then creates a profiles row
  Future<CaregiverProfile> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  });

  /// Authenticates a caregiver
  Future<CaregiverProfile> login({
    required String email,
    required String password,
  });

  /// Logs out the active caregiver session
  Future<void> logout();

  /// Gets current authenticated caregiver profile (or cached offline)
  Future<CaregiverProfile?> getCurrentCaregiver();

  /// Creates a new patient record and links it to the active caregiver
  Future<PatientSummary> createPatient({
    required CreatePatientInput input,
    String? caregiverId,
  });

  /// Fetches only patients assigned to the authenticated caregiver
  Future<List<PatientSummary>> getAssignedPatients(String caregiverId);

  /// Retrieves recent game sessions played by the selected patient
  Future<List<CaregiverGameRecord>> getGameHistory(String patientId);

  /// Retrieves active/recent reminders and completion status for the patient
  Future<List<CaregiverReminderRecord>> getReminderStatus(String patientId);

  /// Creates a new reminder for the patient
  Future<CaregiverReminderRecord> createReminder(
    CreateOrUpdateReminderInput input,
  );

  /// Updates an existing reminder (e.g. time, recurrence, title)
  Future<CaregiverReminderRecord> updateReminder(
    String reminderId,
    CreateOrUpdateReminderInput input,
  );

  /// Enables or disables a reminder
  Future<void> toggleReminderActive(String reminderId, bool isActive);

  /// Soft-deletes a reminder
  Future<void> deleteReminder(String reminderId);

  /// Calculates a non-clinical 7-day activity completion summary
  Future<List<DailyActivitySummary>> getSevenDayActivity(String patientId);

  /// Retrieves sync and connectivity status info
  Future<CaregiverSyncInfo> getSyncStatus(String patientId);
}
