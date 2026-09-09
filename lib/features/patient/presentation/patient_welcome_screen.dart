// ==============================================================================
// NIRVANA - Patient Welcome Screen
// Description: First-run screen shown to elderly patients on their device.
// Claymorphic wellness design with soft dual shadows, large typography,
// and accessible touch surfaces.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/app/widgets/widgets.dart';

class PatientWelcomeScreen extends StatefulWidget {
  const PatientWelcomeScreen({super.key});

  @override
  State<PatientWelcomeScreen> createState() => _PatientWelcomeScreenState();
}

class _PatientWelcomeScreenState extends State<PatientWelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ElderColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28.0,
                    vertical: 24.0,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 48.0) > 0
                          ? constraints.maxHeight - 48.0
                          : 0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),

                        // App Logo / Icon Clay Bubble
                        Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            color: ElderColors.primaryContainer,
                            shape: BoxShape.circle,
                            boxShadow: NirvanaShadows.float(tint: ElderColors.primary),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.favorite_rounded,
                              size: 56,
                              color: ElderColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // App Name
                        const Text(
                          'NIRVANA',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: ElderColors.primary,
                            letterSpacing: 3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),

                        // Tagline
                        const Text(
                          'Your daily companion\nfor memory and wellness',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: ElderColors.textSecondary,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Setup instruction clay card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: ElderColors.surface,
                            borderRadius: BorderRadius.circular(ElderTheme.cardBorderRadius),
                            boxShadow: NirvanaShadows.card(),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: ElderColors.skyBg,
                                  shape: BoxShape.circle,
                                  boxShadow: NirvanaShadows.float(tint: ElderColors.skyDeep),
                                ),
                                child: const Icon(
                                  Icons.phone_android_rounded,
                                  size: 32,
                                  color: ElderColors.skyDeep,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Let\'s connect this device',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: ElderColors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Ask your caregiver for a short 6-digit code.\nYou only need to do this once.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: ElderColors.textSecondary,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Primary CTA button
                        SizedBox(
                          width: double.infinity,
                          child: LargeActionButton(
                            label: 'Connect This Device',
                            icon: Icons.link_rounded,
                            variant: LargeActionButtonVariant.primary,
                            onPressed: () => context.go('/patient/pairing'),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Small reassurance text
                        const Text(
                          'Your caregiver set this up for you.',
                          style: TextStyle(
                            fontSize: 14,
                            color: ElderColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

