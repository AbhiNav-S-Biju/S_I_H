// ==============================================================================
// NIRVANA - Elder Theme System
// Description: Calming, high-contrast, large touch-target theme tailored
// specifically for seniors with cognitive/memory support needs.
// ==============================================================================

import 'package:flutter/material.dart';
import 'elder_typography.dart';

/// Semantic colors designed for elderly care: high contrast, zero glare,
/// and soft supportive non-alarming status tones.
class ElderColors {
  ElderColors._();

  // Primary Calming Palette (Deep Teal)
  static const Color primary = Color(0xFF0F766E);
  static const Color onPrimary = Colors.white;
  static const Color primaryContainer = Color(0xFFCCFBF1);
  static const Color onPrimaryContainer = Color(0xFF115E59);

  // High Contrast Primary
  static const Color highContrastPrimary = Color(0xFF044E47);

  // Background & Surfaces (Warm anti-glare tones)
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF1F5F9);

  // Typography & Text
  static const Color textPrimary = Color(0xFF0F172A); // 15:1 contrast
  static const Color textSecondary = Color(0xFF334155); // 9:1 contrast
  static const Color textMuted = Color(0xFF475569);

  // Tactile Borders & Dividers
  static const Color border = Color(0xFFCBD5E1);
  static const Color borderHighContrast = Color(0xFF0F172A);

  // Supportive, Non-Alarming Feedback Colors
  // Gentle warm amber/honey for reassurance/prompts instead of jarring alerts
  static const Color supportiveBg = Color(0xFFFEF3C7);
  static const Color supportiveBorder = Color(0xFFFCD34D);
  static const Color supportiveText = Color(0xFF92400E);
  static const Color supportiveIcon = Color(0xFFB45309);

  // Gentle Soft Terracotta for errors/pauses (supportive, not scary/red-heavy)
  static const Color gentleErrorBg = Color(0xFFFFEDD5);
  static const Color gentleErrorBorder = Color(0xFFFDBA74);
  static const Color gentleErrorText = Color(0xFF9A3412);
  static const Color gentleErrorPrimary = Color(0xFFC2410C);

  // Gentle Meadow for Success & Accomplishments
  static const Color successBg = Color(0xFFDCFCE7);
  static const Color successBorder = Color(0xFF86EFAC);
  static const Color successText = Color(0xFF166534);
}

class ElderTheme {
  ElderTheme._();

  /// Touch Target Dimensions
  static const double minTouchTargetSize = 64.0;
  static const double buttonHeight = 64.0;
  static const double cardBorderRadius = 18.0;
  static const double buttonBorderRadius = 16.0;

  /// Builds the standard elder-friendly theme.
  static ThemeData buildStandardTheme({double fontScaleFactor = 1.0}) {
    final textTheme = ElderTypography.createTextTheme(
      textColor: ElderColors.textPrimary,
      mutedTextColor: ElderColors.textSecondary,
      fontScaleFactor: fontScaleFactor,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: ElderColors.primary,
      scaffoldBackgroundColor: ElderColors.background,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: ElderColors.primary,
        onPrimary: ElderColors.onPrimary,
        primaryContainer: ElderColors.primaryContainer,
        onPrimaryContainer: ElderColors.onPrimaryContainer,
        secondary: Color(0xFF0369A1),
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFE0F2FE),
        onSecondaryContainer: Color(0xFF075985),
        surface: ElderColors.surface,
        onSurface: ElderColors.textPrimary,
        error: ElderColors.gentleErrorPrimary,
        onError: Colors.white,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: ElderColors.surface,
        elevation: 0.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardBorderRadius),
          side: const BorderSide(color: ElderColors.border, width: 2.0),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ElderColors.primary,
          foregroundColor: ElderColors.onPrimary,
          elevation: 0.0,
          minimumSize: const Size(64.0, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonBorderRadius),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            color: ElderColors.onPrimary,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ElderColors.textPrimary,
          backgroundColor: ElderColors.surface,
          elevation: 0.0,
          minimumSize: const Size(64.0, buttonHeight),
          side: const BorderSide(color: ElderColors.border, width: 2.5),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonBorderRadius),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconTheme: const IconThemeData(
        size: 32.0,
        color: ElderColors.textPrimary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ElderColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardBorderRadius),
          side: const BorderSide(color: ElderColors.border, width: 2.0),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: ElderColors.surface,
        foregroundColor: ElderColors.textPrimary,
        elevation: 0.0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineMedium,
        shape: const Border(
          bottom: BorderSide(color: ElderColors.border, width: 2.0),
        ),
      ),
    );
  }

  /// Builds a High Contrast theme with maximum visual clarity and bold borders.
  static ThemeData buildHighContrastTheme({double fontScaleFactor = 1.0}) {
    final textTheme = ElderTypography.createTextTheme(
      textColor: const Color(0xFF000000),
      mutedTextColor: const Color(0xFF1E293B),
      fontScaleFactor: fontScaleFactor,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: ElderColors.highContrastPrimary,
      scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: ElderColors.highContrastPrimary,
        onPrimary: Colors.white,
        secondary: Color(0xFF0C4A6E),
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: Color(0xFF000000),
        error: Color(0xFF9A3412),
        onError: Colors.white,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardBorderRadius),
          side: const BorderSide(
            color: ElderColors.borderHighContrast,
            width: 3.0,
          ),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ElderColors.highContrastPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size(64.0, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonBorderRadius),
            side: const BorderSide(color: Colors.black, width: 2.0),
          ),
          textStyle: textTheme.labelLarge?.copyWith(color: Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
          minimumSize: const Size(64.0, buttonHeight),
          side: const BorderSide(color: Colors.black, width: 3.0),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonBorderRadius),
          ),
          textStyle: textTheme.labelLarge?.copyWith(color: Colors.black),
        ),
      ),
      iconTheme: const IconThemeData(size: 34.0, color: Colors.black),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.0,
        titleTextStyle: textTheme.headlineMedium?.copyWith(
          color: Colors.black,
          fontWeight: FontWeight.w900,
        ),
        shape: const Border(
          bottom: BorderSide(color: Colors.black, width: 3.0),
        ),
      ),
    );
  }
}
