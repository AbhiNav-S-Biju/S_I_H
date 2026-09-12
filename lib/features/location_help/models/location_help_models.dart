// ==============================================================================
// NIRVANA - Location Help Models
// Description: Domain models for the "I'm Lost / I Need Help" location sharing feature.
// ==============================================================================

enum LocationSessionStatus { active, stopped, expired }

class LocationSession {
  final String id;
  final String patientId;
  final String caregiverId;
  final LocationSessionStatus status;
  final DateTime startedAt;
  final DateTime? stoppedAt;
  final DateTime expiresAt;
  final DateTime? lastLocationUpdate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LocationSession({
    required this.id,
    required this.patientId,
    required this.caregiverId,
    required this.status,
    required this.startedAt,
    this.stoppedAt,
    required this.expiresAt,
    this.lastLocationUpdate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LocationSession.fromMap(Map<String, dynamic> map) {
    return LocationSession(
      id: map['id'] as String? ?? '',
      patientId: map['patient_id'] as String? ?? '',
      caregiverId: map['caregiver_id'] as String? ?? '',
      status: _parseStatus(map['status'] as String?),
      startedAt: DateTime.tryParse(map['started_at'] as String? ?? '') ?? DateTime.now(),
      stoppedAt: map['stopped_at'] != null
          ? DateTime.tryParse(map['stopped_at'] as String)
          : null,
      expiresAt: DateTime.tryParse(map['expires_at'] as String? ?? '') ?? DateTime.now(),
      lastLocationUpdate: map['last_location_update'] != null
          ? DateTime.tryParse(map['last_location_update'] as String)
          : null,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  static LocationSessionStatus _parseStatus(String? status) {
    switch (status) {
      case 'active':
        return LocationSessionStatus.active;
      case 'stopped':
        return LocationSessionStatus.stopped;
      case 'expired':
        return LocationSessionStatus.expired;
      default:
        return LocationSessionStatus.expired;
    }
  }

  bool get isActive => status == LocationSessionStatus.active && DateTime.now().isBefore(expiresAt);

  Duration get timeRemaining {
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'patient_id': patientId,
    'caregiver_id': caregiverId,
    'status': status.name,
    'started_at': startedAt.toUtc().toIso8601String(),
    if (stoppedAt != null) 'stopped_at': stoppedAt!.toUtc().toIso8601String(),
    'expires_at': expiresAt.toUtc().toIso8601String(),
    if (lastLocationUpdate != null) 'last_location_update': lastLocationUpdate!.toUtc().toIso8601String(),
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };
}

class PatientLocation {
  final String id;
  final String sessionId;
  final String patientId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final double? heading;
  final DateTime recordedAt;
  final DateTime createdAt;

  const PatientLocation({
    required this.id,
    required this.sessionId,
    required this.patientId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
    required this.recordedAt,
    required this.createdAt,
  });

  factory PatientLocation.fromMap(Map<String, dynamic> map) {
    return PatientLocation(
      id: map['id'] as String? ?? '',
      sessionId: map['session_id'] as String? ?? '',
      patientId: map['patient_id'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      altitude: (map['altitude'] as num?)?.toDouble(),
      speed: (map['speed'] as num?)?.toDouble(),
      heading: (map['heading'] as num?)?.toDouble(),
      recordedAt: DateTime.tryParse(map['recorded_at'] as String? ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'session_id': sessionId,
    'patient_id': patientId,
    'latitude': latitude,
    'longitude': longitude,
    if (accuracy != null) 'accuracy': accuracy,
    if (altitude != null) 'altitude': altitude,
    if (speed != null) 'speed': speed,
    if (heading != null) 'heading': heading,
    'recorded_at': recordedAt.toUtc().toIso8601String(),
    'created_at': createdAt.toUtc().toIso8601String(),
  };
}

class StartLocationSessionResult {
  final bool success;
  final String? sessionId;
  final String? caregiverId;
  final DateTime? expiresAt;
  final bool reused;
  final String? errorCode;
  final String? errorMessage;

  const StartLocationSessionResult({
    required this.success,
    this.sessionId,
    this.caregiverId,
    this.expiresAt,
    this.reused = false,
    this.errorCode,
    this.errorMessage,
  });

  factory StartLocationSessionResult.fromRpcResponse(Map<String, dynamic> map) {
    final success = map['success'] as bool? ?? false;
    if (success) {
      return StartLocationSessionResult(
        success: true,
        sessionId: map['session_id'] as String?,
        caregiverId: map['caregiver_id'] as String?,
        expiresAt: map['expires_at'] != null
            ? DateTime.tryParse(map['expires_at'] as String)
            : null,
        reused: map['reused'] as bool? ?? false,
      );
    }
    return StartLocationSessionResult(
      success: false,
      errorCode: map['error'] as String?,
      errorMessage: map['message'] as String?,
    );
  }
}

class UpdateLocationResult {
  final bool success;
  final String? locationId;
  final DateTime? recordedAt;
  final String? errorCode;
  final String? errorMessage;

  const UpdateLocationResult({
    required this.success,
    this.locationId,
    this.recordedAt,
    this.errorCode,
    this.errorMessage,
  });

  factory UpdateLocationResult.fromRpcResponse(Map<String, dynamic> map) {
    final success = map['success'] as bool? ?? false;
    if (success) {
      return UpdateLocationResult(
        success: true,
        locationId: map['location_id'] as String?,
        recordedAt: map['recorded_at'] != null
            ? DateTime.tryParse(map['recorded_at'] as String)
            : null,
      );
    }
    return UpdateLocationResult(
      success: false,
      errorCode: map['error'] as String?,
      errorMessage: map['message'] as String?,
    );
  }
}

class StopLocationSessionResult {
  final bool success;
  final DateTime? stoppedAt;
  final String? errorCode;
  final String? errorMessage;

  const StopLocationSessionResult({
    required this.success,
    this.stoppedAt,
    this.errorCode,
    this.errorMessage,
  });

  factory StopLocationSessionResult.fromRpcResponse(Map<String, dynamic> map) {
    final success = map['success'] as bool? ?? false;
    if (success) {
      return StopLocationSessionResult(
        success: true,
        stoppedAt: map['stopped_at'] != null
            ? DateTime.tryParse(map['stopped_at'] as String)
            : null,
      );
    }
    return StopLocationSessionResult(
      success: false,
      errorCode: map['error'] as String?,
      errorMessage: map['message'] as String?,
    );
  }
}

class ActiveSessionCheckResult {
  final bool active;
  final String? sessionId;
  final String? caregiverId;
  final String? caregiverName;
  final String? caregiverPhone;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final DateTime? lastLocationUpdate;

  const ActiveSessionCheckResult({
    required this.active,
    this.sessionId,
    this.caregiverId,
    this.caregiverName,
    this.caregiverPhone,
    this.startedAt,
    this.expiresAt,
    this.lastLocationUpdate,
  });

  factory ActiveSessionCheckResult.fromRpcResponse(Map<String, dynamic> map) {
    final active = map['active'] as bool? ?? false;
    if (active) {
      return ActiveSessionCheckResult(
        active: true,
        sessionId: map['session_id'] as String?,
        caregiverId: map['caregiver_id'] as String?,
        caregiverName: map['caregiver_name'] as String?,
        caregiverPhone: map['caregiver_phone'] as String?,
        startedAt: map['started_at'] != null
            ? DateTime.tryParse(map['started_at'] as String)
            : null,
        expiresAt: map['expires_at'] != null
            ? DateTime.tryParse(map['expires_at'] as String)
            : null,
        lastLocationUpdate: map['last_location_update'] != null
            ? DateTime.tryParse(map['last_location_update'] as String)
            : null,
      );
    }
    return const ActiveSessionCheckResult(active: false);
  }
}

class LatestLocationResult {
  final bool success;
  final bool hasLocation;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final double? heading;
  final DateTime? recordedAt;
  final LocationSessionStatus? sessionStatus;
  final DateTime? expiresAt;
  final String? patientPhone;
  final String? errorCode;
  final String? errorMessage;

  const LatestLocationResult({
    required this.success,
    required this.hasLocation,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
    this.recordedAt,
    this.sessionStatus,
    this.expiresAt,
    this.patientPhone,
    this.errorCode,
    this.errorMessage,
  });

  factory LatestLocationResult.fromRpcResponse(Map<String, dynamic> map) {
    final success = map['success'] as bool? ?? false;
    if (success) {
      return LatestLocationResult(
        success: true,
        hasLocation: map['has_location'] as bool? ?? false,
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        accuracy: (map['accuracy'] as num?)?.toDouble(),
        altitude: (map['altitude'] as num?)?.toDouble(),
        speed: (map['speed'] as num?)?.toDouble(),
        heading: (map['heading'] as num?)?.toDouble(),
        recordedAt: map['recorded_at'] != null
            ? DateTime.tryParse(map['recorded_at'] as String)
            : null,
        sessionStatus: _parseStatus(map['session_status'] as String?),
        expiresAt: map['expires_at'] != null
            ? DateTime.tryParse(map['expires_at'] as String)
            : null,
        patientPhone: map['patient_phone'] as String?,
      );
    }
    return LatestLocationResult(
      success: false,
      hasLocation: false,
      errorCode: map['error'] as String?,
      errorMessage: map['message'] as String?,
    );
  }

  static LocationSessionStatus? _parseStatus(String? status) {
    switch (status) {
      case 'active':
        return LocationSessionStatus.active;
      case 'stopped':
        return LocationSessionStatus.stopped;
      case 'expired':
        return LocationSessionStatus.expired;
      default:
        return null;
    }
  }
}