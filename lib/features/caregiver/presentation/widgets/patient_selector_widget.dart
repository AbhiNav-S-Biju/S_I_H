// ==============================================================================
// NIRVANA - Patient Selector Widget
// Description: Dropdown/Selector allowing a caregiver to switch between assigned
// loved ones/patients. Scoped strictly to authorized accounts.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No assigned loved ones found for this account.',
                style: TextStyle(fontSize: 16),
              ),
            ),
          );
        }

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
                        value: selectedPatient ?? patients.first,
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
