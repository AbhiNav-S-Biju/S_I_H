// ==============================================================================
// NIRVANA - Voice Helper
// Description: Utility class for voice-assisted interaction, providing
// easy-to-use methods for TTS, STT, and audio feedback.
// Designed for elderly-friendly interfaces with clear visual feedback.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/accessibility_providers.dart';
import '../network/audio_service.dart';

/// VoiceHelper - Simple utility interface for voice features
class VoiceHelper {
  final Ref _ref;
  final IAudioService _audioService;

  VoiceHelper(this._ref, this._audioService);

  /// Speak text with current app language
  Future<void> speak(String text) async {
    final voiceEnabled = _ref.read(voiceEnabledProvider);
    if (!voiceEnabled) return;

    final locale = _ref.read(localeProvider);
    await _audioService.speak(text, languageCode: locale.languageCode);
  }

  /// Listen for speech and return recognized text
  Future<String?> listen({int? timeoutSeconds}) async {
    final locale = _ref.read(localeProvider);
    return await _audioService.listenForSpeech(
      languageCode: locale.languageCode,
      timeoutSeconds: timeoutSeconds,
    );
  }

  /// Stop current listening
  Future<void> stopListening() => _audioService.stopListening();

  /// Check if currently speaking
  Future<bool> isSpeaking() => _audioService.isSpeaking();

  /// Stop current speech
  Future<void> stopSpeaking() => _audioService.stopSpeaking();

  /// Play audio feedback (chimes, confirm, error)
  Future<void> playFeedback(AudioFeedbackType type) async {
    final voiceEnabled = _ref.read(voiceEnabledProvider);
    if (!voiceEnabled) return;
    await _audioService.playFeedback(type);
  }

  /// Read content aloud with language support (static helper for quick calls)
  static Future<void> speakContent({
    required WidgetRef ref,
    required String text,
    String? languageCode,
  }) async {
    final voiceEnabled = ref.read(voiceEnabledProvider);
    if (!voiceEnabled) return;

    final locale = languageCode ?? ref.read(localeProvider).languageCode;
    final audioService = ref.read(audioServiceProvider);
    await audioService.speak(text, languageCode: locale);
  }
}

/// Provider for VoiceHelper
final voiceHelperProvider = Provider<VoiceHelper>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return VoiceHelper(ref, audioService);
});

/// Extension on WidgetRef for fast voice access
extension VoiceWidgetRefExtension on WidgetRef {
  VoiceHelper get voice => read(voiceHelperProvider);
}

/// A simple audio feedback widget for game screens
class VoiceFeedbackWrapper extends ConsumerWidget {
  final Widget child;
  final String successMessage;
  final String errorMessage;
  final String? listeningPrompt;
  final bool enableVoiceFeedback;

  const VoiceFeedbackWrapper({
    super.key,
    required this.child,
    required this.successMessage,
    required this.errorMessage,
    this.listeningPrompt,
    this.enableVoiceFeedback = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceEnabled = ref.watch(voiceEnabledProvider);

    if (!voiceEnabled || !enableVoiceFeedback) {
      return child;
    }

    return _VoiceFeedbackObserver(
      successMessage: successMessage,
      errorMessage: errorMessage,
      listeningPrompt: listeningPrompt,
      child: child,
    );
  }
}

class _VoiceFeedbackObserver extends ConsumerStatefulWidget {
  final Widget child;
  final String successMessage;
  final String errorMessage;
  final String? listeningPrompt;

  const _VoiceFeedbackObserver({
    required this.child,
    required this.successMessage,
    required this.errorMessage,
    this.listeningPrompt,
  });

  @override
  ConsumerState<_VoiceFeedbackObserver> createState() =>
      _VoiceFeedbackObserverState();
}

class _VoiceFeedbackObserverState
    extends ConsumerState<_VoiceFeedbackObserver> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Simple voice prompt helper for onboarding
class VoiceOnboardingPrompt extends ConsumerWidget {
  const VoiceOnboardingPrompt({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceEnabled = ref.watch(voiceEnabledProvider);
    if (!voiceEnabled) return const SizedBox.shrink();

    final locale = ref.watch(localeProvider);
    final audioService = ref.read(audioServiceProvider);

    return FutureBuilder<void>(
      future: audioService.speak(
        'Welcome to NIRVANA. A gentle companion for your mind.',
        languageCode: locale.languageCode,
      ),
      builder: (context, snapshot) {
        return const SizedBox.shrink();
      },
    );
  }
}