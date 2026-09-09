// ==============================================================================
// NIRVANA - Patient Welcome Screen
// Description: First-run screen shown to elderly patients on their device.
// Presented only once — after pairing, the app launches directly to Patient Home.
// Designed with maximum accessibility: large text, high contrast, minimal steps.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nirvana/app/theme/elder_theme.dart';

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
                    horizontal: 32.0,
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

                        // App Logo / Icon
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: ElderColors.primaryContainer,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: ElderColors.primary.withAlpha(40),
                                blurRadius: 30,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            size: 56,
                            color: ElderColors.primary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // App Name
                        Text(
                          'NIRVANA',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: ElderColors.primary,
                            letterSpacing: 4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),

                        // Tagline
                        Text(
                          'Your daily companion\nfor memory and wellness',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: ElderColors.textSecondary,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Setup instruction card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: ElderColors.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: ElderColors.primary.withAlpha(60),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.phone_android_rounded,
                                size: 40,
                                color: ElderColors.primary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Let\'s connect this device',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  color: ElderColors.onPrimaryContainer,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Ask your caregiver for a short code.\nYou only need to do this once.',
                                style: TextStyle(
                                  fontSize: 15,
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
                          height: 64,
                          child: ElevatedButton(
                            onPressed: () => context.go('/patient/pairing'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ElderColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 4,
                              shadowColor: ElderColors.primary.withAlpha(100),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.link_rounded, size: 28),
                                SizedBox(width: 12),
                                Text(
                                  'Connect This Device',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Small reassurance text
                        Text(
                          'Your caregiver set this up for you.',
                          style: TextStyle(
                            fontSize: 14,
                            color: ElderColors.textMuted,
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
