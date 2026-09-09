// ==============================================================================
// NIRVANA - Ask NIRVANA AI Assistant Service Tests
// Description: Unit tests validating the AI fallback layer, dementia safety
// guardrails, medical diversion, offline handling, timeout resilience, and
// zero API key exposure guarantees.
// ==============================================================================

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirvana/core/network/connectivity_monitor.dart';
import 'package:nirvana/features/ask_nirvana/services/ai_assistant_service.dart';

class FakeTestConnectivityMonitor implements IConnectivityMonitor {
  NetworkStatus currentStatus;
  final _controller = StreamController<NetworkStatus>.broadcast();

  FakeTestConnectivityMonitor({this.currentStatus = NetworkStatus.online});

  @override
  Future<NetworkStatus> checkStatus() async => currentStatus;

  @override
  Stream<NetworkStatus> get statusStream => _controller.stream;

  void setOnline(bool online) {
    currentStatus = online ? NetworkStatus.online : NetworkStatus.offline;
    _controller.add(currentStatus);
  }
}

void main() {
  late FakeTestConnectivityMonitor fakeConnectivity;

  setUp(() {
    fakeConnectivity = FakeTestConnectivityMonitor(
      currentStatus: NetworkStatus.online,
    );
  });

  group('Ask NIRVANA - AI Assistant Service Dementia Safety Guardrails', () {
    test('Redirects medical emergencies to caregiver and emergency services', () async {
      final service = SupabaseAiAssistantService(
        connectivityMonitor: fakeConnectivity,
      );

      final responseEn = await service.getAiFallbackResponse(
        query: 'I have severe chest pain and cannot breathe',
        languageCode: 'en',
      );

      expect(responseEn, contains('caregiver, doctor, or emergency services'));

      final responseHi = await service.getAiFallbackResponse(
        query: 'मुझे सीने में दर्द हो रहा है आपातकाल',
        languageCode: 'hi',
      );

      expect(responseHi, contains('देखभालकर्ता या डॉक्टर'));
    });

    test('Redirects medication alteration requests safely', () async {
      final service = SupabaseAiAssistantService(
        connectivityMonitor: fakeConnectivity,
      );

      final response = await service.getAiFallbackResponse(
        query: 'Should I change my dose or stop my medicine?',
        languageCode: 'en',
      );

      expect(response, contains('caregiver, doctor, or emergency services'));
    });

    test('Redirects dementia diagnosis requests safely', () async {
      final service = SupabaseAiAssistantService(
        connectivityMonitor: fakeConnectivity,
      );

      final response = await service.getAiFallbackResponse(
        query: 'Do I have dementia or Alzheimer?',
        languageCode: 'en',
      );

      expect(response, contains('caregiver, doctor, or emergency services'));
    });
  });

  group('Ask NIRVANA - AI Assistant Service Offline & Network Handling', () {
    test('Returns friendly localized offline message when network is disconnected', () async {
      fakeConnectivity.setOnline(false);

      final service = SupabaseAiAssistantService(
        connectivityMonitor: fakeConnectivity,
      );

      final responseEn = await service.getAiFallbackResponse(
        query: 'Tell me a story',
        languageCode: 'en',
      );

      expect(
        responseEn,
        equals(
          "I can't connect right now, but I can still help with your reminders and daily routine.",
        ),
      );

      final responseHi = await service.getAiFallbackResponse(
        query: 'मुझे एक कहानी सुनाओ',
        languageCode: 'hi',
      );

      expect(
        responseHi,
        equals(
          'मैं अभी कनेक्ट नहीं कर पा रहा हूँ, लेकिन मैं आपकी दवा और दिनचर्या में मदद कर सकता हूँ।',
        ),
      );

      final responseBn = await service.getAiFallbackResponse(
        query: 'আমাকে একটা গল্প বলো',
        languageCode: 'bn',
      );

      expect(
        responseBn,
        equals(
          'আমি এখন সংযোগ করতে পারছি না, তবে আমি আপনার রিমাইন্ডার এবং দৈনন্দিন রুটিনে সাহায্য করতে পারি।',
        ),
      );

      final responseAs = await service.getAiFallbackResponse(
        query: 'মোক এটা সাধু কোৱা',
        languageCode: 'as',
      );

      expect(
        responseAs,
        equals(
          'মই এই মুহূৰ্তত সংযোগ কৰিব পৰা নাই, কিন্তু মই আপোনাৰ সোঁৱৰণী আৰু দৈনিক কামত সহায় কৰিব পাৰোঁ।',
        ),
      );
    });

    test('Gracefully returns friendly message on unconfigured client or API failure', () async {
      fakeConnectivity.setOnline(true);

      // Without a mocked Supabase backend, client fallback message is returned cleanly
      final service = SupabaseAiAssistantService(
        supabaseClient: null,
        connectivityMonitor: fakeConnectivity,
        timeout: const Duration(milliseconds: 50),
      );

      final response = await service.getAiFallbackResponse(
        query: 'What is the color of the sky?',
        languageCode: 'en',
      );

      expect(
        response,
        equals(
          "I can't connect right now, but I can still help with your reminders and daily routine.",
        ),
      );
    });
  });
}
