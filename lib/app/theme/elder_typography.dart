// ==============================================================================
// NIRVANA - Elder Typography System
// Description: Accessible typography scale with min 22sp body text, generous
// line heights, and high-legibility weights for senior users.
// ==============================================================================

import 'package:flutter/material.dart';

class ElderTypography {
  ElderTypography._();

  /// Creates a senior-focused text theme scaled by [fontScaleFactor].
  static TextTheme createTextTheme({
    required Color textColor,
    required Color mutedTextColor,
    double fontScaleFactor = 1.0,
  }) {
    double scale(double base) => (base * fontScaleFactor).roundToDouble();

    return TextTheme(
      // Large headers (e.g. Welcome title, main celebration)
      displaySmall: TextStyle(
        fontSize: scale(32.0),
        fontWeight: FontWeight.w800,
        height: 1.3,
        letterSpacing: -0.5,
        color: textColor,
      ),
      // Section and screen headers
      headlineLarge: TextStyle(
        fontSize: scale(28.0),
        fontWeight: FontWeight.w800,
        height: 1.3,
        letterSpacing: -0.3,
        color: textColor,
      ),
      headlineMedium: TextStyle(
        fontSize: scale(25.0),
        fontWeight: FontWeight.w700,
        height: 1.35,
        color: textColor,
      ),
      // Card titles & Primary dialog titles
      titleLarge: TextStyle(
        fontSize: scale(23.0),
        fontWeight: FontWeight.w700,
        height: 1.35,
        color: textColor,
      ),
      titleMedium: TextStyle(
        fontSize: scale(21.0),
        fontWeight: FontWeight.w700,
        height: 1.4,
        color: textColor,
      ),
      // Standard body text (minimum ~22sp per requirements)
      bodyLarge: TextStyle(
        fontSize: scale(22.0),
        fontWeight: FontWeight.w500,
        height: 1.45,
        color: textColor,
      ),
      // Subtitle / explanatory text
      bodyMedium: TextStyle(
        fontSize: scale(20.0),
        fontWeight: FontWeight.w500,
        height: 1.45,
        color: mutedTextColor,
      ),
      bodySmall: TextStyle(
        fontSize: scale(18.0),
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: mutedTextColor,
      ),
      // Action buttons & prominent labels
      labelLarge: TextStyle(
        fontSize: scale(22.0),
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
        height: 1.2,
        color: textColor,
      ),
      labelMedium: TextStyle(
        fontSize: scale(19.0),
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: textColor,
      ),
    );
  }
}
