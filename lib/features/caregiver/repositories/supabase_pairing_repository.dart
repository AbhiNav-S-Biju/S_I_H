// ==============================================================================
// NIRVANA - Supabase Caregiver Pairing Repository
// Description: Implements IPairingRepository using Supabase RPCs for generating
// patient pairing codes and managing linked devices, with offline fallback.
// ==============================================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/connectivity_monitor.dart';
import '../models/caregiver_models.dart';
import 'pairing_repository.dart';

class SupabasePairingRepository implements IPairingRepository {
  final SupabaseClient? _client;
  final IConnectivityMonitor _connectivityMonitor;

  SupabasePairingRepository({
    SupabaseClient? client,
    IConnectivityMonitor? connectivityMonitor,
  }) : _client = client,
       _connectivityMonitor = connectivityMonitor ?? ConnectivityMonitor();

  SupabaseClient? get _activeClient {
    if (_client != null) return _client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  @override
  Future<PairingCodeInfo> generatePairingCode(
    String patientId, {
    int validityMinutes = 15,
  }) async {
    final client = _activeClient;
    final status = await _connectivityMonitor.checkStatus();
    final isUuid = _uuidRegex.hasMatch(patientId);

    if (client != null && status == NetworkStatus.online) {
      if (client.auth.currentUser == null) {
        throw Exception(
          'Authentication required: Caregiver must be logged in to generate a pairing code.',
        );
      }
      if (!isUuid) {
        throw Exception('Invalid patient identifier: $patientId');
      }

      try {
        // Call the server-side RPC that generates a secure one-time code
        final result = await client.rpc(
          'generate_patient_pairing_code',
          params: {
            'p_patient_id': patientId,
            'p_validity_minutes': validityMinutes,
          },
        );

        final code = result as String;
        return PairingCodeInfo(
          code: code,
          expiresAt: DateTime.now().add(Duration(minutes: validityMinutes)),
          patientId: patientId,
        );
      } catch (e) {
        debugPrint('⚠️ generate_patient_pairing_code RPC error: $e');
        rethrow;
      }
    }

    // Offline fallback: generate a readable demo code (strictly when offline)
    debugPrint('⚠️ Offline mode — generating local demo pairing code');
    final demoCode = _generateLocalDemoCode();
    return PairingCodeInfo(
      code: demoCode,
      expiresAt: DateTime.now().add(Duration(minutes: validityMinutes)),
      patientId: patientId,
    );
  }

  @override
  Future<PatientDeviceSummary?> getLinkedDevice(String patientId) async {
    final client = _activeClient;
    final status = await _connectivityMonitor.checkStatus();
    final isUuid = _uuidRegex.hasMatch(patientId);

    if (client != null && status == NetworkStatus.online && isUuid) {
      try {
        final response = await client
            .from('patient_devices')
            .select()
            .eq('patient_id', patientId)
            .eq('is_active', true)
            .order('paired_at', ascending: false)
            .limit(1);

        final list = response as List;
        if (list.isEmpty) return null;

        return PatientDeviceSummary.fromMap(list.first as Map<String, dynamic>);
      } catch (e) {
        debugPrint('⚠️ getLinkedDevice error: $e');
      }
    }

    return null; // No device linked (offline or not found)
  }

  @override
  Future<void> revokeDevice(String deviceId) async {
    final client = _activeClient;
    final status = await _connectivityMonitor.checkStatus();

    if (client != null && status == NetworkStatus.online) {
      try {
        await client
            .from('patient_devices')
            .update({
              'is_active': false,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('device_id', deviceId);
        return;
      } catch (e) {
        debugPrint('⚠️ revokeDevice error: $e');
        rethrow;
      }
    }

    debugPrint('⚠️ Offline — revokeDevice skipped (no connectivity)');
  }

  /// Generates a pseudo-random 6-digit demo code for offline mode
  String _generateLocalDemoCode() {
    final now = DateTime.now();
    final seed = now.millisecondsSinceEpoch % 900000 + 100000;
    return seed.toString().substring(0, 6);
  }
}
