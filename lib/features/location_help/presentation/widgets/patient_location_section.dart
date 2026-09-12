// ==============================================================================
// NIRVANA - Patient Location Section (Caregiver Dashboard)
// Description: Compact "live location" card for the caregiver home page.
//
// Shows the most recent fix, how fresh it is, its accuracy, and shortcuts to
// open the full map or stop sharing. Renders nothing at all when the patient is
// not sharing, so the dashboard stays uncluttered.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nirvana/app/theme/elder_theme.dart';

import '../../providers/location_help_providers.dart';
import '../caregiver_patient_location_screen.dart';

class PatientLocationSection extends ConsumerWidget {
  const PatientLocationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(activeLocationHelpSessionProvider).value;
    if (session == null) return const SizedBox.shrink();

    final location = ref.watch(currentPatientLocationProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFD32F2F).withValues(alpha: 0.35),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.my_location_rounded,
                  color: Color(0xFFD32F2F),
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Live Location Sharing',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: ElderColors.textPrimary,
                    ),
                  ),
                ),
                _FreshnessDot(recordedAt: location?.recordedAt),
              ],
            ),
            const SizedBox(height: 12),

            // ---------------------------------------------------------------
            // Coordinates + accuracy
            // ---------------------------------------------------------------
            if (location == null)
              const Text(
                'Waiting for the first location update…',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ElderColors.textSecondary,
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatTime(location.recordedAt),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: ElderColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location.accuracy == null
                        ? 'Accuracy unknown'
                        : 'Accuracy ±${location.accuracy!.round()} m',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ElderColors.textSecondary,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 14),

            // ---------------------------------------------------------------
            // Open the map
            // ---------------------------------------------------------------
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CaregiverPatientLocationScreen(),
                  ),
                ),
                icon: const Icon(Icons.map_rounded, size: 20),
                label: const Text(
                  'VIEW LIVE MAP',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime recordedAt) {
    final local = recordedAt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final s = local.second.toString().padLeft(2, '0');
    return 'Last updated at $h:$m:$s';
  }
}

/// Green when the feed is fresh, amber when it has gone quiet.
class _FreshnessDot extends StatelessWidget {
  final DateTime? recordedAt;

  const _FreshnessDot({required this.recordedAt});

  @override
  Widget build(BuildContext context) {
    final seconds = recordedAt == null
        ? null
        : DateTime.now().toUtc().difference(recordedAt!.toUtc()).inSeconds;

    final isStale = seconds == null || seconds > 45;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isStale ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isStale ? 'STALE' : 'LIVE',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: isStale ? const Color(0xFF92400E) : const Color(0xFF166534),
        ),
      ),
    );
  }
}
