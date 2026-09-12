// ==============================================================================
// NIRVANA - Location Help Riverpod Providers
// Description: State management for the "I'm Lost / I Need Help" location sharing feature.
// ==============================================================================

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/network/connectivity_monitor.dart';
import '../../../database/hive_database.dart';
import '../../caregiver/providers/caregiver_providers.dart';
import '../../patient/providers/patient_pairing_providers.dart';
import '../models/location_help_models.dart';
import '../repositories/location_help_repository.dart';
import '../repositories/supabase_location_help_repository.dart';
import '../services/location_service.dart';
import '../services/phone_dialer.dart';

/// Session lifetime. Mirrors the server-side default in
/// start_location_help_session(); the server remains the source of truth.
const kLocationHelpTimeout = Duration(minutes: 30);

/// How often a fix is written to Supabase while sharing is active.
const kLocationPushInterval = Duration(seconds: 10);

/// A fix worse than this is still sent, but flagged as low quality in the UI.
const kGoodAccuracyMetres = 50.0;

// ==============================================================================
// Infrastructure providers
// ==============================================================================

final locationServiceProvider = Provider<LocationService>((ref) {
  return const LocationService();
});

final phoneDialerProvider = Provider<PhoneDialer>((ref) {
  return const PhoneDialer();
});

/// Location help repository provider
final locationHelpRepositoryProvider = Provider<ILocationHelpRepository>((ref) {
  final monitor = ref.watch(connectivityMonitorProvider);
  return SupabaseLocationHelpRepository(connectivityMonitor: monitor);
});

// ==============================================================================
// Patient-side State Management
// ==============================================================================

enum LocationHelpStatus { idle, requestingPermission, active, stopping, error }

class LocationHelpState {
  final LocationHelpStatus status;
  final LocationSession? session;
  final PatientLocation? currentLocation;
  final String? caregiverName;
  final String? caregiverPhone;
  final String? errorMessage;

  /// True when the OS will not prompt again and the user must use Settings.
  final bool permissionDeniedForever;
  final bool locationServiceDisabled;

  /// How many fixes have been pushed to Supabase this session.
  final int updatesSent;

  const LocationHelpState({
    this.status = LocationHelpStatus.idle,
    this.session,
    this.currentLocation,
    this.caregiverName,
    this.caregiverPhone,
    this.errorMessage,
    this.permissionDeniedForever = false,
    this.locationServiceDisabled = false,
    this.updatesSent = 0,
  });

  bool get isActive => status == LocationHelpStatus.active;
  bool get isStopping => status == LocationHelpStatus.stopping;
  bool get isBusy =>
      status == LocationHelpStatus.requestingPermission ||
      status == LocationHelpStatus.stopping;

  LocationHelpState copyWith({
    LocationHelpStatus? status,
    LocationSession? session,
    PatientLocation? currentLocation,
    String? caregiverName,
    String? caregiverPhone,
    String? errorMessage,
    bool? permissionDeniedForever,
    bool? locationServiceDisabled,
    int? updatesSent,
    bool clearSession = false,
    bool clearLocation = false,
    bool clearError = false,
  }) {
    return LocationHelpState(
      status: status ?? this.status,
      session: clearSession ? null : (session ?? this.session),
      currentLocation:
          clearLocation ? null : (currentLocation ?? this.currentLocation),
      caregiverName: caregiverName ?? this.caregiverName,
      caregiverPhone: caregiverPhone ?? this.caregiverPhone,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      permissionDeniedForever:
          permissionDeniedForever ?? this.permissionDeniedForever,
      locationServiceDisabled:
          locationServiceDisabled ?? this.locationServiceDisabled,
      updatesSent: updatesSent ?? this.updatesSent,
    );
  }
}

class LocationHelpNotifier extends StateNotifier<LocationHelpState> {
  final ILocationHelpRepository _repository;
  final Ref _ref;

  /// The live GPS subscription. Cancelled the moment sharing stops.
  StreamSubscription<Position>? _positionSub;

  /// Fires at the session expiry so we stop without user interaction.
  Timer? _expiryTimer;

  /// Throttles writes so a chatty GPS chip cannot flood Supabase.
  DateTime? _lastPushAt;

  LocationHelpNotifier(this._repository, this._ref)
      : super(const LocationHelpState());

  String get _deviceId => HiveDatabase.getOrCreateDeviceId();

  // ----------------------------------------------------------------------------
  // Start
  // ----------------------------------------------------------------------------

  /// Step 1-4: ask for permission, then open the session and begin streaming.
  ///
  /// Called only after the user confirms the dialog.
  Future<void> confirmAndStart() async {
    if (state.isActive || state.isBusy) return;

    state = state.copyWith(
      status: LocationHelpStatus.requestingPermission,
      clearError: true,
    );

    final patientSession = _ref.read(localPatientSessionProvider);
    final patientId = patientSession?.patientId;

    if (patientId == null || patientId.isEmpty) {
      _fail('This device is not paired yet. Please ask your caregiver for a code.');
      return;
    }

    // --- 3. Location permission -------------------------------------------------
    final locationService = _ref.read(locationServiceProvider);
    final outcome = await locationService.requestPermission();

    if (outcome != LocationPermissionOutcome.granted) {
      state = state.copyWith(
        status: LocationHelpStatus.idle,
        permissionDeniedForever:
            outcome == LocationPermissionOutcome.deniedForever,
        locationServiceDisabled:
            outcome == LocationPermissionOutcome.serviceDisabled,
        errorMessage: outcome == LocationPermissionOutcome.serviceDisabled
            ? 'Please turn on Location in your phone settings, then try again.'
            : 'Location permission is needed to share where you are.',
      );
      return;
    }

    // --- 4. Open (or reuse) the session -----------------------------------------
    final result = await _repository.startLocationSession(
      patientId,
      deviceId: _deviceId,
      timeoutMinutes: kLocationHelpTimeout.inMinutes,
    );

    if (!result.success || result.sessionId == null) {
      _fail(result.errorMessage ?? 'Could not start sharing. Please try again.');
      return;
    }

    final expiresAt = result.expiresAt ??
        DateTime.now().toUtc().add(kLocationHelpTimeout);

    state = state.copyWith(
      status: LocationHelpStatus.active,
      session: LocationSession(
        id: result.sessionId!,
        patientId: patientId,
        caregiverId: result.caregiverId ?? '',
        status: LocationSessionStatus.active,
        startedAt: DateTime.now().toUtc(),
        expiresAt: expiresAt,
        lastLocationUpdate: DateTime.now().toUtc(),
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      ),
      permissionDeniedForever: false,
      locationServiceDisabled: false,
      updatesSent: 0,
    );

    // Caregiver contact details for CALL CARETAKER.
    final active = await _repository.checkActiveSession(
      patientId,
      deviceId: _deviceId,
    );
    if (active.active) {
      state = state.copyWith(
        caregiverName: active.caregiverName,
        caregiverPhone: active.caregiverPhone,
      );
    }

    _startTracking();
    _scheduleAutoStop(expiresAt);
  }

  /// Restore an in-flight session after an app restart (no new permission ask).
  Future<void> resumeIfActive() async {
    if (state.isActive || state.isBusy) return;

    final patientId = _ref.read(localPatientSessionProvider)?.patientId;
    if (patientId == null || patientId.isEmpty) return;

    final active = await _repository.checkActiveSession(
      patientId,
      deviceId: _deviceId,
    );
    if (!active.active || active.sessionId == null) return;

    state = state.copyWith(
      status: LocationHelpStatus.active,
      session: LocationSession(
        id: active.sessionId!,
        patientId: patientId,
        caregiverId: active.caregiverId ?? '',
        status: LocationSessionStatus.active,
        startedAt: active.startedAt ?? DateTime.now().toUtc(),
        expiresAt: active.expiresAt ??
            DateTime.now().toUtc().add(kLocationHelpTimeout),
        lastLocationUpdate: active.lastLocationUpdate,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      ),
      caregiverName: active.caregiverName,
      caregiverPhone: active.caregiverPhone,
    );

    _startTracking();
    _scheduleAutoStop(state.session!.expiresAt);
  }

  // ----------------------------------------------------------------------------
  // Streaming
  // ----------------------------------------------------------------------------

  void _startTracking() {
    _positionSub?.cancel();

    final locationService = _ref.read(locationServiceProvider);

    // Send one immediate fix so the caregiver sees a pin without waiting.
    unawaited(_pushCurrentFix(locationService));

    _positionSub = locationService.positionStream().listen(
          (position) => unawaited(_pushPosition(position)),
          onError: (Object error, StackTrace _) {
            // Coarse reason only — never the coordinates.
            debugPrint('📍 Location stream error: ${error.runtimeType}');
          },
          cancelOnError: false,
        );
  }

  Future<void> _pushCurrentFix(LocationService locationService) async {
    final position = await locationService.getCurrentPosition();
    if (position != null) await _pushPosition(position);
  }

  Future<void> _pushPosition(Position position) async {
    final session = state.session;
    if (session == null || !state.isActive) return;

    // Throttle: at most one write per kLocationPushInterval.
    final now = DateTime.now();
    if (_lastPushAt != null &&
        now.difference(_lastPushAt!) < kLocationPushInterval) {
      return;
    }
    _lastPushAt = now;

    final accuracy = position.accuracy;

    // Update the local view immediately so the on-screen "sent" indicator is
    // instant; the network call follows.
    state = state.copyWith(
      currentLocation: PatientLocation(
        id: '',
        sessionId: session.id,
        patientId: session.patientId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: accuracy,
        altitude: position.altitude,
        speed: position.speed,
        heading: position.heading,
        recordedAt: position.timestamp,
        createdAt: position.timestamp,
      ),
    );

    final result = await _repository.updateLocation(
      sessionId: session.id,
      deviceId: _deviceId,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: accuracy,
      altitude: position.altitude,
      speed: position.speed,
      heading: position.heading,
      recordedAt: position.timestamp,
    );

    if (result.success) {
      state = state.copyWith(updatesSent: state.updatesSent + 1);
      return;
    }

    // The server has closed the session (stopped or expired): stop locally too.
    if (result.errorCode == 'SESSION_NOT_ACTIVE' ||
        result.errorCode == 'SESSION_EXPIRED') {
      debugPrint('📍 Sharing ended server-side (${result.errorCode})');
      await _teardownLocal();
    }
  }

  // ----------------------------------------------------------------------------
  // Stop
  // ----------------------------------------------------------------------------

  /// Step 8: automatic stop when the 30-minute window elapses.
  void _scheduleAutoStop(DateTime expiresAt) {
    _expiryTimer?.cancel();

    final remaining = expiresAt.difference(DateTime.now().toUtc());
    final delay = remaining.isNegative ? Duration.zero : remaining;

    _expiryTimer = Timer(delay, () async {
      final session = state.session;
      if (session == null) return;

      // Best-effort server stop, then always tear down locally.
      await _repository.stopLocationSession(
        sessionId: session.id,
        stoppedBy: 'patient',
        deviceId: _deviceId,
      );
      await _teardownLocal();
    });
  }

  /// User pressed STOP SHARING.
  Future<void> stopSession() async {
    final session = state.session;
    if (session == null) return;

    state = state.copyWith(status: LocationHelpStatus.stopping);

    final result = await _repository.stopLocationSession(
      sessionId: session.id,
      stoppedBy: 'patient',
      deviceId: _deviceId,
    );

    if (result.success) {
      await _teardownLocal();
    } else {
      // Even if the network call failed, stop streaming on this device so we
      // are never sharing longer than the user asked.
      await _teardownLocal();
      state = state.copyWith(
        errorMessage:
            result.errorMessage ?? 'Sharing stopped on this phone.',
      );
    }
  }

  /// Cancels every timer/subscription and clears the session from state.
  Future<void> _teardownLocal() async {
    await _positionSub?.cancel();
    _positionSub = null;
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _lastPushAt = null;

    state = state.copyWith(
      status: LocationHelpStatus.idle,
      clearSession: true,
      clearLocation: true,
    );
  }

  void _fail(String message) {
    state = state.copyWith(
      status: LocationHelpStatus.error,
      errorMessage: message,
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Reset to idle
  void reset() {
    state = const LocationHelpState();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _expiryTimer?.cancel();
    super.dispose();
  }
}

final locationHelpProvider =
    StateNotifierProvider<LocationHelpNotifier, LocationHelpState>((ref) {
  final repo = ref.watch(locationHelpRepositoryProvider);
  return LocationHelpNotifier(repo, ref);
});

// ==============================================================================
// Caregiver-side Providers
// ==============================================================================

/// The active help session for the caregiver's currently selected patient.
///
/// Reads through RLS with the caregiver's authenticated session — an
/// unauthorized caregiver is returned null because RLS yields no row.
final activeLocationHelpSessionProvider =
    FutureProvider.autoDispose<LocationSession?>((ref) async {
  final selectedPatient = ref.watch(selectedPatientProvider);
  if (selectedPatient == null) return null;

  final repo = ref.watch(locationHelpRepositoryProvider);
  return repo.fetchCaregiverActiveSession(selectedPatient.id);
});

/// Stream provider for realtime location updates (caregiver side)
final locationUpdatesStreamProvider = StreamProvider.autoDispose<PatientLocation?>((ref) {
  final sessionAsync = ref.watch(activeLocationHelpSessionProvider);
  final session = sessionAsync.value;

  if (session == null || session.id.isEmpty) {
    return const Stream.empty();
  }

  final repo = ref.watch(locationHelpRepositoryProvider);
  return repo.watchLocationUpdates(session.id).map((loc) => loc).handleError((_) => null);
});

/// Stream provider for session status changes (caregiver side)
final locationSessionStatusStreamProvider = StreamProvider.autoDispose<LocationSession?>((ref) {
  final sessionAsync = ref.watch(activeLocationHelpSessionProvider);
  final session = sessionAsync.value;

  if (session == null || session.id.isEmpty) {
    return const Stream.empty();
  }

  final repo = ref.watch(locationHelpRepositoryProvider);
  return repo.watchSessionStatus(session.id).map((s) => s).handleError((_) => null);
});

/// Provider for latest location (initial load for caregiver)
final latestLocationProvider = FutureProvider.autoDispose<LatestLocationResult?>((ref) async {
  final sessionAsync = ref.watch(activeLocationHelpSessionProvider);
  final session = sessionAsync.value;

  if (session == null || session.id.isEmpty) return null;

  final repo = ref.watch(locationHelpRepositoryProvider);
  return repo.getLatestLocation(session.id);
});

/// Notifier for caregiver to stop location session
class CaregiverLocationHelpNotifier extends StateNotifier<AsyncValue<void>> {
  final ILocationHelpRepository _repository;
  final Ref _ref;

  CaregiverLocationHelpNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> stopSession(String sessionId) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.stopLocationSession(
        sessionId: sessionId,
        stoppedBy: 'caregiver',
      );

      if (result.success) {
        _ref.invalidate(activeLocationHelpSessionProvider);
        _ref.invalidate(locationUpdatesStreamProvider);
        _ref.invalidate(locationSessionStatusStreamProvider);
        _ref.invalidate(latestLocationProvider);
        state = const AsyncValue.data(null);
      } else {
        state = AsyncValue.error(
          Exception(result.errorMessage ?? 'Failed to stop session'),
          StackTrace.current,
        );
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final caregiverLocationHelpNotifierProvider =
    StateNotifierProvider<CaregiverLocationHelpNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(locationHelpRepositoryProvider);
  return CaregiverLocationHelpNotifier(repo, ref);
});// ==============================================================================
// Caregiver "Needs Help" surface
// ==============================================================================

/// True when the selected patient currently has a live help request.
///
/// Drives the prominent banner on the caregiver dashboard. Re-evaluates when
/// the realtime session stream reports a status change, so the banner appears
/// the moment a patient asks for help and disappears the moment sharing ends.
final patientNeedsHelpProvider = Provider.autoDispose<bool>((ref) {
  final session = ref.watch(activeLocationHelpSessionProvider).value;
  return session != null && session.isActive;
});

/// The most recent location point for the selected patient, preferring realtime
/// data and falling back to the initial RPC fetch.
final currentPatientLocationProvider =
    Provider.autoDispose<PatientLocation?>((ref) {
  final realtime = ref.watch(locationUpdatesStreamProvider).value;
  if (realtime != null) return realtime;

  final latest = ref.watch(latestLocationProvider).value;
  if (latest == null || !latest.success || !latest.hasLocation) return null;
  if (latest.latitude == null || latest.longitude == null) return null;

  return PatientLocation(
    id: '',
    sessionId: ref.watch(activeLocationHelpSessionProvider).value?.id ?? '',
    patientId: '',
    latitude: latest.latitude!,
    longitude: latest.longitude!,
    accuracy: latest.accuracy,
    altitude: latest.altitude,
    speed: latest.speed,
    heading: latest.heading,
    recordedAt: latest.recordedAt ?? DateTime.now().toUtc(),
    createdAt: latest.recordedAt ?? DateTime.now().toUtc(),
  );
});

/// The patient phone number, for CALL PATIENT. Sourced from the caregiver RPC
/// so the number is never exposed to anyone but the authorized caregiver.
final patientPhoneProvider = Provider.autoDispose<String?>((ref) {
  return ref.watch(latestLocationProvider).value?.patientPhone;
});
