// ==============================================================================
// NIRVANA - Supabase Patient Pairing Repository
// Description: Implements IPatientPairingRepository by calling the server-side
// validate_and_pair_device RPC, then persisting the session locally in Hive
// for zero-password subsequent launches. Includes offline demo mode fallback.
// ==============================================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/connectivity_monitor.dart';
import '../../../database/hive_database.dart';
import '../../../database/models/hive_patient_session.dart';
import '../../caregiver/models/caregiver_models.dart';
import 'patient_pairing_repository.dart';

class SupabasePatientPairingRepository implements IPatientPairingRepository {
  final SupabaseClient? _client;
  final IConnectivityMonitor _connectivityMonitor;

  SupabasePatientPairingRepository({
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
  Future<PairDeviceResult> validateAndPairDevice({
    required String code,
    required String deviceId,
    String? deviceName,
  }) async {
    final client = _activeClient;
    final status = await _connectivityMonitor.checkStatus();

    if (client != null && status == NetworkStatus.online) {
      try {
        final response = await client.rpc(
          'validate_and_pair_device',
          params: {
            'p_code': code.trim(),
            'p_device_id': deviceId,
            'p_device_name': deviceName ?? 'Elder Device',
          },
        );

        final result = PairDeviceResult.fromRpcResponse(
          (response as Map).cast<String, dynamic>(),
        );

        if (result.success && result.patientId != null) {
          // Persist session locally so future launches skip pairing entirely
          await saveSession(
            HivePatientDeviceSession(
              isPaired: true,
              patientId: result.patientId!,
              deviceId: deviceId,
              displayName: result.displayName ?? 'Loved One',
              preferredName: result.preferredName ?? 'Loved One',
              pairedAt: DateTime.now(),
              lastSyncAt: DateTime.now(),
              isActive: true,
              accessibilitySettings: const {},
            ),
          );
        }

        return result;
      } catch (e) {
        debugPrint('⚠️ validate_and_pair_device error: $e');
        return PairDeviceResult(
          success: false,
          errorCode: 'RPC_ERROR',
          errorMessage: 'Could not verify the code. Please try again.',
        );
      }
    }

    // ---------------------------------------------------------------------------
    // Offline demo mode: Accept any 6-digit code and create a local session
    // ---------------------------------------------------------------------------
    debugPrint('⚠️ Offline mode — accepting demo pairing code: $code');

    if (code.trim().length != 6 || int.tryParse(code.trim()) == null) {
      return const PairDeviceResult(
        success: false,
        errorCode: 'INVALID_CODE_FORMAT',
        errorMessage: 'Please enter the 6-digit code your caregiver showed you.',
      );
    }

    const demoPatientId = '11111111-1111-4111-8111-111111111111';
    const demoDisplayName = 'Elena Rostova';
    const demoPreferredName = 'Elena';

    await saveSession(
      HivePatientDeviceSession(
        isPaired: true,
        patientId: demoPatientId,
        deviceId: deviceId,
        displayName: demoDisplayName,
        preferredName: demoPreferredName,
        pairedAt: DateTime.now(),
        lastSyncAt: DateTime.now(),
        isActive: true,
        accessibilitySettings: const {
          'large_text': true,
          'high_contrast': true,
          'audio_prompts': true,
          'font_scale': 1.3,
        },
      ),
    );

    return const PairDeviceResult(
      success: true,
      patientId: demoPatientId,
      displayName: demoDisplayName,
      preferredName: demoPreferredName,
      deviceId: 'demo-device',
    );
  }

  @override
  HivePatientDeviceSession? loadLocalSession() {
    return HiveDatabase.currentPatientSession;
  }

  @override
  Future<void> saveSession(HivePatientDeviceSession session) async {
    await HiveDatabase.savePatientSession(session);
  }

  @override
  Future<void> clearSession() async {
    await HiveDatabase.clearPatientSession();
  }
}
