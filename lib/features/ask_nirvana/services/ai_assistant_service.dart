// ==============================================================================
// NIRVANA - Ask NIRVANA AI Assistant Service
// Description: Secure AI fallback layer for queries that do NOT match structured
// NIRVANA intents (Reminders, Routine, Family, etc.).
//
// SECURITY & PRIVACY:
// - Zero private AI API keys in Flutter source code.
// - External AI requests route via Supabase Edge Function `ask-nirvana-ai`.
// - Strict dementia-safety, medical diversion, and localized fallback mechanisms.
// ==============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/network/connectivity_monitor.dart';

/// Abstract contract for Ask NIRVANA AI fallback assistant
abstract class IAiAssistantService {
  /// Generates a gentle, dementia-safe AI fallback response for unmapped queries
  Future<String> getAiFallbackResponse({
    required String query,
    required String languageCode,
    String? patientContext,
  });
}

abstract interface class IAdvancedNirvanaAiService {
  Future<String> getAiResponse({
    required String query,
    required String languageCode,
    String? patientContext,
    NirvanaToolExecutor? toolExecutor,
    List<Map<String, String>> conversation = const [],
  });
}

typedef NirvanaToolExecutor =
    Future<String> Function(String toolName, Map<String, dynamic> arguments);

/// Supabase Edge Function implementation of IAiAssistantService
class SupabaseAiAssistantService
    implements IAiAssistantService, IAdvancedNirvanaAiService {
  final SupabaseClient? _supabaseClient;
  final IConnectivityMonitor _connectivityMonitor;
  final Duration _timeout;

  SupabaseAiAssistantService({
    SupabaseClient? supabaseClient,
    required IConnectivityMonitor connectivityMonitor,
    Duration timeout = const Duration(seconds: 7),
  }) : _supabaseClient = supabaseClient,
       _connectivityMonitor = connectivityMonitor,
       _timeout = timeout;

  // Localized offline & connection failure fallbacks
  static const Map<String, String> _connectionFailureMessages = {
    'en':
        "I can't connect right now, but I can still help with your reminders and daily routine.",
    'hi':
        'मैं अभी कनेक्ट नहीं कर पा रहा हूँ, लेकिन मैं आपकी दवा और दिनचर्या में मदद कर सकता हूँ।',
    'bn':
        'আমি এখন সংযোগ করতে পারছি না, তবে আমি আপনার রিমাইন্ডার এবং দৈনন্দিন রুটিনে সাহায্য করতে পারি।',
    'as':
        'মই এই মুহূৰ্তত সংযোগ কৰিব পৰা নাই, কিন্তু মই আপোনাৰ সোঁৱৰণী আৰু দৈনিক কামত সহায় কৰিব পাৰোঁ।',
    'ne':
        'म अहिले जडान गर्न सक्दिनँ, तर म तपाईंका रिमाइन्डरहरू र दैनिक तालिकामा मद्दत गर्न सक्छु।',
    'mni':
        'ঐহাক হৌজিক কনেক্ট তৌবা ঙমদ্রে, অদুবু ঐহাক্না অদোমগী রিমাইন্দর অমসুং নোংমগী থবকশিংদা মতেং পাংবা ঙমগনি।',
    'kha':
        'Nga ym lah ban iasoh mynta, hynrei nga dang lah ban iarap ia ki jingkynmaw bad ka rukom trei jong phi.',
    'lus':
        'Tunah ka inthlunzawm thei rih lo, mahse i thil tih tur leh daily routine-ah ka pui thei reng che.',
  };

  // Localized medical & emergency safety redirects
  static const Map<String, String> _medicalSafetyMessages = {
    'en':
        'If you are feeling unwell or have a medical question, please talk to your caregiver, doctor, or emergency services right away.',
    'hi':
        'यदि आपकी तबीयत ठीक नहीं है या कोई चिकित्सा संबंधी प्रश्न है, तो कृपया तुरंत अपने देखभालकर्ता या डॉक्टर से संपर्क करें।',
    'bn':
        'যদি আপনার শরীর খারাপ লাগে বা কোনো চিকিৎসার প্রশ্ন থাকে, তবে অনুগ্রহ করে এখনই আপনার সেবাদানকারী বা ডাক্তারের সাথে কথা বলুন।',
    'as':
        'যদি আপোনাৰ গা ভাল লগা নাই বা কিবা চিকিৎসা সম্পৰ্কীয় প্ৰশ্ন আছে, অনুগ্ৰহ কৰি এতিয়াই আপোনাৰ যত্নলোৱা ব্যক্তি বা চিকিৎসকৰ লগত কথা পাতক।',
    'ne':
        'यदि तपाईंलाई सन्चो छैन वा कुनै चिकित्सा प्रश्न छ भने, कृपया तुरुन्तै आफ्नो हेरचाहकर्ता वा डाक्टरसँग कुरा गर्नुहोस्।',
  };

  @override
  Future<String> getAiFallbackResponse({
    required String query,
    required String languageCode,
    String? patientContext,
  }) => getAiResponse(
    query: query,
    languageCode: languageCode,
    patientContext: patientContext,
  );

  @override
  Future<String> getAiResponse({
    required String query,
    required String languageCode,
    String? patientContext,
    NirvanaToolExecutor? toolExecutor,
    List<Map<String, String>> conversation = const [],
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return _getConnectionFailureMessage(languageCode);
    }

    // 1. Client-Side Pre-Flight Dementia & Emergency Safety Guard
    if (_isMedicalOrEmergencyQuery(cleanQuery)) {
      return _getMedicalSafetyMessage(languageCode);
    }

    // 2. Connectivity Check
    try {
      final status = await _connectivityMonitor.checkStatus();
      if (status == NetworkStatus.offline) {
        debugPrint(
          'ℹ️ [AiAssistantService] Offline mode: returning local fallback',
        );
        return _getConnectionFailureMessage(languageCode);
      }
    } catch (e) {
      debugPrint('⚠️ [AiAssistantService] Connectivity check failed: $e');
      return _getConnectionFailureMessage(languageCode);
    }

    // 3. Supabase Client Verification
    final client = _supabaseClient ?? _resolveDefaultSupabaseClient();
    if (client == null || !SupabaseConfig.isConfigured) {
      debugPrint(
        'ℹ️ [AiAssistantService] Supabase not configured: returning friendly local message',
      );
      return _getConnectionFailureMessage(languageCode);
    }

    // 4. Remote Supabase Edge Function Call with Timeout & Error Recovery
    try {
      var response = await _invoke(
        client,
        body: {
          'query': cleanQuery,
          'languageCode': languageCode,
          if (patientContext != null && patientContext.isNotEmpty)
            'patientContext': patientContext,
          if (conversation.isNotEmpty) 'conversation': conversation,
        },
      );

      final toolCalls = _readToolCalls(response.data);
      if (toolCalls.isNotEmpty && toolExecutor != null) {
        final toolResults = <Map<String, dynamic>>[];
        for (final call in toolCalls) {
          final result = await toolExecutor(
            call['name'] as String,
            (call['arguments'] as Map<String, dynamic>?) ?? const {},
          );
          toolResults.add({'name': call['name'], 'result': result});
        }
        response = await _invoke(
          client,
          body: {
            'query': cleanQuery,
            'languageCode': languageCode,
            'toolResults': toolResults,
            if (patientContext != null && patientContext.isNotEmpty)
              'patientContext': patientContext,
            if (conversation.isNotEmpty) 'conversation': conversation,
          },
        );
      }

      if (response.status == 200 && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['reply'] is String) {
          final reply = (data['reply'] as String).trim();
          if (reply.isNotEmpty) {
            return reply;
          }
        } else if (data is String && data.trim().isNotEmpty) {
          return data.trim();
        }
      }

      debugPrint(
        '⚠️ [AiAssistantService] Edge function returned status: ${response.status}',
      );
      return _getConnectionFailureMessage(languageCode);
    } on TimeoutException {
      debugPrint(
        '⏱️ [AiAssistantService] Edge function timed out after ${_timeout.inSeconds}s',
      );
      return _getConnectionFailureMessage(languageCode);
    } catch (e) {
      debugPrint('⚠️ [AiAssistantService] Exception calling AI fallback: $e');
      return _getConnectionFailureMessage(languageCode);
    }
  }

  Future<dynamic> _invoke(
    SupabaseClient client, {
    required Map<String, dynamic> body,
  }) {
    return client.functions
        .invoke('ask-nirvana-ai', body: body)
        .timeout(_timeout);
  }

  List<Map<String, dynamic>> _readToolCalls(dynamic data) {
    if (data is! Map) return const [];
    final calls = data['toolCalls'];
    if (calls is! List) return const [];
    return calls
        .whereType<Map>()
        .map(
          (call) => <String, dynamic>{
            'name': call['name']?.toString() ?? '',
            'arguments': call['arguments'] is Map
                ? Map<String, dynamic>.from(call['arguments'] as Map)
                : <String, dynamic>{},
          },
        )
        .where((call) => (call['name'] as String).isNotEmpty)
        .toList(growable: false);
  }

  /// Client-side emergency & medical query detection for immediate elder safety
  bool _isMedicalOrEmergencyQuery(String clean) {
    final lower = clean.toLowerCase();
    const emergencyKeywords = [
      'emergency',
      'ambulance',
      'chest pain',
      'heart attack',
      'stroke',
      'cannot breathe',
      'cant breathe',
      'bleeding',
      'severe pain',
      'hospital',
      'change my dose',
      'stop my medicine',
      'increase dosage',
      'diagnose me',
      'do i have dementia',
      'do i have alzheimer',
      'आपातकाल',
      'एम्बुलेंस',
      'सीने में दर्द',
      'सांस नहीं आ रही',
      'দয়া করে ডাক্তার',
      'জরুরী',
      'বুকের ব্যথা',
    ];

    for (final kw in emergencyKeywords) {
      if (lower.contains(kw)) return true;
    }
    return false;
  }

  String _getConnectionFailureMessage(String langCode) {
    return _connectionFailureMessages[langCode] ??
        _connectionFailureMessages['en']!;
  }

  String _getMedicalSafetyMessage(String langCode) {
    return _medicalSafetyMessages[langCode] ?? _medicalSafetyMessages['en']!;
  }

  SupabaseClient? _resolveDefaultSupabaseClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }
}

/// Riverpod provider for IAiAssistantService
final aiAssistantServiceProvider = Provider<IAiAssistantService>((ref) {
  final connectivity = ref.watch(connectivityMonitorProvider);
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (_) {}

  return SupabaseAiAssistantService(
    supabaseClient: client,
    connectivityMonitor: connectivity,
  );
});
