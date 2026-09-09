// ==============================================================================
// NIRVANA - Patient Pairing Success Screen
// Description: Celebration screen shown immediately after successful device pairing.
// Displays the patient's name, a success animation, and auto-navigates to Patient Home.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/features/patient/providers/patient_pairing_providers.dart';

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
    final preferredName = session?.preferredName ?? 'there';

    return Scaffold(
      backgroundColor: ElderColors.successBg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated check circle
                FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        color: ElderColors.successText.withAlpha(25),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ElderColors.successBorder,
                          width: 4,
                        ),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 72,
                        color: ElderColors.successText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Personalised greeting
                Text(
                  'Welcome, $preferredName!',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: ElderColors.successText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                Text(
                  'This device is now connected.\nYou\'re all set!',
                  style: TextStyle(
                    fontSize: 20,
                    color: ElderColors.successText.withAlpha(200),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 56),

                // Progress dots / continue indicator
                Text(
                  'Taking you to your home screen…',
                  style: TextStyle(
                    fontSize: 16,
                    color: ElderColors.successText.withAlpha(160),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: ElderColors.successText,
                  ),
                ),
                const SizedBox(height: 40),

                // Manual "Continue" button in case auto-nav is slow
                TextButton(
                  onPressed: () => context.go('/patient/home'),
                  child: Text(
                    'Continue →',
                    style: TextStyle(
                      fontSize: 18,
                      color: ElderColors.successText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
