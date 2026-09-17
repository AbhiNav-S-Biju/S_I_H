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

  @override
  Future<PatientContactInfo> getPatientContact(String patientId) async {
    final client = _activeClient;
    final status = await _connectivityMonitor.checkStatus();

    if (client == null || status != NetworkStatus.online || !_uuidRegex.hasMatch(patientId)) {
      return PatientContactInfo(patientId: patientId, patientName: 'Loved One');
    }

    // The RPC enforces the caregiver -> patient relationship server-side and is
    // the only path by which a patient phone number reaches the client.
    final response = await client.rpc(
      'get_patient_contact_for_caregiver',
      params: {'p_patient_id': patientId},
    );

    final map = (response as Map).cast<String, dynamic>();
    if (map['success'] != true) {
      // Includes UNAUTHORIZED / PATIENT_NOT_FOUND. Never leak which it was.
      return PatientContactInfo(patientId: patientId, patientName: 'Loved One');
    }

    return PatientContactInfo.fromRpcResponse(map);
  }

  @override
  Future<PasscodeSmsResult> sendPasscodeSms({
    required String patientId,
    required String code,
    String? pairingCodeId,
  }) async {
    final client = _activeClient;
    final status = await _connectivityMonitor.checkStatus();

    if (client == null || status != NetworkStatus.online) {
      return const PasscodeSmsResult(
        status: PasscodeSmsStatus.failure,
        message: 'No internet connection. Please check your network.',
      );
    }

    if (client.auth.currentUser == null) {
      return const PasscodeSmsResult(
        status: PasscodeSmsStatus.unauthorized,
        message: 'Please sign in again to send a passcode.',
      );
    }

    if (!_uuidRegex.hasMatch(patientId)) {
      return const PasscodeSmsResult(
        status: PasscodeSmsStatus.failure,
        message: 'Invalid patient identifier.',
      );
    }

    final trimmedCode = code.trim();
    if (trimmedCode.isEmpty) {
      return const PasscodeSmsResult(
        status: PasscodeSmsStatus.staleCode,
        message: 'Generate a passcode first.',
      );
    }

    // Validate phone-number format up-front so the user gets immediate, clear
    // feedback instead of a round trip that can only fail.
    final contact = await getPatientContact(patientId);
    if (!contact.hasPatientPhone) {
      return const PasscodeSmsResult(
        status: PasscodeSmsStatus.noPhone,
        message: 'Phone number not available',
      );
    }
    if (!_isPlausiblePhoneNumber(contact.patientPhone!)) {
      return const PasscodeSmsResult(
        status: PasscodeSmsStatus.failure,
        message:
            'The patient\'s phone number is not valid. Please update it and try again.',
      );
    }

    // Claim the send: verifies server-side that this IS the current passcode and
    // that it has not already been sent. Prevents duplicate/old-code sends.
    final claimResponse = await client.rpc(
      'claim_passcode_sms_send',
      params: {'p_patient_id': patientId, 'p_code': trimmedCode},
    );

    final claim = (claimResponse as Map).cast<String, dynamic>();
    final claimStatus = claim['status'] as String? ?? '';

    if (claimStatus != 'CLAIMED') {
      return PasscodeSmsResult.fromErrorCode(claimStatus);
    }

    final claimedCodeId = (claim['pairing_code_id'] as String?) ?? pairingCodeId;

    // Invoke the secure backend function. Credentials live in Edge Function
    // secrets only — never in this client.
    try {
      final functionResponse = await client.functions.invoke(
        'send-passcode-sms',
        body: {
          'patient_id': patientId,
          'code': trimmedCode,
          if (claimedCodeId != null) 'pairing_code_id': claimedCodeId,
        },
      );

      final data = functionResponse.data;
      final resultMap = data is Map ? data.cast<String, dynamic>() : null;

      if (functionResponse.status == 200 && resultMap?['success'] == true) {
        return PasscodeSmsResult(
          status: PasscodeSmsStatus.sent,
          sentToMasked: resultMap?['sent_to_masked'] as String?,
        );
      }

      final errorCode = resultMap?['error'] as String? ?? '';
      if (errorCode.isNotEmpty) {
        return PasscodeSmsResult.fromErrorCode(errorCode);
      }
      return PasscodeSmsResult.fromErrorCode('HTTP_${functionResponse.status}');
    } catch (e) {
      // Only the exception type is logged — never the passcode or phone number.
      debugPrint('⚠️ send-passcode-sms invocation error: ${e.runtimeType}');
      return const PasscodeSmsResult(
        status: PasscodeSmsStatus.failure,
        message: 'Could not send the passcode. Please try again.',
      );
    }
  }

  /// Lenient E.164-ish check: optional '+', then 8-15 digits once separators are
  /// stripped. Matches the server-side normalization rules.
  bool _isPlausiblePhoneNumber(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 8 && digits.length <= 15;
  }

  /// Generates a pseudo-random 6-digit demo code for offline mode
  String _generateLocalDemoCode() {
    final now = DateTime.now();
    final seed = now.millisecondsSinceEpoch % 900000 + 100000;
    return seed.toString().substring(0, 6);
  }
}
