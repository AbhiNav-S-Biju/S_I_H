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

  /// Resolves the patient's registered phone number (and the caregiver's own),
  /// but only for a caregiver authorized for that patient. Implementations must
  /// never return data for an unrelated patient.
  Future<PatientContactInfo> getPatientContact(String patientId);

  /// Sends [code] — the patient's CURRENT pairing passcode — to the patient's
  /// registered phone number via the secure backend SMS function.
  ///
  /// [pairingCodeId] is the server-side id of the claimed passcode row, used to
  /// re-verify server-side that exactly this (still-valid) code is delivered.
  Future<PasscodeSmsResult> sendPasscodeSms({
    required String patientId,
    required String code,
    String? pairingCodeId,
  });
}
