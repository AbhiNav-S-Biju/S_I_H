// ==============================================================================
// NIRVANA - Hive Patient Device Session Model
// Description: Persists patient pairing session, device ID, and profile metadata
// locally in Hive to enable 100% offline, zero-password launches.
// ==============================================================================

class HivePatientDeviceSession {
  final bool isPaired;
  final String patientId;
  final String deviceId;
  final String displayName;
  final String preferredName;
  final DateTime pairedAt;
  final DateTime? lastSyncAt;
  final bool isActive;
  final Map<String, dynamic> accessibilitySettings;

  const HivePatientDeviceSession({
    required this.isPaired,
    required this.patientId,
    required this.deviceId,
    required this.displayName,
    required this.preferredName,
    required this.pairedAt,
    this.lastSyncAt,
    this.isActive = true,
    this.accessibilitySettings = const {},
  });

  HivePatientDeviceSession copyWith({
    bool? isPaired,
    String? patientId,
    String? deviceId,
    String? displayName,
    String? preferredName,
    DateTime? pairedAt,
    DateTime? lastSyncAt,
    bool? isActive,
    Map<String, dynamic>? accessibilitySettings,
  }) {
    return HivePatientDeviceSession(
      isPaired: isPaired ?? this.isPaired,
      patientId: patientId ?? this.patientId,
      deviceId: deviceId ?? this.deviceId,
      displayName: displayName ?? this.displayName,
      preferredName: preferredName ?? this.preferredName,
      pairedAt: pairedAt ?? this.pairedAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      isActive: isActive ?? this.isActive,
      accessibilitySettings:
          accessibilitySettings ?? this.accessibilitySettings,
    );
  }

  Map<String, dynamic> toMap() => {
    'is_paired': isPaired,
    'patient_id': patientId,
    'device_id': deviceId,
    'display_name': displayName,
    'preferred_name': preferredName,
    'paired_at': pairedAt.toIso8601String(),
    'last_sync_at': lastSyncAt?.toIso8601String(),
    'is_active': isActive,
    'accessibility_settings': accessibilitySettings,
  };
}
