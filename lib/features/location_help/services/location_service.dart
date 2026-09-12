// ==============================================================================
// NIRVANA - Location Tracking Service
// Description: Thin, testable wrapper around the device GPS.
//
// FOREGROUND ONLY (MVP). We deliberately do NOT enable background location:
// the existing architecture has no background isolate / foreground-service
// plumbing, and the brief asks for reliable foreground tracking first.
// Sharing is tied to the visible "sharing active" screen.
//
// Privacy: nothing in this file writes location data to disk or to the log.
// Coordinates are never handed to debugPrint.
// ==============================================================================

import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// Outcome of asking the OS for location permission.
enum LocationPermissionOutcome {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

class LocationService {
  const LocationService();

  /// Whether the device's location hardware/service is switched on.
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  /// Current permission state without prompting.
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  /// Open the OS location settings (used by the rationale dialog).
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  /// Open this app's permission settings page.
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// Prompt for permission if we do not already hold it.
  Future<LocationPermissionOutcome> requestPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationPermissionOutcome.serviceDisabled;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationPermissionOutcome.granted;
      case LocationPermission.deniedForever:
        return LocationPermissionOutcome.deniedForever;
      case LocationPermission.denied:
        return LocationPermissionOutcome.denied;
      default:
        return LocationPermissionOutcome.denied;
    }
  }

  /// Best-effort single fix. Returns null when the OS cannot produce one.
  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Continuous fixes while a session is active.
  ///
  /// `distanceFilter: 0` means "deliver even when stationary" so a caregiver
  /// never sees a stale pin. Throttling of how often a point is written to
  /// Supabase happens in the provider, not here.
  ///
  /// NOTE: we keep this as a platform-agnostic [LocationSettings] — the
  /// interval hint is Android-only and is intentionally not set, because the
  /// provider already governs the write cadence.
  Stream<Position> positionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    );
  }
}
