// ==============================================================================
// NIRVANA - Patient Pairing Success Screen (3D Claymorphism)
// Description: Celebratory 3D claymorphic success screen with volumetric checkmark,
// glowing stars, floating ambient pebbles, and smooth auto-navigation.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/widgets/clay_3d/clay_3d.dart';
import '../../../features/patient/providers/patient_pairing_providers.dart';

class PatientPairingSuccessScreen extends ConsumerStatefulWidget {
  const PatientPairingSuccessScreen({super.key});

  @override
  ConsumerState<PatientPairingSuccessScreen> createState() =>
      _PatientPairingSuccessScreenState();
}

class _PatientPairingSuccessScreenState
    extends ConsumerState<PatientPairingSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );
    _animController.forward();

    // Auto-navigate to patient home after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        context.go('/patient/home');
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(localPatientSessionProvider);
    final preferredName = session?.preferredName.isNotEmpty == true
        ? session!.preferredName
        : 'dundu';

    return ClayScaffold3D(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Animated 3D check circle badge
            FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Clay3DTheme.tealLight,
                    shape: BoxShape.circle,
                    boxShadow: Clay3DTheme.deepShadow(blur: 20, offset: 8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_rounded,
                      size: 64,
                      color: Color(0xFF1F5C5C),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Personalized greeting
            Text(
              'Welcome, $preferredName! 🌸',
              style: GoogleFonts.nunito(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Clay3DTheme.textDark,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            Text(
              'This device is now connected.\nYou are all set to begin your journey!',
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: Clay3DTheme.textMuted,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 36),

            // Indicator
            Text(
              'Taking you to your home screen…',
              style: GoogleFonts.nunito(
                fontSize: 14.5,
                color: Clay3DTheme.textMuted,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3.0,
                valueColor: AlwaysStoppedAnimation<Color>(Clay3DTheme.lavender),
              ),
            ),

            const SizedBox(height: 32),

            // Continue CTA — clamped so it never exceeds narrow screens.
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 200.0, maxWidth: 320.0),
              child: ClayButton3D(
                label: 'Continue',
                icon: Icons.arrow_forward_rounded,
                color: Clay3DTheme.lavender,
                minHeight: 52,
                onPressed: () => context.go('/patient/home'),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
