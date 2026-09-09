// ==============================================================================
// NIRVANA - Patient Selector Widget
// Description: Dropdown/Selector allowing a caregiver to switch between assigned
// loved ones/patients. Scoped strictly to authorized accounts.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
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
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ElderColors.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.person_add_alt_1,
                  size: 40,
                  color: ElderColors.primary,
                ),
                const SizedBox(height: 8),
                const Text(
                  'No loved ones linked yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ElderColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add a care recipient to start monitoring activity.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ElderColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  onPressed: () => context.push('/caregiver/onboarding'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    'Add Loved One',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }

        final effectiveSelected = (selectedPatient != null &&
                patients.any((p) => p.id == selectedPatient.id))
            ? patients.firstWhere((p) => p.id == selectedPatient.id)
            : patients.first;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ElderColors.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: ElderColors.primary.withValues(alpha: 0.15),
                child: const Icon(
                  Icons.person,
                  color: ElderColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Viewing Activity For',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<PatientSummary>(
                        key: const Key('patient_selector_dropdown'),
                        value: effectiveSelected,
                        isDense: true,
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: ElderColors.primary,
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ElderColors.textPrimary,
                        ),
                        items: patients.map((patient) {
                          return DropdownMenuItem<PatientSummary>(
                            value: patient,
                            child: Text(
                              '${patient.fullName} (${patient.relationship})',
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
                icon: const Icon(Icons.person_add_alt, color: ElderColors.primary),
                tooltip: 'Add Loved One',
                onPressed: () => context.push('/caregiver/onboarding'),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Text(
        'Unable to load assigned patients: $e',
        style: const TextStyle(color: Colors.red),
      ),
    );
  }
}
