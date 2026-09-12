// ==============================================================================
// NIRVANA - Active Location Sharing Screen (Patient)
// Description: Shown while the patient's location is being shared.
//
// This screen owns the foreground tracking lifetime: it starts/resumes the
// session on mount and the provider tears everything down when the screen is
// dismissed or the 30-minute window elapses.
//
// Deliberately minimal for an older user:
//   - Countdown of time remaining, so "how long?" is never a mystery.
//   - A large green confirmation that sharing is on.
//   - Exactly two actions: CALL CARETAKER and STOP SHARING.
// ==============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nirvana/app/theme/elder_theme.dart';

import '../providers/location_help_providers.dart';

class LocationSharingActiveScreen extends ConsumerStatefulWidget {
  const LocationSharingActiveScreen({super.key});

  @override
  ConsumerState<LocationSharingActiveScreen> createState() =>
      _LocationSharingActiveScreenState();
}

class _LocationSharingActiveScreenState
    extends ConsumerState<LocationSharingActiveScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Restore an in-flight session (e.g. after the app was backgrounded).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(locationHelpProvider.notifier).resumeIfActive();
    });

    // Re-render once a second so the countdown stays truthful.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _callCaregiver(String? phone) async {
    final dialer = ref.read(phoneDialerProvider);
    final ok = await dialer.dial(phone);

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No phone number saved for your caregiver. Please ask them to add one.',
            style: TextStyle(fontSize: 18),
          ),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _stopSharing() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Stop sharing?',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'Your caregiver will no longer see where you are.',
          style: TextStyle(fontSize: 18, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Keep Sharing',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
            ),
            child: const Text(
              'Yes, Stop',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await ref.read(locationHelpProvider.notifier).stopSession();
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(locationHelpProvider);
    final session = state.session;

    final remaining = session?.timeRemaining ?? Duration.zero;
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;

    final accuracy = state.currentLocation?.accuracy;
    final accuracyLabel = accuracy == null
        ? 'Finding your location…'
        : accuracy <= kGoodAccuracyMetres
        ? 'Location is accurate'
        : 'Location is approximate';

    return Scaffold(
      backgroundColor: ElderColors.backgroundClay,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---------------------------------------------------------------
              // Reassurance header
              // ---------------------------------------------------------------
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(
                    ElderTheme.cardBorderRadius,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 56,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Help is on the way',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You are sharing your location'
                      '${state.caregiverName != null && state.caregiverName!.isNotEmpty ? ' with ${state.caregiverName}' : ''}.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ---------------------------------------------------------------
              // Time remaining + accuracy
              // ---------------------------------------------------------------
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    ElderTheme.cardBorderRadius,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Sharing stops automatically in',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ElderColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$minutes min $seconds sec',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: ElderColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          accuracy == null
                              ? Icons.gps_not_fixed_rounded
                              : Icons.gps_fixed_rounded,
                          size: 18,
                          color: ElderColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          accuracyLabel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: ElderColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ---------------------------------------------------------------
              // CALL CARETAKER
              // ---------------------------------------------------------------
              SizedBox(
                height: 72,
                child: FilledButton.icon(
                  onPressed: () => _callCaregiver(state.caregiverPhone),
                  icon: const Icon(Icons.call_rounded, size: 30),
                  label: const Text(
                    'CALL CARETAKER',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: ElderColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ---------------------------------------------------------------
              // STOP SHARING
              // ---------------------------------------------------------------
              SizedBox(
                height: 72,
                child: OutlinedButton.icon(
                  onPressed: state.isStopping ? null : _stopSharing,
                  icon: const Icon(Icons.stop_circle_rounded, size: 30),
                  label: const Text(
                    'STOP SHARING',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD32F2F),
                    side: const BorderSide(
                      color: Color(0xFFD32F2F),
                      width: 2.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
