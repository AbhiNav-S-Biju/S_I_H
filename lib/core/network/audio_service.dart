// ==============================================================================
// NIRVANA - Audio Service
// Description: Handles text-to-speech, speech-to-text, and audio playback
// for voice-assisted interaction. Designed for elderly users with
// clear, supportive audio feedback.
// ==============================================================================

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Enum for different types of audio feedback
enum AudioFeedbackType {
  confirmation,
  error,
  encouragement,
  instruction,
  gameSuccess,
  gameError,
}

/// Configuration for voice features
class VoiceConfig {
  /// Speech rate for TTS (0.0 to 2.0, default 0.8 for elderly clarity)
  static const double speechRate = 0.8;

  /// Pitch for TTS (0.5 to 2.0, default 1.0)
  static const double speechPitch = 1.0;

  /// Volume for TTS (0.0 to 1.0, default 0.9)
  static const double speechVolume = 0.9;

  /// Language codes for TTS/STT
  static const Map<String, String> ttsLanguageMap = {
    'en': 'en-US',
    'hi': 'hi-IN',
    'as': 'as-IN',
    'bn': 'bn-IN',
    'mni': 'mni-IN',
    'kha': 'kha-IN',
    'lus': 'lus-IN',
    'ne': 'ne-NP',
  };

  /// Whether to use high-quality voice (may require internet)
  static const bool preferNetworkVoices = false;

  /// Timeout for speech recognition (seconds)
  static const int speechRecognitionTimeout = 15;
}

/// Abstract interface for audio service
abstract class IAudioService {
  /// Initialize the audio service
  Future<bool> initialize();

  /// Speak text using text-to-speech
  Future<void> speak(String text, {String? languageCode});

  /// Stop current speech
  Future<void> stopSpeaking();

  /// Check if TTS is currently speaking
  Future<bool> isSpeaking();

  /// Listen for speech input and return recognized text
  Future<String?> listenForSpeech({
    String? languageCode,
    int? timeoutSeconds,
    bool showListeningUI = true,
  });

  /// Stop speech listening
  Future<void> stopListening();

  /// Play audio feedback sound
  Future<void> playFeedback(AudioFeedbackType type);

  /// Load and play a specific audio asset
  Future<void> playAsset(String assetPath);

  /// Dispose resources
  void dispose();
}

/// Implementation of audio service
class AudioService implements IAudioService {
  final FlutterTts _flutterTts;
  final stt.SpeechToText _speechToText;
  final AudioPlayer _audioPlayer;
  bool _isInitialized = false;
  bool _isSpeaking = false;
  final String _currentLanguage = 'en';
  String? _activeTtsLanguage;

  AudioService({
    FlutterTts? flutterTts,
    stt.SpeechToText? speechToText,
    AudioPlayer? audioPlayer,
  })  : _flutterTts = flutterTts ?? FlutterTts(),
        _speechToText = speechToText ?? stt.SpeechToText(),
        _audioPlayer = audioPlayer ?? AudioPlayer();

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Configure audio session for platforms that support it (iOS/Android/macOS)
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.macOS)) {
        try {
          final session = await AudioSession.instance;
          await session.configure(const AudioSessionConfiguration.speech());
        } catch (e) {
          debugPrint('⚠️ AudioSession configuration skipped: $e');
        }
      }

      // Initialize TTS
      _activeTtsLanguage = _ttsLanguageFromLocale(_currentLanguage);
      try {
        await _flutterTts.setLanguage(_activeTtsLanguage!);
        await _flutterTts.setSpeechRate(VoiceConfig.speechRate);
        await _flutterTts.setPitch(VoiceConfig.speechPitch);
        await _flutterTts.setVolume(VoiceConfig.speechVolume);
      } catch (e) {
        debugPrint('⚠️ FlutterTts settings error: $e');
      }

      // Set TTS event handlers
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint('TTS Error: $msg');
      });

      _isInitialized = true;
      debugPrint('🔊 AudioService initialized successfully');
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to initialize AudioService: $e');
      debugPrint(stackTrace.toString());
      return false;
    }
  }

  @override
  Future<void> speak(String text, {String? languageCode}) async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) return;
    }

    try {
      // Stop any ongoing speech first
      await stopSpeaking();

      // Determine language to use
      final String langCode = languageCode ?? _currentLanguage;
      final String ttsLang = _ttsLanguageFromLocale(langCode);

      // Set language if changed
      if (ttsLang != _activeTtsLanguage) {
        await _flutterTts.setLanguage(ttsLang);
        _activeTtsLanguage = ttsLang;
      }

      // Speak the text
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('❌ Error in TTS speak: $e');
    }
  }

  @override
  Future<void> stopSpeaking() async {
    if (_isInitialized && _isSpeaking) {
      await _flutterTts.stop();
      _isSpeaking = false;
    }
  }

  @override
  Future<bool> isSpeaking() async => _isSpeaking;

  @override
  Future<String?> listenForSpeech({
    String? languageCode,
    int? timeoutSeconds,
    bool showListeningUI = true,
  }) async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) return null;
    }

    try {
      final bool available = await _speechToText.initialize(
        debugLogging: kDebugMode,
      );

      if (!available) {
        debugPrint('❌ Speech recognition not available');
        return null;
      }

      final String langCode = languageCode ?? _currentLanguage;
      final String localeId = _localeForSpeechToText(langCode);

      final completer = Completer<String?>();
      String? recognizedWords;

      await _speechToText.listen(
        onResult: (result) {
          recognizedWords = result.recognizedWords;
          if (result.finalResult && !completer.isCompleted) {
            completer.complete(recognizedWords);
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
          cancelOnError: true,
          partialResults: showListeningUI,
          localeId: localeId,
          listenFor: Duration(
            seconds: timeoutSeconds ?? VoiceConfig.speechRecognitionTimeout,
          ),
          pauseFor: const Duration(seconds: 3),
        ),
      );

      // Set a fallback timer to resolve with whatever was recognized
      final timeoutDuration = Duration(
        seconds: (timeoutSeconds ?? VoiceConfig.speechRecognitionTimeout) + 1,
      );
      Timer(timeoutDuration, () {
        if (!completer.isCompleted) {
          completer.complete(recognizedWords);
        }
      });

      final finalResult = await completer.future;
      return finalResult?.trim();
    } catch (e) {
      debugPrint('❌ Error in speech recognition: $e');
      return null;
    }
  }

  @override
  Future<void> stopListening() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
  }

  @override
  Future<void> playFeedback(AudioFeedbackType type) async {
    try {
      String assetPath;
      switch (type) {
        case AudioFeedbackType.confirmation:
          assetPath = 'assets/audio/confirmation.mp3';
          break;
        case AudioFeedbackType.error:
          assetPath = 'assets/audio/error.mp3';
          break;
        case AudioFeedbackType.encouragement:
          assetPath = 'assets/audio/encouragement.mp3';
          break;
        case AudioFeedbackType.instruction:
          assetPath = 'assets/audio/instruction.mp3';
          break;
        case AudioFeedbackType.gameSuccess:
          assetPath = 'assets/audio/game_success.mp3';
          break;
        case AudioFeedbackType.gameError:
          assetPath = 'assets/audio/game_error.mp3';
          break;
      }

      await playAsset(assetPath);
    } catch (e) {
      debugPrint('❌ Error playing feedback: $e');
    }
  }

  @override
  Future<void> playAsset(String assetPath) async {
    try {
      await _audioPlayer.setAsset(assetPath);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('❌ Error playing asset $assetPath: $e');
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _speechToText.cancel();
    _audioPlayer.dispose();
  }

  // Helper methods

  String _ttsLanguageFromLocale(String languageCode) {
    return VoiceConfig.ttsLanguageMap[languageCode] ?? 'en-US';
  }

  String _localeForSpeechToText(String languageCode) {
    final Map<String, String> sttLocaleMap = {
      'en': 'en_US',
      'hi': 'hi_IN',
      'as': 'as_IN',
      'bn': 'bn_IN',
      'mni': 'mni_IN',
      'kha': 'kha_IN',
      'lus': 'lus_IN',
      'ne': 'ne_NP',
    };
    return sttLocaleMap[languageCode] ?? 'en_US';
  }
}

/// Riverpod Providers
final audioServiceProvider = Provider<IAudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});

final isSpeakingProvider = StateProvider<bool>((ref) {
  return false;
});