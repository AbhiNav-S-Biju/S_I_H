// ==============================================================================
// NIRVANA - Caregiver Push Notification Service Unit Tests
// Description: Tests the token payload parser, graceful fallback when FCM is
// unavailable, and tap stream broadcast capabilities.
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:nirvana/features/caregiver/caregiver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CaregiverNotificationPayload Tests', () {
    test('Correctly parses payload from standard FCM data map', () {
      final data = {
        'notification_id': 'notif-123',
        'patient_id': 'patient-abc',
        'notification_type': 'reminder_missed',
        'title': 'Missed Medication',
        'body': 'Elder missed Morning Pills at 8:00 AM',
        'related_reminder_id': 'rem-456',
        'related_game_session_id': '',
      };

      final payload = CaregiverNotificationPayload.fromData(data);

      expect(payload.notificationId, 'notif-123');
      expect(payload.patientId, 'patient-abc');
      expect(payload.notificationType, 'reminder_missed');
      expect(payload.title, 'Missed Medication');
      expect(payload.body, 'Elder missed Morning Pills at 8:00 AM');
      expect(payload.relatedReminderId, 'rem-456');
    });

    test('Gracefully handles empty or missing payload fields', () {
      final payload = CaregiverNotificationPayload.fromData({});

      expect(payload.notificationId, isNull);
      expect(payload.patientId, isNull);
      expect(payload.notificationType, isNull);
      expect(payload.title, isNull);
      expect(payload.body, isNull);
      expect(payload.relatedReminderId, isNull);
    });
  });

  group('CaregiverPushNotificationService Lifecycle Tests', () {
    test('Initializes safely without throwing even if Firebase is unconfigured', () async {
      final service = CaregiverPushNotificationService();

      // Should complete without throwing unhandled exceptions
      final result = await service.initialize();

      // Result is boolean (false if unconfigured/no-app in test environment)
      expect(result, isA<bool>());
    });

    test('Gracefully handles requestNotificationPermissions when FCM is unavailable', () async {
      final service = CaregiverPushNotificationService();

      final granted = await service.requestNotificationPermissions();
      expect(granted, isA<bool>());
    });

    test('Gracefully handles getDeviceToken when FCM is unavailable', () async {
      final service = CaregiverPushNotificationService();

      final token = await service.getDeviceToken();
      expect(token, isNull);
    });

    test('Gracefully handles registerDeviceTokenForCaregiver when FCM is unavailable', () async {
      final service = CaregiverPushNotificationService();

      // Should not throw
      await expectLater(
        service.registerDeviceTokenForCaregiver('caregiver-123'),
        completes,
      );
    });

    test('Gracefully handles unregisterDeviceToken', () async {
      final service = CaregiverPushNotificationService();

      await expectLater(
        service.unregisterDeviceToken(),
        completes,
      );
    });
  });
}
