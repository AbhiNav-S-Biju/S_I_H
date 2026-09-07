// ==============================================================================
// NIRVANA - Caregiver Repository Interface
// Description: Contract defining data operations for Caregiver Portal.
// ==============================================================================

import '../models/caregiver_models.dart';

abstract class ICaregiverRepository {
  /// Authenticates a caregiver
  Future<CaregiverProfile> login({
    required String email,
    required String password,
  });

  /// Logs out the active caregiver session
  Future<void> logout();

  /// Gets current authenticated caregiver profile (or cached offline)
  Future<CaregiverProfile?> getCurrentCaregiver();

  /// Fetches only patients assigned to the authenticated caregiver
  Future<List<PatientSummary>> getAssignedPatients(String caregiverId);

  /// Retrieves recent game sessions played by the selected patient
  Future<List<CaregiverGameRecord>> getGameHistory(String patientId);

  /// Retrieves active/recent reminders and completion status for the patient
  Future<List<CaregiverReminderRecord>> getReminderStatus(String patientId);

  /// Calculates a non-clinical 7-day activity completion summary
  Future<List<DailyActivitySummary>> getSevenDayActivity(String patientId);

  /// Retrieves sync and connectivity status info
  Future<CaregiverSyncInfo> getSyncStatus(String patientId);
}
