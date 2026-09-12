// ==============================================================================
// NIRVANA - Supabase Location Help Repository Implementation
// ==============================================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/connectivity_monitor.dart';
import '../models/location_help_models.dart';
import 'location_help_repository.dart';

class SupabaseLocationHelpRepository implements ILocationHelpRepository {
  final SupabaseClient? _client;
  final IConnectivityMonitor _connectivityMonitor;

  SupabaseLocationHelpRepository({
    SupabaseClient? client,
    IConnectivityMonitor? connectivityMonitor,
  })  : _client = client,
        _connectivityMonitor = connectivityMonitor ?? ConnectivityMonitor();

  SupabaseClient? get _activeClient {
    if (_client != null) return _client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ActiveSessionCheckResult> checkActiveSession(
    String patientId, {
    required String deviceId,
  }) async {
    final client = _activeClient;
    final status = await _connectivityMonitor.checkStatus();

    if (client != null &&
        status == NetworkStatus.online &&
        patientId.isNotEmpty &&
        deviceId.isNotEmpty) {
      try {
        final response = await client.rpc(
          'get_active_location_session',
          params: {
            'p_patient_id': patientId,
            'p_device_id': deviceId,
          },
        );

        return ActiveSessionCheckResult.fromRpcResponse(
          (response as Map).cast<String, dynamic>(),
        );
      } catch (e) {
        debugPrint('⚠️ checkActiveSession error: $e');
        return const ActiveSessionCheckResult(active: false);
      }
    }

    return const ActiveSessionCheckResult(active: false);
  }

  @override
  Future<StartLocationSessionResult> startLocationSession(
    String patientId, {
    required String deviceId,
    int timeoutMinutes = 30,
  }) async {
    final client = _activeClient;
    final status = await _connectivityMonitor.checkStatus();

    if (client != null &&
        status == NetworkStatus.online &&
        patientId.isNotEmpty &&
        deviceId.isNotEmpty) {
      try {
        final response = await client.rpc(
          'start_location_help_session',
          params: {
            'p_patient_id': patientId,
            'p_device_id': deviceId,
            'p_timeout_minutes': timeoutMinutes,
          },
        );

        return StartLocationSessionResult.fromRpcResponse(
          (response as Map).cast<String, dynamic>(),
        );
      } catch (e) {
        debugPrint('⚠️ startLocationSession error: $e');
        return StartLocationSessionResult(
          success: false,
          errorCode: 'RPC_ERROR',
          errorMessage: 'Could not start location session. Please try again.',
        );
      }
    }

    return StartLocationSessionResult(
      success: false,
      errorCode: 'OFFLINE',
      errorMessage: 'No internet connection. Please check your network.',
    );
  }

  @override
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
  }) async {
    final client = _activeClient;
    final status = await _connectivityMonitor.checkStatus();

    if (client != null &&
        status == NetworkStatus.online &&
        sessionId.isNotEmpty &&
        deviceId.isNotEmpty) {
      try {
        final response = await client.rpc(
          'update_patient_location',
          params: {
            'p_session_id': sessionId,
            'p_device_id': deviceId,
            'p_latitude': latitude,
            'p_longitude': longitude,
            if (accuracy != null) 'p_accuracy': accuracy,
            if (altitude != null) 'p_altitude': altitude,
            if (speed != null) 'p_speed': speed,
            if (heading != null) 'p_heading': heading,
            if (recordedAt != null)
              'p_recorded_at': recordedAt.toUtc().toIso8601String(),
          },
        );

        return UpdateLocationResult.fromRpcResponse(
          (response as Map).cast<String, dynamic>(),
        );
      } catch (e) {
        debugPrint('⚠️ updateLocation error: $e');
        return UpdateLocationResult(
          success: false,
          errorCode: 'RPC_ERROR',
          errorMessage: 'Could not update location',
        );
      }
    }

    return UpdateLocationResult(
      success: false,
      errorCode: 'OFFLINE',
      errorMessage: 'No internet connection',
    );
  }

  @override
  Future<StopLocationSessionResult> stopLocationSession({
    required String sessionId,
    required String stoppedBy,
    String? deviceId,
  }) async {
    final client = _activeClient;
    final status = await _connectivityMonitor.checkStatus();

    if (client != null && status == NetworkStatus.online && sessionId.isNotEmpty) {
      try {
        final response = await client.rpc(
          'stop_location_help_session',
          params: {
            'p_session_id': sessionId,
            'p_stopped_by': stoppedBy,
            if (deviceId != null && deviceId.isNotEmpty) 'p_device_id': deviceId,
          },
        );

        return StopLocationSessionResult.fromRpcResponse(
          (response as Map).cast<String, dynamic>(),
        );
      } catch (e) {
        debugPrint('⚠️ stopLocationSession error: $e');
        return StopLocationSessionResult(
          success: false,
          errorCode: 'RPC_ERROR',
          errorMessage: 'Could not stop location session',
        );
      }
    }

    return StopLocationSessionResult(
      success: false,
      errorCode: 'OFFLINE',
      errorMessage: 'No internet connection',
    );
  }

  @override
  Future<LocationSession?> fetchCaregiverActiveSession(String patientId) async {
    final client = _activeClient;
    final status = await _connectivityMonitor.checkStatus();

    if (client == null || status != NetworkStatus.online || patientId.isEmpty) {
      return null;
    }

    // RLS restricts this read to the authorized caregiver; a caregiver acting
    // on a patient they are not linked to simply receives no rows.
    try {
      final data = await client
          .from('location_sessions')
          .select()
          .eq('patient_id', patientId)
          .eq('status', 'active')
          .gt('expires_at', DateTime.now().toUtc().toIso8601String())
          .order('started_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (data == null) return null;
      return LocationSession.fromMap((data as Map).cast<String, dynamic>());
    } catch (e) {
      debugPrint('⚠️ fetchCaregiverActiveSession error: $e');
      return null;
    }
  }

  @override
  Future<LatestLocationResult> getLatestLocation(String sessionId) async {
    final client = _activeClient;
    final status = await _connectivityMonitor.checkStatus();

    if (client != null && status == NetworkStatus.online && sessionId.isNotEmpty) {
      try {
        final response = await client.rpc(
          'get_latest_location',
          params: {'p_session_id': sessionId},
        );

        return LatestLocationResult.fromRpcResponse(
          (response as Map).cast<String, dynamic>(),
        );
      } catch (e) {
        debugPrint('⚠️ getLatestLocation error: $e');
        return LatestLocationResult(
          success: false,
          hasLocation: false,
          errorCode: 'RPC_ERROR',
          errorMessage: 'Could not fetch location',
        );
      }
    }

    return LatestLocationResult(
      success: false,
      hasLocation: false,
      errorCode: 'OFFLINE',
      errorMessage: 'No internet connection',
    );
  }

  @override
  Stream<PatientLocation> watchLocationUpdates(String sessionId) {
    final client = _activeClient;
    if (client == null) {
      return const Stream.empty();
    }

    return client
        .from('patient_locations')
        .stream(primaryKey: ['id'])
        .eq('session_id', sessionId)
        .order('recorded_at', ascending: false)
        .limit(1)
        .map((data) {
          if (data.isEmpty) {
            throw StateError('No location data');
          }
          return PatientLocation.fromMap(data.first);
        })
        .handleError((error) {
          debugPrint('⚠️ watchLocationUpdates error: $error');
        });
  }

  @override
  Stream<LocationSession> watchSessionStatus(String sessionId) {
    final client = _activeClient;
    if (client == null) {
      return const Stream.empty();
    }

    return client
        .from('location_sessions')
        .stream(primaryKey: ['id'])
        .eq('id', sessionId)
        .limit(1)
        .map((data) {
          if (data.isEmpty) {
            throw StateError('No session data');
          }
          return LocationSession.fromMap(data.first);
        })
        .handleError((error) {
          debugPrint('⚠️ watchSessionStatus error: $error');
        });
  }
}