// ==============================================================================
// NIRVANA - Caregiver Live Patient Location Screen
// Description: "Patient Needs Help" view showing the patient's latest location
// on a map, updated live via Supabase Realtime.
//
// Privacy / access control:
//   - Every read goes through the caregiver's authenticated Supabase session.
//   - RLS on location_sessions / patient_locations means a caregiver only ever
//     receives rows for THEIR patient. No location data is public.
//   - The map is rendered from OpenStreetMap tiles (no API key, no data sharing
//     with a maps vendor beyond tile requests).
//
// Updates arrive through the realtime stream on patient_locations; this screen
// deliberately does not poll.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:nirvana/app/theme/elder_theme.dart';

import '../../caregiver/providers/caregiver_providers.dart';
import '../models/location_help_models.dart';
import '../providers/location_help_providers.dart';

class CaregiverPatientLocationScreen extends ConsumerStatefulWidget {
  const CaregiverPatientLocationScreen({super.key});

  @override
  ConsumerState<CaregiverPatientLocationScreen> createState() =>
      _CaregiverPatientLocationScreenState();
}

class _CaregiverPatientLocationScreenState
    extends ConsumerState<CaregiverPatientLocationScreen> {
  final MapController _mapController = MapController();

  /// Remember the last point we centred on, so we do not fight the caregiver
  /// if they pan the map manually.
  LatLng? _lastCentred;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _recenterIfMoved(PatientLocation location) {
    final target = LatLng(location.latitude, location.longitude);
    if (_lastCentred != null &&
        _lastCentred!.latitude == target.latitude &&
        _lastCentred!.longitude == target.longitude) {
      return;
    }
    _lastCentred = target;

    // Defer until the map has been laid out at least once.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _mapController.move(target, _mapController.camera.zoom);
      } catch (_) {
        // Map not ready yet; the initial center below will handle it.
      }
    });
  }

  Future<void> _callPatient() async {
    final phone = ref.read(patientPhoneProvider);
    final dialer = ref.read(phoneDialerProvider);
    final ok = await dialer.dial(phone);

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No phone number saved for this patient. Add one in their profile.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }
  }

  Future<void> _stopSharing() async {
    final session = ref.read(activeLocationHelpSessionProvider).value;
    if (session == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stop location sharing?'),
        content: const Text(
          'The patient will stop sharing their location and the live map will close.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
            ),
            child: const Text('Stop Sharing'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref
        .read(caregiverLocationHelpNotifierProvider.notifier)
        .stopSession(session.id);

    if (mounted) {
      ref.invalidate(activeLocationHelpSessionProvider);
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(activeLocationHelpSessionProvider);
    final session = sessionAsync.value;
    final location = ref.watch(currentPatientLocationProvider);
    final patient = ref.watch(selectedPatientProvider);
    final patientName = patient?.preferredName ?? 'Patient';

    if (location != null) _recenterIfMoved(location);

    return Scaffold(
      backgroundColor: ElderColors.backgroundClay,
      appBar: AppBar(
        backgroundColor: ElderColors.backgroundClay,
        elevation: 0,
        title: Text(
          '$patientName — Live Location',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: ElderColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // -----------------------------------------------------------------
            // Status strip: freshness + accuracy
            // -----------------------------------------------------------------
            _StatusStrip(location: location, session: session),

            // -----------------------------------------------------------------
            // Map
            // -----------------------------------------------------------------
            Expanded(
              child: session == null
                  ? const _NoActiveSharing()
                  : location == null
                  ? const _WaitingForFirstFix()
                  : _PatientMap(
                      controller: _mapController,
                      location: location,
                      patientName: patientName,
                    ),
            ),

            // -----------------------------------------------------------------
            // Actions
            // -----------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: FilledButton.icon(
                        onPressed: _callPatient,
                        icon: const Icon(Icons.call_rounded),
                        label: const Text(
                          'CALL PATIENT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: ElderColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: OutlinedButton.icon(
                        onPressed: session == null ? null : _stopSharing,
                        icon: const Icon(Icons.stop_circle_rounded),
                        label: const Text(
                          'STOP SHARING',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFD32F2F),
                          side: const BorderSide(
                            color: Color(0xFFD32F2F),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ==============================================================================
// Supporting widgets
// ==============================================================================

/// Freshness + accuracy summary. Answers "is this current?" at a glance.
class _StatusStrip extends StatelessWidget {
  final PatientLocation? location;
  final LocationSession? session;

  const _StatusStrip({required this.location, required this.session});

  String _relativeTime(DateTime? recordedAt) {
    if (recordedAt == null) return 'Waiting for the first location…';

    final seconds = DateTime.now()
        .toUtc()
        .difference(recordedAt.toUtc())
        .inSeconds;
    if (seconds < 15) return 'Updated just now';
    if (seconds < 60) return 'Updated ${seconds}s ago';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return 'Updated $minutes min ago';
    return 'Updated ${minutes ~/ 60} h ago';
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = location?.accuracy;
    final seconds = location?.recordedAt == null
        ? null
        : DateTime.now()
              .toUtc()
              .difference(location!.recordedAt.toUtc())
              .inSeconds;

    // Stale once we have not heard from the device for a while.
    final isStale = seconds != null && seconds > 45;

    final accuracyText = accuracy == null
        ? 'Accuracy unknown'
        : 'Accuracy ±${accuracy.round()} m';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isStale
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF22C55E),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _relativeTime(location?.recordedAt),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: ElderColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  accuracyText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ElderColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (session != null)
            Text(
              session!.isActive ? 'SHARING ACTIVE' : 'SHARING ENDED',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: session!.isActive
                    ? const Color(0xFF22C55E)
                    : ElderColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

class _PatientMap extends StatelessWidget {
  final MapController controller;
  final PatientLocation location;
  final String patientName;

  const _PatientMap({
    required this.controller,
    required this.location,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    final point = LatLng(location.latitude, location.longitude);

    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: point,
        initialZoom: 16,
        // The pin is the only interaction point that matters; keep it simple.
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.nirvana.app',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: point,
              width: 64,
              height: 64,
              child: Semantics(
                label: '$patientName is here',
                child: const Icon(
                  Icons.location_on_rounded,
                  size: 52,
                  color: Color(0xFFD32F2F),
                ),
              ),
            ),
            // Approximate accuracy circle, so the caregiver knows how precise
            // the fix really is rather than trusting a bare pin.
            if (location.accuracy != null && location.accuracy! > 0)
              Marker(
                point: point,
                width: 1,
                height: 1,
                child: Container(
                  width: location.accuracy! * 2,
                  height: location.accuracy! * 2,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD32F2F).withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const RichAttributionWidget(
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),
      ],
    );
  }
}

class _WaitingForFirstFix extends StatelessWidget {
  const _WaitingForFirstFix();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Waiting for the patient\'s location…',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ElderColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoActiveSharing extends StatelessWidget {
  const _NoActiveSharing();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shield_moon_rounded,
              size: 56,
              color: ElderColors.textSecondary,
            ),
            SizedBox(height: 14),
            Text(
              'No active sharing',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: ElderColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This patient is not sharing their location right now. '
              'Location is only visible while they ask for help.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: ElderColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
