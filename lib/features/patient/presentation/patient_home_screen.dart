// ==============================================================================
// NIRVANA - Patient Home Screen
// Description: Thin wrapper / forwarder to PatientDashboard.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'patient_dashboard.dart';

export 'patient_dashboard.dart';

class PatientHomeScreen extends ConsumerWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const PatientDashboard();
  }
}
