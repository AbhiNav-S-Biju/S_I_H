// ==============================================================================
// NIRVANA - Patient Welcome Screen (3D Claymorphism)
// Description: Tactile, warm first-run welcome screen for elderly patients on their device.
// Features volumetric 3D clay heart, floating clouds & pebbles, and deep clay card shadows.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/widgets/clay_3d/clay_3d.dart';

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
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
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
    return ClayScaffold3D(
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // 3D Volumetric Clay Heart
              const SizedBox(
                width: 96,
                height: 96,
                child: CustomPaint(
                  painter: ClayHeart3DPainter(color: Clay3DTheme.lavender),
                ),
              ),

              const SizedBox(height: 20),

              // App Name Slab
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

              const SizedBox(height: 10),

              // Tagline
              Text(
                'Your daily companion\nfor memory and wellness',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Clay3DTheme.textDark,
                  height: 1.35,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 28),

              // Setup instruction 3D clay card
              ClayCard3D(
                padding: const EdgeInsets.all(24),
                borderRadius: 26,
                customShadows: Clay3DTheme.deepShadow(blur: 18, offset: 8),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Clay3DTheme.tealLight,
                        shape: BoxShape.circle,
                        boxShadow: Clay3DTheme.cardShadow(blur: 10, offset: 4),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.phone_android_rounded,
                          size: 32,
                          color: Color(0xFF1F5C5C),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Let\'s connect this device',
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Clay3DTheme.textDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ask your caregiver for a short 6-digit code.\nYou only need to do this once.',
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        color: Clay3DTheme.textMuted,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Primary CTA button
              SizedBox(
                width: double.infinity,
                child: ClayButton3D(
                  label: 'Connect This Device',
                  icon: Icons.link_rounded,
                  color: Clay3DTheme.lavender,
                  minHeight: 56,
                  onPressed: () => context.go('/patient/pairing'),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Your caregiver set this up for you.',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: Clay3DTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
