// ==============================================================================
// NIRVANA - Caregiver Pairing Repository Interface
// Description: Contract for generating and managing patient device pairing codes.
// ==============================================================================

import '../models/caregiver_models.dart';

abstract class IPairingRepository {
  /// Generates a 6-digit one-time pairing code for the given patient.
  /// The code is valid for [validityMinutes] minutes (default 15).
  Future<PairingCodeInfo> generatePairingCode(
    String patientId, {
    int validityMinutes = 15,
  });

  /// Returns the most recently active device linked to the patient, if any.
  Future<PatientDeviceSummary?> getLinkedDevice(String patientId);

  /// Revokes (deactivates) a patient device by its device ID.
  Future<void> revokeDevice(String deviceId);
}
