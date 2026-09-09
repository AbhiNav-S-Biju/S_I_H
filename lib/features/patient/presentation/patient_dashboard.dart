// ==============================================================================
// NIRVANA - Patient Dashboard Screen (Ultra-Fidelity 3D Claymorphism)
// Description: Accessible, soothing, tactile 3D clay wellness dashboard for elderly patients.
// Implements volumetric 3D clay lighting, puffy clouds, organic pebbles, wave landscape,
// gold ribbon, and physical 3D embossed iconography matching design reference.
// ==============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nirvana/features/patient/providers/patient_pairing_providers.dart';

// ==============================================================================
// Design Tokens & Color Palette
// ==============================================================================
class _DashboardPalette {
  _DashboardPalette._();

  // Canvas
  static const Color canvas = Color(0xFFF3ECE2);
  static const Color cardSurface = Color(0xFFF7F1E8);

  // Typography
  static const Color textDark = Color(0xFF2C2723);
  static const Color textLight = Color(0xFFFAF7F2);

  // Feature Colors
  static const Color bannerLavender = Color(0xFFA797D6);
  static const Color bannerInset = Color(0xFF9483C6);
  static const Color starYellow = Color(0xFFFFD447);

  // 3D Card Tokens
  static const Color tokenLavender = Color(0xFFA292D4);
  static const Color tokenTeal = Color(0xFF5CB3B3);
  static const Color tokenCoral = Color(0xFFE58878);
  static const Color tokenOlive = Color(0xFFC7B174);

  // Pebble Colors
  static const Color pebbleTeal = Color(0xFF68C2BE);
  static const Color pebbleCoral = Color(0xFFF19E8E);

  // Dual-Layer Clay Shadows
  static List<BoxShadow> clayCardShadow({double blur = 18, double offset = 8}) => [
        BoxShadow(
          color: const Color(0xFF4A3B2C).withValues(alpha: 0.12),
          offset: Offset(offset, offset),
          blurRadius: blur,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.95),
          offset: Offset(-offset, -offset),
          blurRadius: blur,
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> clayDeepShadow({double blur = 20, double offset = 10}) => [
        BoxShadow(
          color: const Color(0xFF382A1E).withValues(alpha: 0.15),
          offset: Offset(offset, offset + 2),
          blurRadius: blur,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.90),
          offset: Offset(-offset, -offset),
          blurRadius: blur,
          spreadRadius: 0,
        ),
      ];
}

// ==============================================================================
// Main Screen: PatientDashboard
// ==============================================================================
class PatientDashboard extends ConsumerWidget {
  const PatientDashboard({super.key});

  String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(localPatientSessionProvider);
    final patientName = session?.preferredName.isNotEmpty == true
        ? session!.preferredName
        : 'dundu';
    final greeting = _timeGreeting();

    return Scaffold(
      backgroundColor: _DashboardPalette.canvas,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // --------------------------------------------------------------------
          // 3D Ambient Decorative Layer (Non-interactive floating shapes)
          // --------------------------------------------------------------------
          const _FloatingAmbient3DLayer(),

          // --------------------------------------------------------------------
          // Scrollable Main Content
          // --------------------------------------------------------------------
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 18.0,
                vertical: 18.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header (Greeting Slab + 3D Heart)
                  _DashboardHeader(
                    greeting: greeting,
                    patientName: patientName,
                  ),
                  const SizedBox(height: 22.0),

                  // 2. Daily Moment 3D Banner with overlapping puffy cloud
                  const _DailyMomentBanner3D(),
                  const SizedBox(height: 28.0),

                  // 3. Section Title inside raised clay slab
                  const _SectionTitleSlab(
                    title: 'What would you like to do?',
                  ),
                  const SizedBox(height: 18.0),

                  // 4. Action Grid
                  _buildActionGrid(context),

                  const SizedBox(height: 48.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 16.0;
        final cardWidth = (constraints.maxWidth - spacing) / 2.0;

        final items = [
          _ActionCardItem(
            tokenType: ClayTokenType.puzzle,
            tokenColor: _DashboardPalette.tokenLavender,
            tag: null,
            title: 'Memory Games',
            onTap: () => context.push('/patient/games'),
          ),
          _ActionCardItem(
            tokenType: ClayTokenType.clock,
            tokenColor: _DashboardPalette.tokenTeal,
            tag: 'ROUTINES',
            title: 'My Reminders',
            onTap: () => context.push('/patient/reminders'),
          ),
          _ActionCardItem(
            tokenType: ClayTokenType.photoFrame,
            tokenColor: _DashboardPalette.tokenCoral,
            tag: 'MEMORIES',
            title: 'Family Photos',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: _DashboardPalette.textDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  content: Text(
                    'Family Photos feature coming soon!',
                    style: GoogleFonts.nunito(
                      color: _DashboardPalette.textLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            },
          ),
          _ActionCardItem(
            tokenType: ClayTokenType.gear,
            tokenColor: _DashboardPalette.tokenOlive,
            tag: 'PREFERENCES',
            title: 'Settings',
            onTap: () => context.push('/patient/settings'),
          ),
          _ActionCardItem(
            tokenType: ClayTokenType.chatBubble,
            tokenColor: _DashboardPalette.tokenLavender,
            tag: null,
            title: 'Ask NIRVANA',
            onTap: () => context.push('/ask-nirvana'),
          ),
        ];

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((item) {
            return SizedBox(
              width: cardWidth,
              height: 184.0,
              child: ClayActionCard(
                tokenType: item.tokenType,
                tokenColor: item.tokenColor,
                tag: item.tag,
                title: item.title,
                onTap: item.onTap,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ==============================================================================
// Action Card Data Model
// ==============================================================================
enum ClayTokenType { puzzle, clock, photoFrame, gear, chatBubble }

class _ActionCardItem {
  final ClayTokenType tokenType;
  final Color tokenColor;
  final String? tag;
  final String title;
  final VoidCallback onTap;

  const _ActionCardItem({
    required this.tokenType,
    required this.tokenColor,
    this.tag,
    required this.title,
    required this.onTap,
  });
}

// ==============================================================================
// Header Component: Raised Slab + 3D Volumetric Heart
// ==============================================================================
class _DashboardHeader extends StatelessWidget {
  final String greeting;
  final String patientName;

  const _DashboardHeader({
    required this.greeting,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Raised Clay Header Slab
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18.0,
              vertical: 12.0,
            ),
            decoration: BoxDecoration(
              color: _DashboardPalette.cardSurface,
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: _DashboardPalette.clayCardShadow(blur: 14, offset: 6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  greeting,
                  style: GoogleFonts.nunito(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                    color: _DashboardPalette.textDark,
                  ),
                ),
                Text(
                  patientName,
                  style: GoogleFonts.nunito(
                    fontSize: 28.0,
                    fontWeight: FontWeight.w900,
                    color: _DashboardPalette.textDark,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16.0),

        // 3D Volumetric Clay Heart
        const SizedBox(
          width: 58.0,
          height: 58.0,
          child: CustomPaint(
            painter: _ClayHeart3DPainter(color: _DashboardPalette.bannerLavender),
          ),
        ),
      ],
    );
  }
}

// ==============================================================================
// Daily Moment 3D Banner
// ==============================================================================
class _DailyMomentBanner3D extends StatelessWidget {
  const _DailyMomentBanner3D();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main Clay Banner Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22.0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFB5A6E2),
                Color(0xFFA291D4),
                Color(0xFF9683CB),
              ],
            ),
            borderRadius: BorderRadius.circular(28.0),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3C2F52).withValues(alpha: 0.22),
                offset: const Offset(10, 10),
                blurRadius: 22,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.65),
                offset: const Offset(-6, -6),
                blurRadius: 14,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Embossed/Inset Pill "DAILY MOMENT"
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14.0,
                        vertical: 5.0,
                      ),
                      decoration: BoxDecoration(
                        color: _DashboardPalette.bannerInset.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.20),
                            offset: const Offset(2, 2),
                            blurRadius: 3,
                            spreadRadius: -1,
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.35),
                            offset: const Offset(-1.5, -1.5),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Text(
                        'DAILY MOMENT',
                        style: GoogleFonts.nunito(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: _DashboardPalette.textLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12.0),

                    // Headline + 3D Glowing Star
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'You are doing wonderfully!',
                            style: GoogleFonts.nunito(
                              fontSize: 18.5,
                              fontWeight: FontWeight.w900,
                              color: _DashboardPalette.textDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4.0),
                        const SizedBox(
                          width: 26.0,
                          height: 26.0,
                          child: CustomPaint(
                            painter: _ClayStar3DPainter(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),

                    // Subtitle
                    Text(
                      'Keep up your daily activities. Every little step brings peace and joy.',
                      style: GoogleFonts.nunito(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: _DashboardPalette.textDark.withValues(alpha: 0.85),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14.0),

              // 3D Circular Action Button with recessed icon
              const SizedBox(
                width: 54.0,
                height: 54.0,
                child: CustomPaint(
                  painter: _ClayButton3DPainter(
                    color: Color(0xFFB0A0E0),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Puffy 3D Cloud overlapping top-right of the banner
        const Positioned(
          top: -24.0,
          right: -16.0,
          child: SizedBox(
            width: 95.0,
            height: 55.0,
            child: CustomPaint(
              painter: _ClayCloud3DPainter(
                color: Color(0xFFCFC4F2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ==============================================================================
// Section Title Slab
// ==============================================================================
class _SectionTitleSlab extends StatelessWidget {
  final String title;

  const _SectionTitleSlab({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 10.0,
      ),
      decoration: BoxDecoration(
        color: _DashboardPalette.cardSurface,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: _DashboardPalette.clayCardShadow(blur: 10, offset: 4),
      ),
      child: Text(
        title,
        style: GoogleFonts.nunito(
          fontSize: 19.0,
          fontWeight: FontWeight.w900,
          color: _DashboardPalette.textDark,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

// ==============================================================================
// Reusable 3D ClayActionCard
// ==============================================================================
class ClayActionCard extends StatelessWidget {
  final ClayTokenType tokenType;
  final Color tokenColor;
  final String? tag;
  final String title;
  final VoidCallback onTap;

  const ClayActionCard({
    super.key,
    required this.tokenType,
    required this.tokenColor,
    this.tag,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: _DashboardPalette.cardSurface,
          borderRadius: BorderRadius.circular(26.0),
          boxShadow: _DashboardPalette.clayDeepShadow(blur: 18, offset: 8),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 14.0,
          vertical: 14.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: 3D Clay Icon Badge + 3D Clay Chevron
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 3D Clay Token
                SizedBox(
                  width: 52.0,
                  height: 52.0,
                  child: CustomPaint(
                    painter: _ClayToken3DPainter(
                      color: tokenColor,
                      tokenType: tokenType,
                    ),
                  ),
                ),

                // 3D Chevron Arrow
                CustomPaint(
                  size: const Size(12, 16),
                  painter: _ClayChevron3DPainter(color: tokenColor),
                ),
              ],
            ),

            // Bottom Row: Tag Pill + Bold Title
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tag != null && tag!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9.0,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: tokenColor.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          offset: const Offset(2, 2),
                          blurRadius: 4,
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.40),
                          offset: const Offset(-1.5, -1.5),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: Text(
                      tag!,
                      style: GoogleFonts.nunito(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: _DashboardPalette.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6.0),
                ] else ...[
                  // Smooth 3D Clay pill bar placeholder
                  Container(
                    width: 60.0,
                    height: 14.0,
                    decoration: BoxDecoration(
                      color: tokenColor.withValues(alpha: 0.80),
                      borderRadius: BorderRadius.circular(10.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          offset: const Offset(2, 2),
                          blurRadius: 3,
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.45),
                          offset: const Offset(-1.5, -1.5),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6.0),
                ],
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: _DashboardPalette.textDark,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// 3D Ambient Decorative Layer
// Renders the puffy clouds, organic pebbles, wave landscape, and gold ribbon
// ==============================================================================
class _FloatingAmbient3DLayer extends StatelessWidget {
  const _FloatingAmbient3DLayer();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Left Puffy Cloud under the banner edge
          const Positioned(
            top: 260.0,
            left: -32.0,
            child: SizedBox(
              width: 80.0,
              height: 48.0,
              child: CustomPaint(
                painter: _ClayCloud3DPainter(
                  color: Color(0xFFC7BAEE),
                ),
              ),
            ),
          ),

          // 2. Middle-Right Teal Clay Kidney/Pebble
          const Positioned(
            top: 285.0,
            right: -15.0,
            child: SizedBox(
              width: 50.0,
              height: 38.0,
              child: CustomPaint(
                painter: _ClayPebble3DPainter(
                  color: _DashboardPalette.pebbleTeal,
                  tilt: 0.4,
                ),
              ),
            ),
          ),

          // 3. Middle-Right Coral Clay Pebble
          const Positioned(
            top: 335.0,
            right: 22.0,
            child: SizedBox(
              width: 28.0,
              height: 28.0,
              child: CustomPaint(
                painter: _ClaySphere3DPainter(
                  color: _DashboardPalette.pebbleCoral,
                ),
              ),
            ),
          ),

          // 4. Middle-Right Small Teal Drop Pebble
          const Positioned(
            top: 365.0,
            right: -8.0,
            child: SizedBox(
              width: 32.0,
              height: 24.0,
              child: CustomPaint(
                painter: _ClayPebble3DPainter(
                  color: _DashboardPalette.pebbleTeal,
                  tilt: -0.2,
                ),
              ),
            ),
          ),

          // 5. Lower-Left Coral/Peach Organic Blob
          const Positioned(
            top: 670.0,
            left: -20.0,
            child: SizedBox(
              width: 48.0,
              height: 70.0,
              child: CustomPaint(
                painter: _ClayPebble3DPainter(
                  color: _DashboardPalette.pebbleCoral,
                  tilt: 0.1,
                ),
              ),
            ),
          ),

          // 6. Bottom-Right 3D Wave Landscape + Glossy Gold Ribbon & Pebbles
          const Positioned(
            bottom: -20.0,
            right: -20.0,
            child: SizedBox(
              width: 220.0,
              height: 220.0,
              child: CustomPaint(
                painter: _ClayWaveLandscape3DPainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// CUSTOM 3D PAINTERS (Volumetric Shading, Highlights, Drop Shadows)
// ==============================================================================

/// Paints a volumetric 3D clay heart with directional specular highlights
class _ClayHeart3DPainter extends CustomPainter {
  final Color color;

  const _ClayHeart3DPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Drop Shadow
    final shadowPath = Path();
    shadowPath.moveTo(w * 0.5, h * 0.85);
    shadowPath.cubicTo(w * 0.15, h * 0.55, w * 0.05, h * 0.25, w * 0.28, h * 0.15);
    shadowPath.cubicTo(w * 0.40, h * 0.10, w * 0.48, h * 0.25, w * 0.5, h * 0.35);
    shadowPath.cubicTo(w * 0.52, h * 0.25, w * 0.60, h * 0.10, w * 0.72, h * 0.15);
    shadowPath.cubicTo(w * 0.95, h * 0.25, w * 0.85, h * 0.55, w * 0.5, h * 0.85);

    canvas.drawPath(
      shadowPath.shift(const Offset(5, 7)),
      Paint()
        ..color = const Color(0xFF382A1E).withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Main Heart Body with 3D Radial Gradient
    final heartPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.45),
        radius: 0.95,
        colors: [
          Colors.white.withValues(alpha: 0.95),
          color.withValues(alpha: 0.95),
          Color.lerp(color, const Color(0xFF6B58A0), 0.55)!,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(shadowPath, heartPaint);

    // Specular Rim Highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawPath(shadowPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _ClayHeart3DPainter oldDelegate) => false;
}

/// Paints a 3D puffy clay cloud cluster
class _ClayCloud3DPainter extends CustomPainter {
  final Color color;

  const _ClayCloud3DPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final spheres = [
      _CloudSphere(center: Offset(w * 0.32, h * 0.60), radius: h * 0.38),
      _CloudSphere(center: Offset(w * 0.52, h * 0.42), radius: h * 0.44),
      _CloudSphere(center: Offset(w * 0.72, h * 0.55), radius: h * 0.36),
      _CloudSphere(center: Offset(w * 0.88, h * 0.65), radius: h * 0.26),
    ];

    // Ambient drop shadow for the whole cloud
    for (final s in spheres) {
      canvas.drawCircle(
        s.center + const Offset(4, 6),
        s.radius + 2,
        Paint()
          ..color = const Color(0xFF382A1E).withValues(alpha: 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // Draw clay spheres with radial 3D lighting
    for (final s in spheres) {
      final rect = Rect.fromCircle(center: s.center, radius: s.radius);
      final paint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.45),
          radius: 0.9,
          colors: [
            Colors.white.withValues(alpha: 0.90),
            color,
            Color.lerp(color, const Color(0xFF6B5A96), 0.40)!,
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(rect);

      canvas.drawCircle(s.center, s.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ClayCloud3DPainter oldDelegate) => false;
}

class _CloudSphere {
  final Offset center;
  final double radius;
  const _CloudSphere({required this.center, required this.radius});
}

/// Paints a glossy 3D clay sphere
class _ClaySphere3DPainter extends CustomPainter {
  final Color color;

  const _ClaySphere3DPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Drop shadow
    canvas.drawCircle(
      center + const Offset(3, 4),
      radius,
      Paint()
        ..color = const Color(0xFF382A1E).withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // 3D Sphere gradient
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.4, -0.45),
        radius: 0.85,
        colors: [
          Colors.white.withValues(alpha: 0.95),
          color,
          Color.lerp(color, Colors.black, 0.35)!,
        ],
        stops: const [0.0, 0.40, 1.0],
      ).createShader(rect);

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _ClaySphere3DPainter oldDelegate) => false;
}

/// Paints an organic oval 3D clay pebble
class _ClayPebble3DPainter extends CustomPainter {
  final Color color;
  final double tilt;

  const _ClayPebble3DPainter({required this.color, this.tilt = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(tilt);
    canvas.translate(-size.width / 2, -size.height / 2);

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(size.height * 0.5));

    // Shadow
    canvas.drawRRect(
      rrect.shift(const Offset(4, 5)),
      Paint()
        ..color = const Color(0xFF382A1E).withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // 3D Clay Body
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.40),
        radius: 0.95,
        colors: [
          Colors.white.withValues(alpha: 0.92),
          color,
          Color.lerp(color, Colors.black, 0.32)!,
        ],
        stops: const [0.0, 0.42, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ClayPebble3DPainter oldDelegate) => false;
}

/// Paints a 3D glowing star
class _ClayStar3DPainter extends CustomPainter {
  const _ClayStar3DPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // Glow
    canvas.drawCircle(
      center,
      w * 0.65,
      Paint()
        ..color = _DashboardPalette.starYellow.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Star path
    final path = Path();
    const points = 5;
    final outerRadius = w * 0.45;
    final innerRadius = w * 0.20;

    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = (i * math.pi / points) - (math.pi / 2);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [
          Colors.white,
          _DashboardPalette.starYellow,
          const Color(0xFFE5A510),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ClayStar3DPainter oldDelegate) => false;
}

/// Paints the 3D Banner button with debossed plant/leaf
class _ClayButton3DPainter extends CustomPainter {
  final Color color;

  const _ClayButton3DPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Drop shadow
    canvas.drawCircle(
      center + const Offset(4, 5),
      radius,
      Paint()
        ..color = const Color(0xFF382A1E).withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );

    // Raised 3D Circle
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.40),
        radius: 0.85,
        colors: [
          Colors.white.withValues(alpha: 0.95),
          color,
          Color.lerp(color, const Color(0xFF5D4A8C), 0.45)!,
        ],
        stops: const [0.0, 0.40, 1.0],
      ).createShader(rect);

    canvas.drawCircle(center, radius, paint);

    // Debossed Plant/Download Icon
    final iconPaint = Paint()
      ..color = const Color(0xFF7662A6).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    // Arrow down
    path.moveTo(center.dx, center.dy - 9);
    path.lineTo(center.dx, center.dy + 4);
    path.moveTo(center.dx - 6, center.dy - 1);
    path.lineTo(center.dx, center.dy + 5);
    path.lineTo(center.dx + 6, center.dy - 1);
    // Cradle
    path.moveTo(center.dx - 9, center.dy + 3);
    path.quadraticBezierTo(center.dx - 9, center.dy + 10, center.dx, center.dy + 10);
    path.quadraticBezierTo(center.dx + 9, center.dy + 10, center.dx + 9, center.dy + 3);

    canvas.drawPath(path, iconPaint);
  }

  @override
  bool shouldRepaint(covariant _ClayButton3DPainter oldDelegate) => false;
}

/// Paints the 3D clay chevron arrow
class _ClayChevron3DPainter extends CustomPainter {
  final Color color;

  const _ClayChevron3DPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(2, 2);
    path.lineTo(size.width - 2, size.height / 2);
    path.lineTo(2, size.height - 2);

    // Shadow
    canvas.drawPath(
      path.shift(const Offset(1.5, 1.5)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );

    // Highlight
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.90)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ClayChevron3DPainter oldDelegate) => false;
}

/// Paints the 3D Action Card Icon Badge with volumetric icon inside
class _ClayToken3DPainter extends CustomPainter {
  final Color color;
  final ClayTokenType tokenType;

  const _ClayToken3DPainter({
    required this.color,
    required this.tokenType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer Dual Clay Shadow
    canvas.drawCircle(
      center + const Offset(3.5, 4.5),
      radius,
      Paint()
        ..color = const Color(0xFF382A1E).withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // 3D Circular Token Surface
    final rect = Rect.fromCircle(center: center, radius: radius);
    final tokenPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.40),
        radius: 0.85,
        colors: [
          Colors.white.withValues(alpha: 0.90),
          color,
          Color.lerp(color, Colors.black, 0.30)!,
        ],
        stops: const [0.0, 0.40, 1.0],
      ).createShader(rect);

    canvas.drawCircle(center, radius, tokenPaint);

    // Render 3D Embossed Physical Icon
    _draw3DIcon(canvas, center, size.width * 0.52);
  }

  void _draw3DIcon(Canvas canvas, Offset center, double iconSize) {
    switch (tokenType) {
      case ClayTokenType.puzzle:
        _drawPuzzlePiece(canvas, center, iconSize);
        break;
      case ClayTokenType.clock:
        _drawClock(canvas, center, iconSize);
        break;
      case ClayTokenType.photoFrame:
        _drawPhotoFrame(canvas, center, iconSize);
        break;
      case ClayTokenType.gear:
        _drawGear(canvas, center, iconSize);
        break;
      case ClayTokenType.chatBubble:
        _drawChatBubble(canvas, center, iconSize);
        break;
    }
  }

  void _drawPuzzlePiece(Canvas canvas, Offset center, double size) {
    final s = size * 0.5;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: s * 1.8, height: s * 1.8),
      const Radius.circular(5),
    );

    // Inset depth
    canvas.drawRRect(
      rrect.shift(const Offset(1.5, 1.5)),
      Paint()
        ..color = const Color(0xFF48386D).withValues(alpha: 0.40)
        ..style = PaintingStyle.fill,
    );

    // Raised piece
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFFC3B6E8)
        ..style = PaintingStyle.fill,
    );

    // Puzzle tabs
    canvas.drawCircle(
      Offset(center.dx, center.dy - s * 0.9),
      s * 0.35,
      Paint()..color = const Color(0xFFC3B6E8),
    );
    canvas.drawCircle(
      Offset(center.dx + s * 0.9, center.dy),
      s * 0.35,
      Paint()..color = const Color(0xFFC3B6E8),
    );
    // Puzzle hole
    canvas.drawCircle(
      Offset(center.dx, center.dy + s * 0.9),
      s * 0.30,
      Paint()..color = color,
    );
  }

  void _drawClock(Canvas canvas, Offset center, double size) {
    final r = size * 0.55;

    // Clock Rim
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = const Color(0xFF388686).withValues(alpha: 0.50)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );

    // Clock Hands
    final handPaint = Paint()
      ..color = const Color(0xFF235B5B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, Offset(center.dx, center.dy - r * 0.65), handPaint);
    canvas.drawLine(center, Offset(center.dx + r * 0.50, center.dy), handPaint);
    canvas.drawCircle(center, 2.5, Paint()..color = const Color(0xFF235B5B));
  }

  void _drawPhotoFrame(Canvas canvas, Offset center, double size) {
    final s = size * 0.55;
    final frameRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: s * 1.8, height: s * 1.8),
      const Radius.circular(5),
    );

    // Frame Shadow
    canvas.drawRRect(
      frameRect.shift(const Offset(1.5, 1.5)),
      Paint()..color = const Color(0xFF8B473A).withValues(alpha: 0.35),
    );
    // Frame Body
    canvas.drawRRect(
      frameRect,
      Paint()..color = const Color(0xFFF7B5A8),
    );

    // Inner Silhouette
    canvas.drawCircle(
      Offset(center.dx, center.dy - s * 0.25),
      s * 0.30,
      Paint()..color = const Color(0xFFC5604E),
    );
    final bodyPath = Path();
    bodyPath.moveTo(center.dx - s * 0.55, center.dy + s * 0.65);
    bodyPath.quadraticBezierTo(
      center.dx,
      center.dy + s * 0.15,
      center.dx + s * 0.55,
      center.dy + s * 0.65,
    );
    canvas.drawPath(bodyPath, Paint()..color = const Color(0xFFC5604E));
  }

  void _drawGear(Canvas canvas, Offset center, double size) {
    final r = size * 0.52;
    const teeth = 6;

    for (int i = 0; i < teeth; i++) {
      final angle = (i * 2 * math.pi) / teeth;
      final toothCenter = Offset(
        center.dx + r * 0.75 * math.cos(angle),
        center.dy + r * 0.75 * math.sin(angle),
      );
      canvas.drawCircle(toothCenter, r * 0.30, Paint()..color = const Color(0xFF8C7738));
    }

    canvas.drawCircle(center, r * 0.70, Paint()..color = const Color(0xFFE8D596));
    canvas.drawCircle(center, r * 0.32, Paint()..color = color);
  }

  void _drawChatBubble(Canvas canvas, Offset center, double size) {
    final s = size * 0.55;
    final bubbleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center - const Offset(0, 2), width: s * 1.8, height: s * 1.4),
      const Radius.circular(8),
    );

    // Bubble Shadow
    canvas.drawRRect(
      bubbleRect.shift(const Offset(1.5, 1.5)),
      Paint()..color = const Color(0xFF4B3C73).withValues(alpha: 0.35),
    );

    // Bubble Body
    canvas.drawRRect(
      bubbleRect,
      Paint()..color = const Color(0xFFC9BCEE),
    );

    // Bubble Tail
    final tailPath = Path();
    tailPath.moveTo(center.dx - s * 0.4, center.dy + s * 0.4);
    tailPath.lineTo(center.dx - s * 0.8, center.dy + s * 0.85);
    tailPath.lineTo(center.dx - s * 0.1, center.dy + s * 0.55);
    tailPath.close();

    canvas.drawPath(tailPath, Paint()..color = const Color(0xFFC9BCEE));
  }

  @override
  bool shouldRepaint(covariant _ClayToken3DPainter oldDelegate) => false;
}

/// Paints the bottom-right 3D wave landscape with metallic gold ribbon and sparkle
class _ClayWaveLandscape3DPainter extends CustomPainter {
  const _ClayWaveLandscape3DPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Lilac Clay Wave Body
    final wavePath = Path();
    wavePath.moveTo(w * 0.20, h);
    wavePath.cubicTo(w * 0.20, h * 0.65, w * 0.50, h * 0.60, w * 0.65, h * 0.45);
    wavePath.cubicTo(w * 0.80, h * 0.30, w * 0.90, h * 0.40, w, h * 0.30);
    wavePath.lineTo(w, h);
    wavePath.close();

    // Wave Drop Shadow
    canvas.drawPath(
      wavePath.shift(const Offset(4, 6)),
      Paint()
        ..color = const Color(0xFF382A1E).withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Wave 3D Shader
    final wavePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFD6C8F5),
          Color(0xFFBAA7EC),
          Color(0xFF9E89D7),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(wavePath, wavePaint);

    // 2. Shiny 4-Point Sparkle on the Wave
    _drawSparkle(canvas, Offset(w * 0.72, h * 0.60), 14.0);

    // 3. 3D Glossy Gold Ribbon Tube
    final ribbonPath = Path();
    ribbonPath.moveTo(w * 0.35, h);
    ribbonPath.cubicTo(w * 0.40, h * 0.80, w * 0.60, h * 0.85, w * 0.75, h * 0.72);
    ribbonPath.cubicTo(w * 0.90, h * 0.60, w * 0.95, h * 0.80, w, h * 0.75);

    // Ribbon Shadow
    canvas.drawPath(
      ribbonPath.shift(const Offset(3, 4)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Ribbon Gold Gradient Body
    final ribbonPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFF2A8),
          Color(0xFFE4BC50),
          Color(0xFFB88C22),
          Color(0xFFFFF2A8),
        ],
        stops: [0.0, 0.4, 0.8, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(ribbonPath, ribbonPaint);

    // 4. Floating Gold Egg & Pebbles near bottom-right
    // Gold Egg
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.55, h * 0.50), width: 22, height: 18),
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.40),
          colors: [Colors.white, Color(0xFFE5C067), Color(0xFF9E7B24)],
        ).createShader(Rect.fromLTWH(w * 0.45, h * 0.40, 22, 18)),
    );

    // Coral Pebble
    canvas.drawCircle(
      Offset(w * 0.28, h * 0.52),
      12.0,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.40),
          colors: [Colors.white, Color(0xFFF19E8E), Color(0xFFC55A48)],
        ).createShader(Rect.fromLTWH(w * 0.20, h * 0.45, 24, 24)),
    );

    // Turquoise Pebble
    canvas.drawCircle(
      Offset(w * 0.15, h * 0.65),
      8.0,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.40),
          colors: [Colors.white, Color(0xFF68C2BE), Color(0xFF287975)],
        ).createShader(Rect.fromLTWH(w * 0.10, h * 0.60, 16, 16)),
    );
  }

  void _drawSparkle(Canvas canvas, Offset center, double size) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - size);
    path.close();

    canvas.drawPath(
      path,
      Paint()..color = Colors.white.withValues(alpha: 0.90),
    );
  }

  @override
  bool shouldRepaint(covariant _ClayWaveLandscape3DPainter oldDelegate) => false;
}
