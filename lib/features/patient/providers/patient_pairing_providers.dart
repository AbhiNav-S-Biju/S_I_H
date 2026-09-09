// ==============================================================================
// NIRVANA - Patient Pairing Riverpod Providers
// Description: State management for the patient-device pairing flow.
// Handles code validation, session loading, and paired-state checks.
// ==============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/connectivity_monitor.dart';
import '../../../database/hive_database.dart';
import '../../../database/models/hive_patient_session.dart';
import '../../caregiver/models/caregiver_models.dart';
import '../repositories/patient_pairing_repository.dart';
import '../repositories/supabase_patient_pairing_repository.dart';

/// Patient pairing repository provider
final patientPairingRepositoryProvider =
    Provider<IPatientPairingRepository>((ref) {
  final monitor = ref.watch(connectivityMonitorProvider);
  return SupabasePatientPairingRepository(connectivityMonitor: monitor);
});

// ==============================================================================
// State model
// ==============================================================================

enum PatientPairingStatus { idle, loading, success, error }

class PatientPairingState {
  final PatientPairingStatus status;
  final PairDeviceResult? result;
  final String? errorMessage;

  const PatientPairingState({
    this.status = PatientPairingStatus.idle,
    this.result,
    this.errorMessage,
  });

  bool get isLoading => status == PatientPairingStatus.loading;
  bool get isSuccess => status == PatientPairingStatus.success;
  bool get isError => status == PatientPairingStatus.error;

  PatientPairingState copyWith({
    PatientPairingStatus? status,
    PairDeviceResult? result,
    String? errorMessage,
  }) {
    return PatientPairingState(
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: errorMessage,
    );
  }
}

// ==============================================================================
// Notifier
// ==============================================================================

class PatientPairingNotifier extends StateNotifier<PatientPairingState> {
  final IPatientPairingRepository _repository;

  PatientPairingNotifier(this._repository)
      : super(const PatientPairingState());

  /// Validates the 6-digit [code] and pairs this device with the patient.
  Future<void> pair(String code) async {
    state = state.copyWith(status: PatientPairingStatus.loading);

    final deviceId = HiveDatabase.getOrCreateDeviceId();

    final result = await _repository.validateAndPairDevice(
      code: code,
      deviceId: deviceId,
      deviceName: 'Elder Mobile Device',
    );

    if (result.success) {
      state = state.copyWith(
        status: PatientPairingStatus.success,
        result: result,
      );
    } else {
      state = state.copyWith(
        status: PatientPairingStatus.error,
        errorMessage: result.errorMessage ??
            'The code is incorrect or has expired. Please ask your caregiver for a new one.',
      );
    }
  }

  void reset() => state = const PatientPairingState();
}

/// Provider for patient pairing state
final patientPairingProvider =
    StateNotifierProvider<PatientPairingNotifier, PatientPairingState>((ref) {
  final repo = ref.watch(patientPairingRepositoryProvider);
  return PatientPairingNotifier(repo);
});

// ==============================================================================
// Local session providers
// ==============================================================================

/// Returns true if this device is already paired (from local Hive storage).
/// Safe to call synchronously since HiveDatabase is initialized in main().
final isDevicePairedProvider = Provider<bool>((ref) {
  return HiveDatabase.isDevicePaired;
});

/// Returns the current local patient session, or null if not paired.
final localPatientSessionProvider = Provider<HivePatientDeviceSession?>((ref) {
  return HiveDatabase.currentPatientSession;
});
