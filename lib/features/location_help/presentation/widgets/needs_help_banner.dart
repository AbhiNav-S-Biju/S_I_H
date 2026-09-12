// ==============================================================================
// NIRVANA - Caregiver "Patient Needs Help" Banner
// Description: Prominent alert card shown on the caregiver dashboard while a
// patient is asking for help. Tapping it opens the live map.
//
// Access control: the underlying session only exists for the caregiver if RLS
// permitted the read, so this widget never has to decide who is authorized.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../caregiver/providers/caregiver_providers.dart';
import '../../providers/location_help_providers.dart';
import '../caregiver_patient_location_screen.dart';

class NeedsHelpBanner extends ConsumerWidget {
  const NeedsHelpBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needsHelp = ref.watch(patientNeedsHelpProvider);
    if (!needsHelp) return const SizedBox.shrink();

    final patient = ref.watch(selectedPatientProvider);
    final name = patient?.preferredName ?? 'Your patient';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const CaregiverPatientLocationScreen(),
            ),
          ),
          child: Ink(
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD32F2F).withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PATIENT NEEDS HELP',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$name asked for help. Tap to see their live location.',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
