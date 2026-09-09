// ==============================================================================
// NIRVANA - Caregiver Riverpod Providers
// Description: State management for Caregiver Authentication, Patient Selection,
// Patient Onboarding, Activity Summaries, Game History, Reminder Status, and Sync.
// ==============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/connectivity_monitor.dart';
import '../models/caregiver_models.dart';
import '../repositories/caregiver_notification_repository.dart';
import '../repositories/caregiver_repository.dart';
import '../repositories/pairing_repository.dart';
import '../repositories/supabase_caregiver_notification_repository.dart';
import '../repositories/supabase_caregiver_repository.dart';
import '../repositories/supabase_pairing_repository.dart';
import '../services/caregiver_event_notification_service.dart';

/// Caregiver repository provider
final caregiverRepositoryProvider = Provider<ICaregiverRepository>((ref) {
  final monitor = ref.watch(connectivityMonitorProvider);
  return SupabaseCaregiverRepository(connectivityMonitor: monitor);
});

/// Caregiver notification repository provider
final caregiverNotificationRepositoryProvider =
    Provider<ICaregiverNotificationRepository>((ref) {
  final monitor = ref.watch(connectivityMonitorProvider);
  return SupabaseCaregiverNotificationRepository(connectivityMonitor: monitor);
});

/// Centralized event dispatcher creating telemetry alerts for caregivers
final caregiverEventNotificationServiceProvider =
    Provider<CaregiverEventNotificationService>((ref) {
  final repo = ref.watch(caregiverNotificationRepositoryProvider);
  return CaregiverEventNotificationService(repository: repo);
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
      final repo = ref.watch(caregiverRepositoryProvider);
      return repo.getAssignedPatients(caregiver?.id ?? '');
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
    if (raw.contains('Authentication required') ||
        raw.contains('not authenticated')) {
      return 'Authentication error: Please sign in with your caregiver account first.';
    }
    if (raw.contains('Access denied') ||
        raw.contains('violates row-level security') ||
        raw.contains('row-level security policy') ||
        raw.contains('42501')) {
      return 'Permission error: You do not have authorization to create patients.';
    }
    if (raw.contains('SocketException') || raw.contains('network')) {
      return 'Network issue: Could not connect to Supabase backend.';
    }
    return 'Failed to create patient: ${raw.replaceFirst(RegExp(r'^Exception:\s*'), '')}';
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

/// Notifier for caregiver reminder CRUD operations
class CaregiverRemindersNotifier extends StateNotifier<AsyncValue<void>> {
  final ICaregiverRepository _repository;
  final Ref _ref;

  CaregiverRemindersNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  Future<CaregiverReminderRecord?> createReminder(
    CreateOrUpdateReminderInput input,
  ) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.createReminder(input);
      _ref.invalidate(selectedPatientRemindersProvider);
      _ref.invalidate(selectedPatientSevenDayActivityProvider);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<CaregiverReminderRecord?> updateReminder(
    String reminderId,
    CreateOrUpdateReminderInput input,
  ) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.updateReminder(reminderId, input);
      _ref.invalidate(selectedPatientRemindersProvider);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> toggleReminderActive(String reminderId, bool isActive) async {
    try {
      await _repository.toggleReminderActive(reminderId, isActive);
      _ref.invalidate(selectedPatientRemindersProvider);
    } catch (e) {
      debugPrint('⚠️ Toggle reminder error: $e');
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    try {
      await _repository.deleteReminder(reminderId);
      _ref.invalidate(selectedPatientRemindersProvider);
      _ref.invalidate(selectedPatientSevenDayActivityProvider);
    } catch (e) {
      debugPrint('⚠️ Delete reminder error: $e');
    }
  }
}

/// Provider for caregiver reminder CRUD operations
final caregiverRemindersNotifierProvider =
    StateNotifierProvider<CaregiverRemindersNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(caregiverRepositoryProvider);
  return CaregiverRemindersNotifier(repo, ref);
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

// ==============================================================================
// PAIRING PROVIDERS
// ==============================================================================

/// Pairing repository provider
final pairingRepositoryProvider = Provider<IPairingRepository>((ref) {
  final monitor = ref.watch(connectivityMonitorProvider);
  return SupabasePairingRepository(connectivityMonitor: monitor);
});

/// State for a generated pairing code
class PairingCodeState {
  final bool isLoading;
  final PairingCodeInfo? code;
  final String? errorMessage;

  const PairingCodeState({
    this.isLoading = false,
    this.code,
    this.errorMessage,
  });

  PairingCodeState copyWith({
    bool? isLoading,
    PairingCodeInfo? code,
    String? errorMessage,
    bool clearCode = false,
  }) {
    return PairingCodeState(
      isLoading: isLoading ?? this.isLoading,
      code: clearCode ? null : (code ?? this.code),
      errorMessage: errorMessage,
    );
  }
}

/// Notifier that handles generating a new pairing code
class PairingCodeNotifier extends StateNotifier<PairingCodeState> {
  final IPairingRepository _repository;

  PairingCodeNotifier(this._repository) : super(const PairingCodeState());

  Future<void> generate(String patientId, {int validityMinutes = 15}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final info = await _repository.generatePairingCode(
        patientId,
        validityMinutes: validityMinutes,
      );
      state = state.copyWith(isLoading: false, code: info);
    } catch (e) {
      final raw = e.toString();
      final String msg;
      if (raw.contains('Authentication required') ||
          raw.contains('not authenticated')) {
        msg = 'Please log in to generate a pairing code.';
      } else if (raw.contains('Access denied') ||
          raw.contains('not an authorized caregiver') ||
          raw.contains('P0001')) {
        msg =
            'Access denied: You are not authorized to generate a pairing code for this patient.';
      } else {
        msg =
            'Could not generate a pairing code: ${raw.replaceFirst(RegExp(r'^Exception:\s*'), '')}';
      }
      state = state.copyWith(isLoading: false, errorMessage: msg);
    }
  }

  void reset() => state = const PairingCodeState();
}

/// Provider for pairing code generation
final pairingCodeProvider =
    StateNotifierProvider.autoDispose<PairingCodeNotifier, PairingCodeState>(
  (ref) {
    final repo = ref.watch(pairingRepositoryProvider);
    return PairingCodeNotifier(repo);
  },
);

/// Fetches the currently linked device for the selected patient
final patientLinkedDeviceProvider =
    FutureProvider.autoDispose<PatientDeviceSummary?>((ref) async {
  final selected = ref.watch(selectedPatientProvider);
  if (selected == null) return null;
  final repo = ref.watch(pairingRepositoryProvider);
  return repo.getLinkedDevice(selected.id);
});

// ==============================================================================
// CAREGIVER NOTIFICATION PROVIDERS
// ==============================================================================

/// Realtime notification stream provider for the active caregiver
final caregiverNotificationsStreamProvider =
    StreamProvider.autoDispose<List<CaregiverNotification>>((ref) {
  final authState = ref.watch(caregiverAuthProvider);
  final caregiver = authState.value;
  if (caregiver == null) return const Stream.empty();

  final selectedPatient = ref.watch(selectedPatientProvider);
  final repo = ref.watch(caregiverNotificationRepositoryProvider);

  return repo.getNotificationsStream(
    caregiver.id,
    patientId: selectedPatient?.id,
  );
});

/// Future provider for caregiver notifications (used for initial load / refresh)
final caregiverNotificationsProvider =
    FutureProvider.autoDispose<List<CaregiverNotification>>((ref) async {
  final authState = ref.watch(caregiverAuthProvider);
  final caregiver = authState.value;
  if (caregiver == null) return [];

  final selectedPatient = ref.watch(selectedPatientProvider);
  final repo = ref.watch(caregiverNotificationRepositoryProvider);

  return repo.getNotifications(
    caregiver.id,
    patientId: selectedPatient?.id,
  );
});

/// Realtime unread notifications count
final unreadCaregiverNotificationsCountProvider =
    Provider.autoDispose<int>((ref) {
  final streamAsync = ref.watch(caregiverNotificationsStreamProvider);
  return streamAsync.when(
    data: (list) => list.where((n) => !n.isRead).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Notifier for marking notifications as read
class CaregiverNotificationsNotifier extends StateNotifier<AsyncValue<void>> {
  final ICaregiverNotificationRepository _repository;
  final Ref _ref;

  CaregiverNotificationsNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markAsRead(notificationId);
      _ref.invalidate(caregiverNotificationsProvider);
    } catch (e) {
      debugPrint('⚠️ Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead(String caregiverId) async {
    try {
      await _repository.markAllAsRead(caregiverId);
      _ref.invalidate(caregiverNotificationsProvider);
    } catch (e) {
      debugPrint('⚠️ Error marking all notifications as read: $e');
    }
  }
}

final caregiverNotificationsNotifierProvider =
    StateNotifierProvider<CaregiverNotificationsNotifier, AsyncValue<void>>(
  (ref) {
    final repo = ref.watch(caregiverNotificationRepositoryProvider);
    return CaregiverNotificationsNotifier(repo, ref);
  },
);
