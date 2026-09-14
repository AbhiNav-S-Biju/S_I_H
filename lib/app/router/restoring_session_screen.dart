// ==============================================================================
// NIRVANA - Restoring Session Splash Screen
// Description: Lightweight startup splash shown while the persisted
// authentication/session state is being restored on cold start.
//
// This prevents the Welcome screen from flashing before the router knows
// whether the user is already authenticated (caregiver) or paired (patient).
// It deliberately mirrors the app's clay aesthetic with a simple spinner.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/clay_3d/clay_3d.dart';

class RestoringSessionScreen extends StatelessWidget {
  const RestoringSessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ClayScaffold3D(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClaySlab3D(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            borderRadius: 20,
            child: Text(
              'NIRVANA',
              style: GoogleFonts.nunito(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 3.0,
                color: Clay3DTheme.lavenderDeep,
              ),
            ),
          ),
          const SizedBox(height: 28),
          const CircularProgressIndicator(color: Clay3DTheme.lavenderDeep),
        ],
      ),
    );
  }
}
