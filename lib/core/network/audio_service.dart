// ==============================================================================
// NIRVANA - Audio Service
// Description: Handles text-to-speech, speech-to-text, and audio playback
// for voice-assisted interaction. Designed for elderly users with
// clear, supportive audio feedback.
// ==============================================================================

import 'dart:async';
import 'dart:io';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/accessibility_providers.dart';

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
  /// Speech rate for TTS (0.0 to 2.0, default 0.5 for elderly clarity and phone playback)
  static const double speechRate = 0.5;

  /// Pitch for TTS (0.5 to 2.0, default 1.0)
  static const double speechPitch = 1.0;

  /// Volume for TTS (0.0 to 1.0, default 0.9)
  static const double speechVolume = 0.9;

  /// Language codes for native TTS/STT
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

  /// Cloud TTS language codes for Google Translate TTS fallback
  static const Map<String, String> cloudTtsLanguageMap = {
    'en': 'en',
    'hi': 'hi',
    'bn': 'bn',
    'ne': 'ne',
    'as': 'bn', // Assamese uses Bengali script and phonetics in Google TTS
    'mni': 'bn',
    'kha': 'en',
    'lus': 'en',
  };

  /// Fallback language preferences (ordered by preference):
  /// For Indian languages, prefer en-IN (Indian English accent) over en-US
  static const Map<String, List<String>> fallbackChain = {
    'hi-IN': ['en-IN', 'en-US'],
    'bn-IN': ['en-IN', 'en-US'],
    'as-IN': ['en-IN', 'en-US'],
    'mni-IN': ['en-IN', 'en-US'],
    'kha-IN': ['en-IN', 'en-US'],
    'lus-IN': ['en-IN', 'en-US'],
    'ne-NP': ['en-IN', 'en-US'],
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

  /// Callback when speaking state changes
  void Function(bool isSpeaking)? onSpeakingChanged;

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

  /// Set the active language for TTS and voice features
  void setLanguage(String languageCode);
}

/// Implementation of audio service
class AudioService implements IAudioService {
  final FlutterTts _flutterTts;
  final stt.SpeechToText _speechToText;
  final AudioPlayer _audioPlayer;
  bool _isInitialized = false;
  bool _isSpeaking = false;
  String _currentLanguage = 'en';
  String? _activeTtsLanguage;

  @override
  void Function(bool isSpeaking)? onSpeakingChanged;

  /// Set of language codes actually available on this device/OS
  final Set<String> _availableLanguages = {};

  void _notifySpeakingState(bool speaking) {
    _isSpeaking = speaking;
    onSpeakingChanged?.call(speaking);
  }

  @override
  void setLanguage(String languageCode) {
    _currentLanguage = languageCode;
    if (_isInitialized) {
      final resolvedLang = _resolveAvailableLanguage(languageCode);
      if (resolvedLang != _activeTtsLanguage) {
        _activeTtsLanguage = resolvedLang;
        _flutterTts.setLanguage(resolvedLang);
        debugPrint(
            '🔊 TTS language set to: $resolvedLang (requested: $languageCode)');
      }
    }
  }

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

      // Discover available TTS languages on this system
      await _discoverAvailableLanguages();

      // Initialize TTS with the best available language
      _activeTtsLanguage = _resolveAvailableLanguage(_currentLanguage);
      try {
        await _flutterTts.setLanguage(_activeTtsLanguage!);
        await _flutterTts.setSpeechRate(VoiceConfig.speechRate);
        await _flutterTts.setPitch(VoiceConfig.speechPitch);
        await _flutterTts.setVolume(VoiceConfig.speechVolume);
        debugPrint(
            '🔊 TTS initialized with language: $_activeTtsLanguage (requested: $_currentLanguage)');
      } catch (e) {
        debugPrint('⚠️ FlutterTts settings error: $e');
      }

      // Set TTS event handlers
      _flutterTts.setStartHandler(() {
        _notifySpeakingState(true);
        debugPrint('🔊 Native TTS started speaking');
      });

      _flutterTts.setCompletionHandler(() {
        _notifySpeakingState(false);
        debugPrint('🔊 Native TTS finished speaking');
      });

      _flutterTts.setErrorHandler((msg) {
        _notifySpeakingState(false);
        debugPrint('❌ Native TTS Error: $msg');
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

  /// Queries the TTS engine for available languages and caches them
  Future<void> _discoverAvailableLanguages() async {
    try {
      final dynamic languages = await _flutterTts.getLanguages;
      if (languages is List) {
        _availableLanguages.clear();
        for (final lang in languages) {
          _availableLanguages.add(lang.toString().toLowerCase());
        }
        debugPrint(
            '🔊 Available native TTS languages on this system: $_availableLanguages');
      }
    } catch (e) {
      debugPrint('⚠️ Could not query available TTS languages: $e');
    }
  }

  /// Resolves the best available TTS language for a given locale code.
  /// If the ideal language isn't installed, walks the fallback chain.
  String _resolveAvailableLanguage(String languageCode) {
    final idealLang = _ttsLanguageFromLocale(languageCode);

    // If no languages were discovered, just return the ideal (best effort)
    if (_availableLanguages.isEmpty) {
      debugPrint(
          '⚠️ No available languages discovered, using ideal: $idealLang');
      return idealLang;
    }

    // Check if the ideal language is available (case-insensitive)
    if (_isLanguageAvailable(idealLang)) {
      return idealLang;
    }

    // Walk the fallback chain
    final fallbacks = VoiceConfig.fallbackChain[idealLang];
    if (fallbacks != null) {
      for (final fallback in fallbacks) {
        if (_isLanguageAvailable(fallback)) {
          debugPrint(
              '⚠️ TTS language "$idealLang" not available, falling back to "$fallback"');
          return fallback;
        }
      }
    }

    // Ultimate fallback: try en-US, then whatever is first available
    if (_isLanguageAvailable('en-US')) {
      debugPrint(
          '⚠️ TTS language "$idealLang" not available, ultimate fallback to "en-US"');
      return 'en-US';
    }

    // Return ideal as last resort (TTS may handle it or fail gracefully)
    debugPrint(
        '⚠️ No suitable TTS fallback found, using ideal: $idealLang');
    return idealLang;
  }

  /// Check if a language is available (case-insensitive, handles both
  /// dash and underscore formats: en-US, en_US, en-us, etc.)
  bool _isLanguageAvailable(String language) {
    final normalized = language.toLowerCase().replaceAll('_', '-');
    for (final available in _availableLanguages) {
      final normalizedAvailable = available.replaceAll('_', '-');
      if (normalizedAvailable == normalized) return true;
    }
    return false;
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
      final String idealLang = _ttsLanguageFromLocale(langCode);
      final bool nativeAvailable = _isLanguageAvailable(idealLang);

      debugPrint(
          '🔊 TTS speak requested: langCode=$langCode, idealLang=$idealLang, nativeAvailable=$nativeAvailable');

      // If native voice is available (e.g. English on Windows, or installed voices on mobile),
      // use flutter_tts
      if (nativeAvailable) {
        if (idealLang != _activeTtsLanguage) {
          await _flutterTts.setLanguage(idealLang);
          _activeTtsLanguage = idealLang;
          debugPrint('🔊 Native TTS language switched to: $idealLang');
        }

        _notifySpeakingState(true);
        debugPrint(
            '🔊 Native TTS speaking [lang=$idealLang]: "${text.length > 60 ? '${text.substring(0, 60)}...' : text}"');

        await _flutterTts.speak(text);
        return;
      }

      // Native voice is NOT available on this device/OS (e.g. Windows without Hindi/Bengali voices).
      // Use Cloud TTS via Google Translate TTS played through AudioPlayer!
      debugPrint(
          '🌐 Native voice for "$idealLang" unavailable. Using Cloud TTS fallback for "$langCode"...');
      final cloudSuccess = await _speakCloud(text, langCode);
      if (cloudSuccess) return;

      // Ultimate fallback: if cloud TTS fails (e.g. offline), try native as best effort
      debugPrint('⚠️ Cloud TTS failed or unavailable, attempting best-effort native fallback');
      final fallbackLang = _resolveAvailableLanguage(langCode);
      if (fallbackLang != _activeTtsLanguage) {
        await _flutterTts.setLanguage(fallbackLang);
        _activeTtsLanguage = fallbackLang;
      }
      _notifySpeakingState(true);
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('❌ Error in TTS speak: $e');
      _notifySpeakingState(false);
    }
  }

  /// Cloud TTS implementation using Google Translate TTS with local MP3 disk caching
  Future<bool> _speakCloud(String text, String langCode) async {
    final cloudLang = VoiceConfig.cloudTtsLanguageMap[langCode] ?? 'en';
    final chunks = _splitTextIntoChunks(text);
    debugPrint('🌐 Cloud TTS playing ${chunks.length} chunk(s) [lang=$cloudLang]');

    _notifySpeakingState(true);

    try {
      for (final chunk in chunks) {
        if (!_isSpeaking) break; // cancelled by user

        final file = await _getCachedOrDownloadAudio(chunk, cloudLang);
        if (file == null || !await file.exists()) {
          debugPrint('⚠️ Cloud TTS could not acquire audio for chunk: "$chunk"');
          return false;
        }

        if (!_isSpeaking) break;

        await _audioPlayer.stop();
        await _audioPlayer.setFilePath(file.path);
        await _audioPlayer.setVolume(VoiceConfig.speechVolume);
        await _audioPlayer.play();

        // Wait until playback of this chunk completes or user cancels
        await _audioPlayer.playerStateStream.firstWhere(
          (state) =>
              state.processingState == ProcessingState.completed ||
              !_isSpeaking,
        );
      }
      return true;
    } catch (e) {
      debugPrint('⚠️ Cloud TTS playback error: $e');
      return false;
    } finally {
      _notifySpeakingState(false);
    }
  }

  /// Splits long text into smaller conversational phrases (< 140 chars)
  /// so Google Translate TTS API doesn't truncate or reject requests.
  List<String> _splitTextIntoChunks(String text, {int maxLength = 140}) {
    final cleanText = text.trim();
    if (cleanText.length <= maxLength) return [cleanText];

    final List<String> chunks = [];
    final RegExp sentenceSplitter = RegExp(r'(?<=[.!?,\n।])\s+');
    final sentences = cleanText.split(sentenceSplitter);

    String currentChunk = '';
    for (final sentence in sentences) {
      final candidate =
          currentChunk.isEmpty ? sentence : '$currentChunk $sentence';
      if (candidate.length <= maxLength) {
        currentChunk = candidate;
      } else {
        if (currentChunk.isNotEmpty) {
          chunks.add(currentChunk);
          currentChunk = '';
        }
        if (sentence.length <= maxLength) {
          currentChunk = sentence;
        } else {
          // Break very long single sentences by space
          final words = sentence.split(' ');
          for (final word in words) {
            final wordCandidate =
                currentChunk.isEmpty ? word : '$currentChunk $word';
            if (wordCandidate.length <= maxLength) {
              currentChunk = wordCandidate;
            } else {
              if (currentChunk.isNotEmpty) chunks.add(currentChunk);
              currentChunk = word;
            }
          }
        }
      }
    }
    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk);
    }
    return chunks;
  }

  /// Downloads TTS audio from Google Translate endpoint with local caching.
  Future<File?> _getCachedOrDownloadAudio(String text, String cloudLang) async {
    try {
      final tempDir = Directory.systemTemp;
      final cacheDir = Directory('${tempDir.path}/nirvana_tts_cache');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      final hash = text.hashCode.toRadixString(16);
      final cacheFile = File('${cacheDir.path}/tts_${cloudLang}_$hash.mp3');

      // Return cached file if it exists and has content
      if (await cacheFile.exists() && (await cacheFile.length()) > 300) {
        return cacheFile;
      }

      final uri = Uri.parse(
        'https://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&tl=$cloudLang&q=${Uri.encodeComponent(text)}',
      );

      final client = HttpClient();
      try {
        final request = await client.getUrl(uri);
        request.headers.set(
          'User-Agent',
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        );
        final response =
            await request.close().timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final bytes = await response
              .fold<List<int>>([], (acc, data) => acc..addAll(data));
          if (bytes.length > 300) {
            await cacheFile.writeAsBytes(bytes, flush: true);
            return cacheFile;
          }
        } else {
          debugPrint('⚠️ Google TTS HTTP error: ${response.statusCode}');
        }
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('⚠️ Error downloading TTS audio: $e');
    }
    return null;
  }

  @override
  Future<void> stopSpeaking() async {
    _notifySpeakingState(false);
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('⚠️ flutterTts.stop error: $e');
    }
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('⚠️ audioPlayer.stop error: $e');
    }
  }

  @override
  Future<bool> isSpeaking() async => _isSpeaking || _audioPlayer.playing;

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
    _notifySpeakingState(false);
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
  service.onSpeakingChanged = (isSpeaking) {
    ref.read(isSpeakingProvider.notifier).state = isSpeaking;
  };

  final initialLocale = ref.read(localeProvider);
  service.setLanguage(initialLocale.languageCode);

  ref.listen<Locale>(localeProvider, (previous, next) {
    debugPrint(
        '🔊 Locale changed: ${previous?.languageCode} -> ${next.languageCode}');
    service.setLanguage(next.languageCode);
  });

  ref.onDispose(() => service.dispose());
  return service;
});

final isSpeakingProvider = StateProvider<bool>((ref) {
  return false;
});