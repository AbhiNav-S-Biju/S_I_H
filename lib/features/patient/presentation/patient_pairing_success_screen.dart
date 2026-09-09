// ==============================================================================
// NIRVANA - Patient Pairing Success Screen
// Description: Celebration screen shown immediately after successful device pairing.
// Displays the patient's name, a celebratory clay checkmark, and auto-navigates.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/app/widgets/widgets.dart';
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
    final preferredName = session?.preferredName ?? 'Friend';

    return Scaffold(
      backgroundColor: ElderColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated clay check circle
                FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        color: ElderColors.forestBg,
                        shape: BoxShape.circle,
                        boxShadow: NirvanaShadows.float(tint: ElderColors.forestDeep),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_rounded,
                          size: 72,
                          color: ElderColors.forestDeep,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // Personalised greeting
                Text(
                  'Welcome, $preferredName! 🌸',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: ElderColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                const Text(
                  'This device is now connected.\nYou are all set to begin your journey!',
                  style: TextStyle(
                    fontSize: 18,
                    color: ElderColors.textSecondary,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Progress dots / continue indicator
                const Text(
                  'Taking you to your home screen…',
                  style: TextStyle(
                    fontSize: 15,
                    color: ElderColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),

                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    valueColor: AlwaysStoppedAnimation<Color>(ElderColors.primary),
                  ),
                ),
                const SizedBox(height: 36),

                // Manual Continue CTA
                SizedBox(
                  width: 220,
                  child: LargeActionButton(
                    label: 'Continue',
                    icon: Icons.arrow_forward_rounded,
                    variant: LargeActionButtonVariant.primary,
                    onPressed: () => context.go('/patient/home'),
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

