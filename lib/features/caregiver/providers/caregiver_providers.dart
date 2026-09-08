// ==============================================================================
// NIRVANA - Caregiver Riverpod Providers
// Description: State management for Caregiver Authentication, Patient Selection,
// Patient Onboarding, Activity Summaries, Game History, Reminder Status, and Sync.
// ==============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/connectivity_monitor.dart';
import '../models/caregiver_models.dart';
import '../repositories/caregiver_repository.dart';
import '../repositories/supabase_caregiver_repository.dart';

/// Caregiver repository provider
final caregiverRepositoryProvider = Provider<ICaregiverRepository>((ref) {
  final monitor = ref.watch(connectivityMonitorProvider);
  return SupabaseCaregiverRepository(connectivityMonitor: monitor);
});

/// Caregiver Authentication StateNotifier
class CaregiverAuthNotifier
    extends StateNotifier<AsyncValue<CaregiverProfile?>> {
  final ICaregiverRepository _repository;

  CaregiverAuthNotifier(this._repository) : super(const AsyncValue.data(null)) {
    _init();
  }

  Future<void> _init() async {
    final current = await _repository.getCurrentCaregiver();
    if (current != null) {
      state = AsyncValue.data(current);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final profile = await _repository.login(email: email, password: password);
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    state = const AsyncValue.loading();
    try {
      final profile = await _repository.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    await _repository.logout();
    state = const AsyncValue.data(null);
  }
}

final caregiverAuthProvider =
    StateNotifierProvider<CaregiverAuthNotifier, AsyncValue<CaregiverProfile?>>(
      (ref) {
        final repo = ref.watch(caregiverRepositoryProvider);
        return CaregiverAuthNotifier(repo);
      },
    );

/// List of accessible patients assigned to the current caregiver
final assignedPatientsProvider =
    FutureProvider.autoDispose<List<PatientSummary>>((ref) async {
      final authState = ref.watch(caregiverAuthProvider);
      final caregiver = authState.value;
      if (caregiver == null) return [];

      final repo = ref.watch(caregiverRepositoryProvider);
      return repo.getAssignedPatients(caregiver.id);
    });

/// Currently selected patient provider
final selectedPatientProvider = StateProvider<PatientSummary?>((ref) {
  final patientsAsync = ref.watch(assignedPatientsProvider);
  return patientsAsync.when(
    data: (patients) => patients.isNotEmpty ? patients.first : null,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Patient Onboarding State
class PatientOnboardingState {
  final bool isLoading;
  final PatientSummary? createdPatient;
  final String? errorMessage;

  const PatientOnboardingState({
    this.isLoading = false,
    this.createdPatient,
    this.errorMessage,
  });

  PatientOnboardingState copyWith({
    bool? isLoading,
    PatientSummary? createdPatient,
    String? errorMessage,
  }) {
    return PatientOnboardingState(
      isLoading: isLoading ?? this.isLoading,
      createdPatient: createdPatient ?? this.createdPatient,
      errorMessage: errorMessage,
    );
  }
}

/// State notifier for Patient Onboarding
class PatientOnboardingNotifier extends StateNotifier<PatientOnboardingState> {
  final ICaregiverRepository _repository;
  final Ref _ref;

  PatientOnboardingNotifier(this._repository, this._ref)
      : super(const PatientOnboardingState());

  Future<PatientSummary?> createPatient(CreatePatientInput input) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final caregiver = _ref.read(caregiverAuthProvider).value;
      final patient = await _repository.createPatient(
        input: input,
        caregiverId: caregiver?.id,
      );

      // Invalidate assigned patients so the list refreshes
      _ref.invalidate(assignedPatientsProvider);

      // Auto-select the newly created patient
      _ref.read(selectedPatientProvider.notifier).state = patient;

      state = state.copyWith(isLoading: false, createdPatient: patient);
      return patient;
    } catch (e) {
      final message = _friendlyError(e.toString());
      state = state.copyWith(isLoading: false, errorMessage: message);
      return null;
    }
  }

  void reset() {
    state = const PatientOnboardingState();
  }

  String _friendlyError(String raw) {
    if (raw.contains('violates row-level security') ||
        raw.contains('row-level security policy')) {
      return 'Security error: You do not have permission to link this patient.';
    }
    if (raw.contains('SocketException') || raw.contains('network')) {
      return 'Network issue. Patient saved in offline cache.';
    }
    return 'Failed to create patient record. Please check details and try again.';
  }
}

final patientOnboardingProvider =
    StateNotifierProvider<PatientOnboardingNotifier, PatientOnboardingState>((ref) {
  final repo = ref.watch(caregiverRepositoryProvider);
  return PatientOnboardingNotifier(repo, ref);
});

/// Game History for selected patient
final selectedPatientGameHistoryProvider =
    FutureProvider.autoDispose<List<CaregiverGameRecord>>((ref) async {
      final selected = ref.watch(selectedPatientProvider);
      if (selected == null) return [];

      final repo = ref.watch(caregiverRepositoryProvider);
      return repo.getGameHistory(selected.id);
    });

/// Reminder Status for selected patient
final selectedPatientRemindersProvider =
    FutureProvider.autoDispose<List<CaregiverReminderRecord>>((ref) async {
      final selected = ref.watch(selectedPatientProvider);
      if (selected == null) return [];

      final repo = ref.watch(caregiverRepositoryProvider);
      return repo.getReminderStatus(selected.id);
    });

/// 7-Day Activity Summary for selected patient
final selectedPatientSevenDayActivityProvider =
    FutureProvider.autoDispose<List<DailyActivitySummary>>((ref) async {
      final selected = ref.watch(selectedPatientProvider);
      if (selected == null) return [];

      final repo = ref.watch(caregiverRepositoryProvider);
      return repo.getSevenDayActivity(selected.id);
    });

/// Real-time Sync Status provider
final caregiverSyncStatusProvider =
    FutureProvider.autoDispose<CaregiverSyncInfo>((ref) async {
      final selected = ref.watch(selectedPatientProvider);
      final repo = ref.watch(caregiverRepositoryProvider);
      return repo.getSyncStatus(selected?.id ?? '');
    });
