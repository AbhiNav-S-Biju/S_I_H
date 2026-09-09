// ==============================================================================
// NIRVANA — Claymorphic Wellness Design System
// Palette derived from warm-peach wellness reference (Bloomly-style).
// Every color, radius and shadow lives here. Screen files must NOT contain
// inline Color(0xFF...) literals — use these tokens only.
// ==============================================================================

import 'package:flutter/material.dart';
import 'elder_typography.dart';

// ==============================================================================
// NIRVANA RADII — all corner-radius decisions centralised
// ==============================================================================
class NirvanaRadii {
  NirvanaRadii._();

  /// Cards, large containers
  static const double card = 24.0;
  /// Buttons
  static const double button = 20.0;
  /// Small icon containers, input fields
  static const double icon = 16.0;
  /// Chips / status pills — always full-pill
  static const double pill = 999.0;
  /// Sheet / bottom drawer header
  static const double sheet = 28.0;
}

// ==============================================================================
// NIRVANA SHADOWS — single-layer warm shadow for claymorphism
// "Shadow-first" cards: the shadow defines the edge, not a border stroke.
// ==============================================================================
class NirvanaShadows {
  NirvanaShadows._();

  /// Standard card shadow — warm brown tint, soft
  static List<BoxShadow> card({Color? tint}) => [
        BoxShadow(
          color: (tint ?? const Color(0xFF3A2F2A)).withValues(alpha: 0.10),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: (tint ?? const Color(0xFF3A2F2A)).withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
          spreadRadius: 0,
        ),
      ];

  /// Button press shadow — coloured glow
  static List<BoxShadow> button({required Color color}) => [
        BoxShadow(
          color: color.withValues(alpha: 0.30),
          blurRadius: 16,
          offset: const Offset(0, 6),
          spreadRadius: 0,
        ),
      ];

  /// Floating FAB / icon-circle shadow
  static List<BoxShadow> float({Color? tint}) => [
        BoxShadow(
          color: (tint ?? const Color(0xFF3A2F2A)).withValues(alpha: 0.14),
          blurRadius: 16,
          offset: const Offset(0, 6),
          spreadRadius: 0,
        ),
      ];

  /// Input field subtle lift
  static const List<BoxShadow> input = [
        BoxShadow(
          color: Color(0x0D3A2F2A),
          blurRadius: 8,
          offset: Offset(0, 3),
          spreadRadius: 0,
        ),
      ];
}

// ==============================================================================
// ELDER COLORS — warm-peach claymorphism palette
// Derived from reference image: peachy background, muted lavender primary,
// dusty sage, muted amber, warm blush coral.
// ==============================================================================
class ElderColors {
  ElderColors._();

  // ---------------------------------------------------------------------------
  // Primary — muted lavender (not saturated violet)
  // ---------------------------------------------------------------------------
  static const Color primary = Color(0xFF9B8EC4);
  static const Color primaryDark = Color(0xFF7A6BA8);
  static const Color primaryLight = Color(0xFFBFB5DC);
  static const Color onPrimary = Colors.white;
  static const Color primaryContainer = Color(0xFFF0EDFB);
  static const Color onPrimaryContainer = Color(0xFF4A3F7A);

  // High-contrast variant (settings / HC theme)
  static const Color highContrastPrimary = Color(0xFF4A3F7A);

  // ---------------------------------------------------------------------------
  // Backgrounds & Surfaces — warm peach family
  // ---------------------------------------------------------------------------
  /// Main scaffold background — warm peachy sand
  static const Color background = Color(0xFFF5EDE0);
  static const Color backgroundClay = Color(0xFFF5EDE0);
  /// Slightly deeper alt background for sections
  static const Color backgroundAlt = Color(0xFFEDE3D4);
  /// Card / surface — near-white with warm undertone
  static const Color surface = Color(0xFFFDFAF6);
  /// Slightly elevated surface (modals, sheets)
  static const Color surfaceElevated = Color(0xFFFAF5EE);

  // ---------------------------------------------------------------------------
  // Typography — warm brown family (never pure black / cool grey)
  // ---------------------------------------------------------------------------
  static const Color textPrimary = Color(0xFF3A2F2A);   // warm dark brown
  static const Color textSecondary = Color(0xFF8C7F76); // muted taupe
  static const Color textMuted = Color(0xFFADA098);     // light taupe

  // ---------------------------------------------------------------------------
  // Borders & Dividers — warm, very subtle
  // ---------------------------------------------------------------------------
  static const Color border = Color(0xFFE8DCCF);
  static const Color borderLight = Color(0xFFF0E8DC);
  static const Color borderHighContrast = Color(0xFF3A2F2A);

  // ---------------------------------------------------------------------------
  // Accent 1 — Muted Lavender (Cognitive / AI companion)
  // ---------------------------------------------------------------------------
  static const Color clayLavender = Color(0xFF9B8EC4);
  static const Color lavenderDeep = Color(0xFF6B5EA8);
  static const Color pastelLavenderBg = Color(0xFFF0EDFB);
  static const Color pastelLavenderBorder = Color(0xFFD5CEF0);
  static const Color pastelLavender = Color(0xFF9B8EC4);

  // ---------------------------------------------------------------------------
  // Accent 2 — Muted Amber / Mustard (Reminders, Schedules)
  // ---------------------------------------------------------------------------
  static const Color clayButtercup = Color(0xFFC8A96E);
  static const Color amberDeep = Color(0xFF8B6E3C);
  static const Color amberBg = Color(0xFFFBF3E2);
  static const Color amberBorder = Color(0xFFEDD89A);
  static const Color pastelButtercupBg = Color(0xFFFBF3E2);
  static const Color pastelButtercupBorder = Color(0xFFEDD89A);
  static const Color pastelButtercup = Color(0xFFC8A96E);

  // ---------------------------------------------------------------------------
  // Accent 3 — Dusty Sage Green (Health, Success, Done)
  // ---------------------------------------------------------------------------
  static const Color claySage = Color(0xFF7BA89A);
  static const Color forestDeep = Color(0xFF3D6B5E);
  static const Color forestBg = Color(0xFFEBF5F2);
  static const Color forestBorder = Color(0xFFB5D8D0);
  static const Color pastelSageBg = Color(0xFFEBF5F2);
  static const Color pastelSageBorder = Color(0xFFB5D8D0);
  static const Color pastelSage = Color(0xFF7BA89A);

  // ---------------------------------------------------------------------------
  // Accent 4 — Warm Blush / Dusty Coral (Family, Alerts, Notices)
  // ---------------------------------------------------------------------------
  static const Color clayPeach = Color(0xFFD4897A);
  static const Color peachDeep = Color(0xFFA85A4A);
  static const Color coralDeep = Color(0xFFA85A4A);
  static const Color coralBg = Color(0xFFFBEFEC);
  static const Color coralBorder = Color(0xFFEDC4BC);
  static const Color pastelPeachBg = Color(0xFFFBEFEC);
  static const Color pastelPeachBorder = Color(0xFFEDC4BC);
  static const Color pastelPeach = Color(0xFFD4897A);

  // ---------------------------------------------------------------------------
  // Accent 5 — Dusty Sky / Teal (Info, Sync, Devices)
  // ---------------------------------------------------------------------------
  static const Color claySky = Color(0xFF6BAAB8);
  static const Color skyDeep = Color(0xFF3D7A8A);
  static const Color skyBg = Color(0xFFEBF5F8);
  static const Color skyBorder = Color(0xFFB2D8E2);
  static const Color pastelSkyBg = Color(0xFFEBF5F8);
  static const Color pastelSkyBorder = Color(0xFFB2D8E2);
  static const Color pastelSky = Color(0xFF6BAAB8);

  // ---------------------------------------------------------------------------
  // Feedback — Supportive & Error tones (warm, never harsh red)
  // ---------------------------------------------------------------------------
  static const Color supportiveBg = Color(0xFFFBF3E2);
  static const Color supportiveBorder = Color(0xFFEDD89A);
  static const Color supportiveText = Color(0xFF8B6E3C);
  static const Color supportiveIcon = Color(0xFFC8A96E);

  static const Color gentleErrorBg = Color(0xFFFBEFEC);
  static const Color gentleErrorBorder = Color(0xFFEDC4BC);
  static const Color gentleErrorText = Color(0xFF8B3A2A);
  static const Color gentleErrorPrimary = Color(0xFFD4897A);

  static const Color successBg = Color(0xFFEBF5F2);
  static const Color successBorder = Color(0xFFB5D8D0);
  static const Color successText = Color(0xFF3D6B5E);

  // ---------------------------------------------------------------------------
  // Shadow helpers — kept for backward-compat; internally delegate to NirvanaShadows
  // ---------------------------------------------------------------------------

  /// Soft claymorphic card shadow — warm brown tint.
  /// Replaces the old dual (top highlight + bottom depth) model
  /// with a single-layer shadow that defines the card edge.
  static List<BoxShadow> clayShadow({
    Color? color,
    double opacity = 0.10,
    double blur = 20.0,
    Offset offset = const Offset(0, 8),
  }) {
    final tint = color ?? textPrimary;
    return [
      BoxShadow(
        color: tint.withValues(alpha: opacity),
        blurRadius: blur,
        offset: offset,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: tint.withValues(alpha: opacity * 0.4),
        blurRadius: blur * 0.3,
        offset: offset * 0.25,
        spreadRadius: 0,
      ),
    ];
  }

  /// Coloured button elevation glow.
  static List<BoxShadow> buttonShadow({Color? color}) {
    return NirvanaShadows.button(color: color ?? primary);
  }
}

// ==============================================================================
// ELDER THEME — ThemeData factory
// ==============================================================================
class ElderTheme {
  ElderTheme._();

  /// Touch Target Dimensions
  static const double minTouchTargetSize = 64.0;
  static const double buttonHeight = 64.0;
  static const double cardBorderRadius = NirvanaRadii.card;
  static const double buttonBorderRadius = NirvanaRadii.button;
  static const double pillBorderRadius = NirvanaRadii.pill;

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
        secondary: ElderColors.claySage,
        onSecondary: Colors.white,
        secondaryContainer: ElderColors.forestBg,
        onSecondaryContainer: ElderColors.forestDeep,
        surface: ElderColors.surface,
        onSurface: ElderColors.textPrimary,
        error: ElderColors.gentleErrorPrimary,
        onError: Colors.white,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: ElderColors.surface,
        elevation: 0.0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NirvanaRadii.card),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ElderColors.primary,
          foregroundColor: ElderColors.onPrimary,
          elevation: 0.0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(64.0, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NirvanaRadii.button),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            color: ElderColors.onPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ElderColors.textPrimary,
          backgroundColor: ElderColors.surface,
          elevation: 0.0,
          minimumSize: const Size(64.0, buttonHeight),
          side: const BorderSide(color: ElderColors.border, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NirvanaRadii.button),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      iconTheme: const IconThemeData(
        size: 30.0,
        color: ElderColors.textPrimary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ElderColors.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NirvanaRadii.card),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: ElderColors.background,
        foregroundColor: ElderColors.textPrimary,
        elevation: 0.0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineMedium?.copyWith(
          color: ElderColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ElderColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NirvanaRadii.icon),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NirvanaRadii.icon),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NirvanaRadii.icon),
          borderSide: const BorderSide(color: ElderColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        labelStyle: const TextStyle(color: ElderColors.textSecondary),
      ),
    );
  }

  static ThemeData buildHighContrastTheme({double fontScaleFactor = 1.0}) {
    final textTheme = ElderTypography.createTextTheme(
      textColor: const Color(0xFF1A1010),
      mutedTextColor: const Color(0xFF3A2F2A),
      fontScaleFactor: fontScaleFactor,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: ElderColors.highContrastPrimary,
      scaffoldBackgroundColor: const Color(0xFFF0E8D8),
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: ElderColors.highContrastPrimary,
        onPrimary: Colors.white,
        secondary: ElderColors.forestDeep,
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: Color(0xFF1A1010),
        error: Color(0xFF8B3A2A),
        onError: Colors.white,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NirvanaRadii.card),
          side: const BorderSide(color: ElderColors.borderHighContrast, width: 2.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ElderColors.highContrastPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size(64.0, buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NirvanaRadii.button),
          ),
          side: const BorderSide(color: ElderColors.borderHighContrast, width: 2.0),
        ),
      ),
    );
  }
}
