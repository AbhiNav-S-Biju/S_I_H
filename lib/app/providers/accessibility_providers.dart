// ==============================================================================
// NIRVANA - Accessibility Providers
// Description: Riverpod state management for Reduced Motion, High Contrast,
// Font Scaling, and Locale preferences designed for elder care.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../database/hive_boxes.dart';

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

/// Languages fully supported by NIRVANA (UI + STT + TTS all verified).
/// Update this list as new languages gain full support.
const List<String> nirvanaFullySupportedLocales = [
  'en', // English — full UI, TTS (en-US), STT (en_US)
  'hi', // Hindi — full UI, TTS (hi-IN), STT (hi_IN)
  'bn', // Bengali — full UI, TTS (bn-IN, with cloud fallback), STT (bn_IN)
  'as', // Assamese — full UI, TTS (as-IN, with cloud fallback), STT (as_IN)
  'ne', // Nepali — full UI, TTS (ne-NP, with cloud fallback), STT (ne_NP)
];

/// Notifier for Active Language / Locale, with Hive-backed persistence.
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(_loadSavedLocale());

  /// Reads the saved language code from Hive. Falls back to English.
  static Locale _loadSavedLocale() {
    try {
      if (Hive.isBoxOpen(HiveBoxes.settings)) {
        final saved = Hive.box<dynamic>(HiveBoxes.settings)
            .get(HiveBoxes.settingsKeyLocale) as String?;
        if (saved != null && nirvanaFullySupportedLocales.contains(saved)) {
          return Locale(saved);
        }
      }
    } catch (_) {}
    return const Locale('en');
  }

  void setLocale(Locale locale) {
    state = locale;
    _persist(locale.languageCode);
  }

  void setLanguageCode(String code) {
    state = Locale(code);
    _persist(code);
  }

  void _persist(String code) {
    try {
      if (Hive.isBoxOpen(HiveBoxes.settings)) {
        Hive.box<dynamic>(HiveBoxes.settings)
            .put(HiveBoxes.settingsKeyLocale, code);
      }
    } catch (e) {
      debugPrint('⚠️ Could not persist locale: $e');
    }
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

/// Notifier for Voice Feedback & Spoken Guidance
class VoiceEnabledNotifier extends StateNotifier<bool> {
  VoiceEnabledNotifier() : super(true);

  void toggle() => state = !state;
  void setVoiceEnabled(bool value) => state = value;
}

final voiceEnabledProvider =
    StateNotifierProvider<VoiceEnabledNotifier, bool>((ref) {
  return VoiceEnabledNotifier();
});

