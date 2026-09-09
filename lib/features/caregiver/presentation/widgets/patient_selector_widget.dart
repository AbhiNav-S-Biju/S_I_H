// ==============================================================================
// NIRVANA - Patient Selector Widget
// Description: Dropdown/Selector allowing a caregiver to switch between assigned
// loved ones/patients. Scoped strictly to authorized accounts.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/app/widgets/widgets.dart';
import 'package:nirvana/features/caregiver/models/caregiver_models.dart';
import 'package:nirvana/features/caregiver/providers/caregiver_providers.dart';

class PatientSelectorWidget extends ConsumerWidget {
  const PatientSelectorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(assignedPatientsProvider);
    final selectedPatient = ref.watch(selectedPatientProvider);

    return patientsAsync.when(
      data: (patients) {
        if (patients.isEmpty) {
          return ElderCard(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ElderColors.clayLavender.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 36,
                    color: ElderColors.clayLavender,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No loved ones linked yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: ElderColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Add a care recipient to start monitoring activity and pairing devices.',
                  style: TextStyle(
                    fontSize: 14,
                    color: ElderColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                LargeActionButton(
                  label: 'Add Loved One',
                  icon: Icons.add_rounded,
                  colorScheme: ElderButtonScheme.primary,
                  onPressed: () => context.push('/caregiver/onboarding'),
                ),
              ],
            ),
          );
        }

        final effectiveSelected =
            (selectedPatient != null &&
                patients.any((p) => p.id == selectedPatient.id))
            ? patients.firstWhere((p) => p.id == selectedPatient.id)
            : patients.first;

        return ElderCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ElderColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: ElderColors.clayLavender,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Viewing Activity For',
                      style: TextStyle(
                        fontSize: 12,
                        color: ElderColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<PatientSummary>(
                        key: const Key('patient_selector_dropdown'),
                        value: effectiveSelected,
                        isDense: true,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.arrow_drop_down_rounded,
                          color: ElderColors.clayLavender,
                          size: 28,
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: ElderColors.textPrimary,
                        ),
                        items: patients.map((patient) {
                          return DropdownMenuItem<PatientSummary>(
                            value: patient,
                            child: Text(
                              '${patient.fullName} (${patient.relationship})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (newPatient) {
                          if (newPatient != null) {
                            ref.read(selectedPatientProvider.notifier).state =
                                newPatient;
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('patient_selector_add_button'),
                icon: const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: ElderColors.clayLavender,
                ),
                tooltip: 'Add Loved One',
                onPressed: () => context.push('/caregiver/onboarding'),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: CircularProgressIndicator(color: ElderColors.clayLavender),
        ),
      ),
      error: (e, _) => Text(
        'Unable to load assigned patients: $e',
        style: const TextStyle(color: ElderColors.gentleErrorText),
      ),
    );
  }
}
