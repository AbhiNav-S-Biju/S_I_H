// ==============================================================================
// NIRVANA - Location Help Repository Interface
// ==============================================================================

import '../models/location_help_models.dart';

abstract class ILocationHelpRepository {
  /// Check if there's an active location help session for the patient.
  /// The patient device proves its identity with [deviceId].
  Future<ActiveSessionCheckResult> checkActiveSession(
    String patientId, {
    required String deviceId,
  });

  /// Start a new location help session for the patient device.
  Future<StartLocationSessionResult> startLocationSession(
    String patientId, {
    required String deviceId,
    int timeoutMinutes = 30,
  });

  /// Update patient location during active session
  Future<UpdateLocationResult> updateLocation({
    required String sessionId,
    required String deviceId,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    double? heading,
    DateTime? recordedAt,
  });

  /// Stop the location help session.
  ///
  /// [deviceId] is supplied by the patient device; caregivers omit it and are
  /// authorized through their authenticated Supabase session instead.
  Future<StopLocationSessionResult> stopLocationSession({
    required String sessionId,
    required String stoppedBy, // 'patient' or 'caregiver'
    String? deviceId,
  });

  /// Find the active session for a patient (CAREGIVER side).
  ///
  /// Unlike [checkActiveSession], this reads through RLS using the caregiver's
  /// authenticated Supabase session — no device_id is involved, and RLS is what
  /// guarantees only the assigned caregiver receives rows.
  Future<LocationSession?> fetchCaregiverActiveSession(String patientId);

  /// Get latest location for a session (caregiver side)
  Future<LatestLocationResult> getLatestLocation(String sessionId);

  /// Stream of location updates for realtime tracking (caregiver side)
  Stream<PatientLocation> watchLocationUpdates(String sessionId);

  /// Stream of session status changes
  Stream<LocationSession> watchSessionStatus(String sessionId);
}