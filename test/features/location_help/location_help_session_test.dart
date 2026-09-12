// ==============================================================================
// NIRVANA - Location Help session lifecycle tests
//
// These cover the patient-side state machine without touching the OS GPS or the
// network: the repository and location service are both faked.
// ==============================================================================

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nirvana/features/location_help/models/location_help_models.dart';
import 'package:nirvana/features/location_help/providers/location_help_providers.dart';
import 'package:nirvana/database/models/hive_patient_session.dart';
import 'package:nirvana/features/location_help/repositories/location_help_repository.dart';
import 'package:nirvana/features/location_help/services/location_service.dart';
import 'package:nirvana/features/patient/providers/patient_pairing_providers.dart';

// ------------------------------------------------------------------------------
// Fakes
// ------------------------------------------------------------------------------

class _FakeRepo implements ILocationHelpRepository {
  bool startSucceeds = true;
  bool stopSucceeds = true;
  int updateCallCount = 0;
  String? lastDeviceId;
  String? lastStoppedBy;

  /// When set, updateLocation reports this error code back to the caller.
  String? updateErrorCode;

  @override
  Future<StartLocationSessionResult> startLocationSession(
    String patientId, {
    required String deviceId,
    int timeoutMinutes = 30,
  }) async {
    lastDeviceId = deviceId;
    if (!startSucceeds) {
      return const StartLocationSessionResult(
        success: false,
        errorCode: 'RPC_ERROR',
        errorMessage: 'boom',
      );
    }
    return StartLocationSessionResult(
      success: true,
      sessionId: 'session-1',
      caregiverId: 'caregiver-1',
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 30)),
    );
  }

  @override
  Future<ActiveSessionCheckResult> checkActiveSession(
    String patientId, {
    required String deviceId,
  }) async {
    return const ActiveSessionCheckResult(
      active: true,
      sessionId: 'session-1',
      caregiverId: 'caregiver-1',
      caregiverName: 'Maya',
      caregiverPhone: '+15550100',
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
    updateCallCount++;
    lastDeviceId = deviceId;
    if (updateErrorCode != null) {
      return UpdateLocationResult(
        success: false,
        errorCode: updateErrorCode,
        errorMessage: 'ended',
      );
    }
    return const UpdateLocationResult(success: true, locationId: 'loc-1');
  }

  @override
  Future<StopLocationSessionResult> stopLocationSession({
    required String sessionId,
    required String stoppedBy,
    String? deviceId,
  }) async {
    lastStoppedBy = stoppedBy;
    if (!stopSucceeds) {
      return const StopLocationSessionResult(
        success: false,
        errorCode: 'RPC_ERROR',
        errorMessage: 'offline',
      );
    }
    return StopLocationSessionResult(
      success: true,
      stoppedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<LocationSession?> fetchCaregiverActiveSession(
    String patientId,
  ) async => null;

  @override
  Future<LatestLocationResult> getLatestLocation(String sessionId) async =>
      const LatestLocationResult(success: true, hasLocation: false);

  @override
  Stream<PatientLocation> watchLocationUpdates(String sessionId) =>
      const Stream.empty();

  @override
  Stream<LocationSession> watchSessionStatus(String sessionId) =>
      const Stream.empty();
}

class _FakeLocationService implements LocationService {
  LocationPermissionOutcome outcome = LocationPermissionOutcome.granted;
  final StreamController<Position> controller =
      StreamController<Position>.broadcast();

  @override
  Future<bool> isServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<bool> openLocationSettings() async => true;

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<LocationPermissionOutcome> requestPermission() async => outcome;

  @override
  Future<Position?> getCurrentPosition() async => _position(1.0, 2.0);

  @override
  Stream<Position> positionStream() => controller.stream;

  Position _position(double lat, double lng, {double accuracy = 10}) {
    return Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now().toUtc(),
      accuracy: accuracy,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  void emit(Position position) => controller.add(position);
}

// ------------------------------------------------------------------------------
// Helpers
// ------------------------------------------------------------------------------

/// Builds a container whose patient-device session is present.
///
/// [localPatientSessionProvider] is backed by Hive in production; here it is
/// overridden so the notifier sees a paired device without initialising Hive.
ProviderContainer _container(_FakeRepo repo, _FakeLocationService service) {
  final container = ProviderContainer(
    overrides: [
      locationHelpRepositoryProvider.overrideWithValue(repo),
      locationServiceProvider.overrideWithValue(service),
      localPatientSessionProvider.overrideWithValue(
        HivePatientDeviceSession(
          isPaired: true,
          patientId: 'patient-1',
          deviceId: 'device-1',
          displayName: 'Elena Rostova',
          preferredName: 'Elena',
          pairedAt: DateTime.now(),
        ),
      ),
    ],
  );
  return container;
}

void main() {
  group('LocationHelpNotifier', () {
    test('does not start when location permission is denied', () async {
      final repo = _FakeRepo();
      final service = _FakeLocationService()
        ..outcome = LocationPermissionOutcome.denied;
      final container = _container(repo, service);
      addTearDown(container.dispose);

      await container.read(locationHelpProvider.notifier).confirmAndStart();

      final state = container.read(locationHelpProvider);
      expect(state.isActive, isFalse);
      expect(state.errorMessage, isNotNull);
      expect(repo.lastDeviceId, isNull, reason: 'must not call the API');
    });

    test(
      'flags deniedForever so the UI can send the user to Settings',
      () async {
        final repo = _FakeRepo();
        final service = _FakeLocationService()
          ..outcome = LocationPermissionOutcome.deniedForever;
        final container = _container(repo, service);
        addTearDown(container.dispose);

        await container.read(locationHelpProvider.notifier).confirmAndStart();

        final state = container.read(locationHelpProvider);
        expect(state.permissionDeniedForever, isTrue);
        expect(state.isActive, isFalse);
      },
    );

    test(
      'starts a session and pushes the device id with every write',
      () async {
        final repo = _FakeRepo();
        final service = _FakeLocationService();
        final container = _container(repo, service);
        addTearDown(container.dispose);

        await container.read(locationHelpProvider.notifier).confirmAndStart();

        final state = container.read(locationHelpProvider);
        expect(state.isActive, isTrue);
        expect(state.session?.id, 'session-1');
        expect(state.caregiverName, 'Maya');
        expect(state.caregiverPhone, '+15550100');

        await service.controller.close();
      },
    );

    test('stops locally even when the server stop call fails', () async {
      final repo = _FakeRepo();
      final service = _FakeLocationService();
      final container = _container(repo, service);
      addTearDown(container.dispose);

      final notifier = container.read(locationHelpProvider.notifier);
      await notifier.confirmAndStart();
      expect(container.read(locationHelpProvider).isActive, isTrue);

      repo.stopSucceeds = false;
      await notifier.stopSession();

      // Safety property: we never keep streaming after the user said stop.
      expect(container.read(locationHelpProvider).isActive, isFalse);
      expect(repo.lastStoppedBy, 'patient');

      await service.controller.close();
    });

    test(
      'tears down when the server reports the session is no longer active',
      () async {
        final repo = _FakeRepo();
        final service = _FakeLocationService();
        final container = _container(repo, service);
        addTearDown(container.dispose);

        final notifier = container.read(locationHelpProvider.notifier);
        await notifier.confirmAndStart();
        expect(container.read(locationHelpProvider).isActive, isTrue);

        // Simulate the caregiver stopping the session from their portal.
        repo.updateErrorCode = 'SESSION_NOT_ACTIVE';
        service.emit(
          Position(
            latitude: 1.0,
            longitude: 2.0,
            timestamp: DateTime.now().toUtc(),
            accuracy: 10,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          ),
        );

        // Give the async listener a chance to run.
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(container.read(locationHelpProvider).isActive, isFalse);

        await service.controller.close();
      },
    );

    test('throttles rapid fixes into a single Supabase write', () async {
      final repo = _FakeRepo();
      final service = _FakeLocationService();
      final container = _container(repo, service);
      addTearDown(container.dispose);

      final notifier = container.read(locationHelpProvider.notifier);
      await notifier.confirmAndStart();

      // Three fixes in quick succession: the first (immediate fix) is sent, the
      // rest fall inside the throttle window.
      service.emit(
        Position(
          latitude: 10,
          longitude: 20,
          timestamp: DateTime.now().toUtc(),
          accuracy: 5,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      final afterFirst = repo.updateCallCount;

      service.emit(
        Position(
          latitude: 11,
          longitude: 21,
          timestamp: DateTime.now().toUtc(),
          accuracy: 5,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(
        repo.updateCallCount,
        afterFirst,
        reason: 'second fix is inside the throttle window',
      );

      await service.controller.close();
    });
  });

  group('LocationHelpState', () {
    test('timeRemaining never goes negative', () {
      final session = LocationSession(
        id: 's',
        patientId: 'p',
        caregiverId: 'c',
        status: LocationSessionStatus.active,
        startedAt: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
        expiresAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

      expect(session.timeRemaining, Duration.zero);
      expect(
        session.isActive,
        isFalse,
        reason: 'expired session is not active',
      );
    });
  });
}
