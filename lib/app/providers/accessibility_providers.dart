// ==============================================================================
// NIRVANA - Accessibility Providers
// Description: Riverpod state management for Reduced Motion, High Contrast,
// Font Scaling, and Locale preferences designed for elder care.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier for Reduced Motion mode (disables transitions, heavy animations)
class ReducedMotionNotifier extends StateNotifier<bool> {
  ReducedMotionNotifier() : super(false);

  void toggle() => state = !state;
  void setReducedMotion(bool value) => state = value;
}

final reducedMotionProvider =
    StateNotifierProvider<ReducedMotionNotifier, bool>((ref) {
      return ReducedMotionNotifier();
    });

/// Notifier for High Contrast visual theme
class HighContrastNotifier extends StateNotifier<bool> {
  HighContrastNotifier() : super(false);

  void toggle() => state = !state;
  void setHighContrast(bool value) => state = value;
}

final highContrastProvider = StateNotifierProvider<HighContrastNotifier, bool>((
  ref,
) {
  return HighContrastNotifier();
});

/// Scale options for typography
enum TextScaleOption {
  standard(1.0),
  extraLarge(1.15),
  maximum(1.3);

  final double scale;
  const TextScaleOption(this.scale);
}

class TextScaleNotifier extends StateNotifier<TextScaleOption> {
  TextScaleNotifier() : super(TextScaleOption.standard);

  void setScale(TextScaleOption option) => state = option;
}

final textScaleProvider =
    StateNotifierProvider<TextScaleNotifier, TextScaleOption>((ref) {
      return TextScaleNotifier();
    });

/// Notifier for Active Language / Locale
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en'));

  void setLocale(Locale locale) => state = locale;

  void setLanguageCode(String code) {
    state = Locale(code);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});
