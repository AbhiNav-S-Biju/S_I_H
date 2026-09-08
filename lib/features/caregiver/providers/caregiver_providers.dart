// ==============================================================================
// NIRVANA - Caregiver Riverpod Providers
// Description: State management for Caregiver Authentication, Patient Selection,
// Activity Summaries, Game History, Reminder Status, and Synchronization.
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
