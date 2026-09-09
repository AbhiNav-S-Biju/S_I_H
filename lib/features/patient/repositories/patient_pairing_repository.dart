// ==============================================================================
// NIRVANA - Patient Pairing Repository Interface
// Description: Contract for the patient-device side of the pairing flow.
// Handles code validation, session persistence, and local state management.
// ==============================================================================

import '../../../database/models/hive_patient_session.dart';
import '../../caregiver/models/caregiver_models.dart';

abstract class IPatientPairingRepository {
  /// Validates the 6-digit pairing code server-side and registers this device.
  /// Returns a [PairDeviceResult] indicating success or detailed failure reason.
  Future<PairDeviceResult> validateAndPairDevice({
    required String code,
    required String deviceId,
    String? deviceName,
  });

  /// Loads the locally persisted patient session from Hive (if any).
  HivePatientDeviceSession? loadLocalSession();

  /// Persists the patient session to Hive after successful pairing.
  Future<void> saveSession(HivePatientDeviceSession session);

  /// Clears the local pairing session (e.g. for factory reset / unpair).
  Future<void> clearSession();
}
