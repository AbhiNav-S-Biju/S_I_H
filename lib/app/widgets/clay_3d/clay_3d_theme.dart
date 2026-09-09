// ==============================================================================
// NIRVANA - 3D Claymorphic Design Theme Tokens
// ==============================================================================

import 'package:flutter/material.dart';

class Clay3DTheme {
  Clay3DTheme._();

  // Canvas & Surfaces
  static const Color canvas = Color(0xFFF3ECE2);
  static const Color cardSurface = Color(0xFFF7F1E8);

  // Typography
  static const Color textDark = Color(0xFF2C2723);
  static const Color textMuted = Color(0xFF6B645D);
  static const Color textLight = Color(0xFFFAF7F2);
  static const Color textLightSub = Color(0xFFEBE6F7);

  // Palette Accents
  static const Color lavender = Color(0xFFA797D6);
  static const Color lavenderDeep = Color(0xFF9483C6);
  static const Color lavenderLight = Color(0xFFC7BAEE);
  static const Color teal = Color(0xFF5CB3B3);
  static const Color tealLight = Color(0xFF68C2BE);
  static const Color coral = Color(0xFFE58878);
  static const Color coralLight = Color(0xFFF19E8E);
  static const Color olive = Color(0xFFC7B174);
  static const Color gold = Color(0xFFE1B752);
  static const Color starYellow = Color(0xFFFFD447);

  // Dual-Layer Clay Shadows
  static List<BoxShadow> cardShadow({double blur = 18, double offset = 8}) => [
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

  static List<BoxShadow> deepShadow({double blur = 20, double offset = 10}) => [
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

  static List<BoxShadow> buttonShadow({Color? tint}) => [
        BoxShadow(
          color: (tint ?? const Color(0xFF382A1E)).withValues(alpha: 0.22),
          offset: const Offset(4, 5),
          blurRadius: 10,
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.50),
          offset: const Offset(-3, -3),
          blurRadius: 6,
        ),
      ];
}
