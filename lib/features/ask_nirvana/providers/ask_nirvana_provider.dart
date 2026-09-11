// ignore_for_file: unused_field, prefer_final_fields

// ==============================================================================
// NIRVANA - Ask NIRVANA State Management
// Description: Riverpod state notifier managing elderly voice interaction lifecycle:
// IDLE -> LISTENING -> THINKING -> SPEAKING -> IDLE / ERROR.
// Reuses AudioService for real STT/TTS with live partial transcription,
// mutual exclusion, localized responses, timeout handling, and concurrency locks.
// ==============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/accessibility_providers.dart';
import '../../../core/network/audio_service.dart';
import '../models/chat_message.dart';
import '../services/nirvana_data_responder.dart';

/// Distinct states of voice and assistant lifecycle
enum AssistantVoiceState { idle, listening, thinking, speaking, error }

/// Immutable state for the Ask NIRVANA feature
@immutable
class AskNirvanaState {
  final List<ChatMessage> messages;
  final AssistantVoiceState voiceState;
  final String? errorMessage;
  final String? liveTranscript;

  const AskNirvanaState({
    required this.messages,
    this.voiceState = AssistantVoiceState.idle,
    this.errorMessage,
    this.liveTranscript,
  });

  AskNirvanaState copyWith({
    List<ChatMessage>? messages,
    AssistantVoiceState? voiceState,
    String? errorMessage,
    String? liveTranscript,
    bool clearError = false,
    bool clearLiveTranscript = false,
  }) {
    return AskNirvanaState(
      messages: messages ?? this.messages,
      voiceState: voiceState ?? this.voiceState,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      liveTranscript: clearLiveTranscript
          ? null
          : (liveTranscript ?? this.liveTranscript),
    );
  }
}

/// Riverpod notifier managing Ask NIRVANA conversation and voice interactions
class AskNirvanaNotifier extends StateNotifier<AskNirvanaState> {
  final Ref _ref;
  final IAudioService _audioService;
  int _mockResponseIndex = 0;
  bool _isProcessing = false;

  // Dementia-friendly responses mapped across NIRVANA's supported locales
  static const Map<String, List<String>> _localizedResponses = {
    'en': [
      "I'm right here with you. Take all the time you need. Today is going well, and you are safe and cared for.",
      "That is wonderful to hear. Remember to take a gentle sip of water and rest whenever you feel like it.",
      "I am always happy to talk with you. You can ask me anything, or we can just enjoy a peaceful moment together.",
      "Everything is taken care of. Your family and caregivers are looking out for you. How are you feeling right now?",
      "It is a lovely day. Would you like to try one of our gentle memory games, or listen to some soothing words?",
    ],
    'hi': [
      "मैं आपके साथ हूँ। कोई जल्दी नहीं है, आप बिल्कुल सुरक्षित हैं।",
      "यह सुनकर बहुत अच्छा लगा। थोड़ा पानी पी लीजिए और जब मन करे आराम कीजिए।",
      "मुझे आपसे बात करके बहुत खुशी होती है। आप मुझसे कुछ भी पूछ सकते हैं।",
      "सब कुछ ठीक है। आपके अपने और देखभाल करने वाले आपका पूरा ध्यान रख रहे हैं।",
    ],
    'bn': [
      "আমি আপনার সাথেই আছি। কোনো তাড়া নেই, আপনি সম্পূর্ণ নিরাপদ।",
      "এটা শুনে খুব ভালো লাগলো। একটু জল খেয়ে নিন এবং বিশ্রাম নিন।",
      "আপনার সাথে কথা বলতে পেরে আমার খুব ভালো লাগছে।",
      "সবকিছু ঠিকঠাক আছে। আপনার পরিবারের সকলে আপনার খেয়াল রাখছেন।",
    ],
    'as': [
      "মই আপোনাৰ লগতেই আছোঁ। কোনো চিন্তা নকৰিব, আপুনি সুৰক্ষিত।",
      "এইটো শুনি খুব ভাল লাগিল। অলপ পানী খাই লওক আৰু বিশ্ৰাম লওক।",
      "আপোনাৰ লগত কথা পাতি মোৰ বৰ ভাল লাগিছে।",
    ],
    'ne': [
      "म तपाईंसँगै छु। कुनै हतार छैन, तपाईं पूर्ण सुरक्षित हुनुहुन्छ।",
      "यो सुनेर धेरै खुसी लाग्यो। अलिकति पानी पिउनुहोस् र आराम गर्नुहोस्।",
      "तपाईंसँग कुरा गर्न पाउँदा मलाई धेरै आनन्द लागेको छ।",
    ],
    'mni': [
      "ঐহাক নহাক্কা লোয়ননা লৈরি। অদোম শান্তিনা লৈবীয়ু।",
      "নহাক্কা ৱারী শানবা অসি য়াম্না নুংঙাই।",
    ],
    'kha': [
      "Nga don ryngkat bad phi. Shong thait suk, ym don kano kano ka jingeh.",
      "Sngewbha ban iakren bad phi. Shim por bad thait bha.",
    ],
    'lus': [
      "I hnenah ka awm reng e. Hahchawl la, hahdam takin awm rawh.",
      "I bula awm hi ka lawm hle mai. Engkim a tha vek e.",
    ],
  };

  static const Map<String, String> _localizedGreetings = {
    'en':
        'Hello! I am NIRVANA, your companion. Tap the large microphone below to talk with me, or type your question.',
    'hi':
        'नमस्ते! मैं निर्वाण हूँ, आपका साथी। बात करने के लिए नीचे दिए गए बड़े माइक को दबाएं, या अपना प्रश्न लिखें।',
    'bn':
        'নমস্কার! আমি নির্ভানা, আপনার সঙ্গী। কথা বলতে নিচের মাইকে টাপ করুন, বা আপনার প্রশ্ন লিখুন।',
    'as':
        'নমস্কাৰ! মই নিৰ্বাণ, আপোনাৰ সংগী। কথা পাতিবলৈ তলেৰ মাইকত টেপ কৰক, নোৱহেলে আপোনাৰ প্ৰশ্ন লিখক।',
    'ne':
        'नमस्ते! म निर्वाण, तपाईंको साथी। कुरा गर्न तलको माइक थिच्नुहोस्, वा आफ्नो प्रश्न लेख्नुहोस्।',
    'mni': 'খুরুমজরি! ঐহাক নির্বানা, অদোমগী মরুপ।',
    'kha': 'Khublei! Nga dei ka NIRVANA. Kren lyngba u microphone.',
    'lus': 'Chibai! NIRVANA ka ni e. Tawng turin microphone hmet rawh.',
  };

  /// Resolve the greeting for the given locale, falling back to English.
  static String _getGreeting(String langCode) {
    return _localizedGreetings[langCode] ?? _localizedGreetings['en']!;
  }

  /// Resolve error message — "no speech detected".
  static String _getNoSpeechMsg(String langCode) {
    const map = {
      'en': "I didn't hear anything. Tap to speak again.",
      'hi': 'मुझे कुछ सुनाई नहीं दिया। फिर से बोलने के लिए टैप करें।',
      'bn': 'আমি কিছু শুনতে পাইনি। আবার বলতে ট্যাপ করুন।',
      'as': 'মই ধান্য শুনিলোং। পুনৰায় কোৱাৱ টেপ কৰক।',
      'ne': 'मैले केही सुनिनँ। फेरि बोल्न ट्याप गर्नुहोस्।',
    };
    return map[langCode] ?? map['en']!;
  }

  /// Resolve error message — "couldn't understand".
  static String _getErrorMsg(String langCode) {
    const map = {
      'en': "I couldn't understand that. Please try again.",
      'hi': 'मैं समझ नहीं पाया। कृपया दोबारा कोशिश करें।',
      'bn': 'আমি বুঝতে পারিনি। আবার চেষ্টা করুন।',
      'as': 'মই বুজিব পৰা নাইলোং। অনুগ্ৰহ পুনৰায় চেষ্টা কৰক।',
      'ne': 'मैले बुझिन। कृपया फेरि प्रयास गर्नुहोस्।',
    };
    return map[langCode] ?? map['en']!;
  }

  /// Resolve mic-unavailable message.
  static String _getMicUnavailableMsg(String langCode) {
    const map = {
      'en':
          'Microphone or speech recognition is not ready. You can type below anytime.',
      'hi': 'माइक्रोफोन या वाक् पहचान तैयार नहीं है। आप नीचे टाइप कर सकते हैं।',
      'bn':
          'মাইক্রোফোন বা স্পীচ রিকগনিশন প্রস্তুত নয়। আপনি নিচে টাইপ করতে পারেন।',
      'as':
          'মাইক্ৰোফোন বা ভাষণ চিনাক্তিকৰণ প্ৰস্তুত নহয়। আপুনি তলত টাইপ কৰিব পাৰে।',
      'ne':
          'माइक्रोफोन वा भाषण पहिचान तयार छैन। तपाईं तल टाइप गर्न सक्नुहुन्छ।',
    };
    return map[langCode] ?? map['en']!;
  }

  AskNirvanaNotifier(this._ref)
    : _audioService = _ref.read(audioServiceProvider),
      super(
        AskNirvanaState(
          messages: [
            ChatMessage(
              id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
              text: _getGreeting(_ref.read(localeProvider).languageCode),
              isUser: false,
              timestamp: DateTime.now(),
            ),
          ],
        ),
      ) {
    // Listen to global TTS speaking state to automatically return to IDLE when speech ends
    _ref.listen<bool>(isSpeakingProvider, (previous, isSpeaking) {
      if (previous == true &&
          !isSpeaking &&
          state.voiceState == AssistantVoiceState.speaking) {
        state = state.copyWith(voiceState: AssistantVoiceState.idle);
      }
    });

    // Update greeting if locale changes while chat is fresh
    _ref.listen(localeProvider, (previous, next) {
      if (state.messages.length == 1 && !state.messages.first.isUser) {
        final greeting = _getGreeting(next.languageCode);
        state = AskNirvanaState(
          messages: [
            ChatMessage(
              id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
              text: greeting,
              isUser: false,
              timestamp: DateTime.now(),
            ),
          ],
          voiceState: AssistantVoiceState.idle,
        );
      }
    });
  }

  /// Start voice listening using real STT with live partial transcription
  Future<void> startListening() async {
    // Concurrency guard: prevent multiple overlapping requests
    if (_isProcessing) return;

    final activeLocale = _ref.read(localeProvider);

    // If currently speaking, stop TTS first
    if (state.voiceState == AssistantVoiceState.speaking ||
        await _audioService.isSpeaking()) {
      await stopSpeaking();
    }

    _isProcessing = true;

    state = state.copyWith(
      voiceState: AssistantVoiceState.listening,
      clearError: true,
      clearLiveTranscript: true,
    );

    try {
      // 1. Check speech recognition availability & microphone permission
      final isAvailable = await _audioService.isSpeechRecognitionAvailable();
      if (!isAvailable) {
        _isProcessing = false;
        state = state.copyWith(
          voiceState: AssistantVoiceState.error,
          errorMessage: _getMicUnavailableMsg(activeLocale.languageCode),
          clearLiveTranscript: true,
        );
        return;
      }

      // 2. Start listening with live partial transcript streaming
      final recognizedText = await _audioService.listenForSpeech(
        languageCode: activeLocale.languageCode,
        timeoutSeconds: 8,
        showListeningUI: true,
        onPartialResult: (partialText) {
          if (mounted &&
              state.voiceState == AssistantVoiceState.listening &&
              partialText.trim().isNotEmpty) {
            state = state.copyWith(liveTranscript: partialText);
          }
        },
      );

      if (!mounted) {
        _isProcessing = false;
        return;
      }

      // 3. Process recognized text or handle empty speech
      if (recognizedText != null && recognizedText.trim().isNotEmpty) {
        state = state.copyWith(clearLiveTranscript: true);
        await _handleUserInput(recognizedText.trim());
      } else {
        // No speech detected within timeout or silence
        state = state.copyWith(
          voiceState: AssistantVoiceState.error,
          errorMessage: _getNoSpeechMsg(activeLocale.languageCode),
          clearLiveTranscript: true,
        );
      }
    } catch (e) {
      debugPrint('⚠️ Ask NIRVANA voice recognition error: $e');
      if (mounted) {
        state = state.copyWith(
          voiceState: AssistantVoiceState.error,
          errorMessage: _getErrorMsg(_ref.read(localeProvider).languageCode),
          clearLiveTranscript: true,
        );
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// Stop active listening immediately
  Future<void> stopListening() async {
    await _audioService.stopListening();
  }

  /// Send text input from the secondary keyboard entry
  Future<void> sendTextMessage(String text) async {
    if (_isProcessing) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _isProcessing = true;
    try {
      await _handleUserInput(trimmed);
    } finally {
      _isProcessing = false;
    }
  }

  /// Processes user input, transitions to thinking, and generates a gentle response
  Future<void> _handleUserInput(String userInput) async {
    // 1. Append user message
    final userMessage = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: userInput,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      voiceState: AssistantVoiceState.thinking,
      clearError: true,
      clearLiveTranscript: true,
    );

    // 2. Dementia-friendly thinking pause (1000ms to feel natural, not abrupt)
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    // 3. Generate response from real NIRVANA data layer
    final activeLocale = _ref.read(localeProvider);
    final dataResponder = _ref.read(nirvanaDataResponderProvider);
    final conversation = state.messages
        .take(12)
        .map(
          (message) => <String, String>{
            'role': message.isUser ? 'user' : 'model',
            'text': message.text,
          },
        )
        .toList(growable: false);
    final responseText = await dataResponder.respond(
      userInput,
      activeLocale.languageCode,
      conversation: conversation,
    );
    if (!mounted) return;

    final assistantMessage = ChatMessage(
      id: 'assistant_${DateTime.now().millisecondsSinceEpoch}',
      text: responseText,
      isUser: false,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, assistantMessage],
      voiceState: AssistantVoiceState.speaking,
    );

    // 4. Speak response if voice guidance is enabled
    final voiceEnabled = _ref.read(voiceEnabledProvider);
    if (voiceEnabled) {
      await speakMessage(responseText);
    } else {
      state = state.copyWith(voiceState: AssistantVoiceState.idle);
    }
  }

  /// Speak a specific text response aloud using TTS in the active language
  Future<void> speakMessage(String text) async {
    final activeLocale = _ref.read(localeProvider);

    // Stop any speech recognition first
    await _audioService.stopListening();

    state = state.copyWith(voiceState: AssistantVoiceState.speaking);
    await _audioService.speak(text, languageCode: activeLocale.languageCode);
  }

  /// Stop current TTS speech
  Future<void> stopSpeaking() async {
    await _audioService.stopSpeaking();
    if (mounted && state.voiceState == AssistantVoiceState.speaking) {
      state = state.copyWith(voiceState: AssistantVoiceState.idle);
    }
  }

  /// Clear the conversation and restore the initial greeting
  void clearConversation() {
    stopSpeaking();
    stopListening();
    final activeLocale = _ref.read(localeProvider);
    final greeting =
        _localizedGreetings[activeLocale.languageCode] ??
        _localizedGreetings['en']!;

    state = AskNirvanaState(
      messages: [
        ChatMessage(
          id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
          text: greeting,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ],
      voiceState: AssistantVoiceState.idle,
      errorMessage: null,
      liveTranscript: null,
    );
  }

  @override
  void dispose() {
    try {
      _audioService.stopListening();
      _audioService.stopSpeaking();
    } catch (_) {}
    super.dispose();
  }
}

/// Provider for Ask NIRVANA state notifier
final askNirvanaProvider =
    StateNotifierProvider.autoDispose<AskNirvanaNotifier, AskNirvanaState>((
      ref,
    ) {
      return AskNirvanaNotifier(ref);
    });
