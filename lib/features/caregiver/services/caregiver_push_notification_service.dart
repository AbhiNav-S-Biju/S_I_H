// ==============================================================================
// NIRVANA - Caregiver Push Notification Service
// Description: Manages Firebase Cloud Messaging (FCM) lifecycle for caregiver alerts.
// Handles FCM token registration, notification permission requests, foreground
// presentation via FlutterLocalNotifications, background message dispatch,
// and notification tap deep linking.
//
// DESIGN PRINCIPLE:
// - Gracefully falls back when FCM is unconfigured or unavailable.
// - Never crashes if Firebase / google-services.json is absent.
// - In-app notification feed remains the definitive source of truth.
// ==============================================================================

import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Top-level background message handler required by Firebase Messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // Ensure Firebase is initialized for background isolate if possible
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('⚠️ Background isolate Firebase init: $e');
  }

  debugPrint(
    '📬 Caregiver Background Push Notification: ${message.messageId} | '
    'Title: ${message.notification?.title} | Type: ${message.data['notification_type']}',
  );
}

/// Payload model for notification tap actions and deep linking
class CaregiverNotificationPayload {
  final String? notificationId;
  final String? patientId;
  final String? notificationType;
  final String? title;
  final String? body;
  final String? relatedReminderId;
  final String? relatedGameSessionId;
  final Map<String, dynamic> rawData;

  const CaregiverNotificationPayload({
    this.notificationId,
    this.patientId,
    this.notificationType,
    this.title,
    this.body,
    this.relatedReminderId,
    this.relatedGameSessionId,
    this.rawData = const {},
  });

  factory CaregiverNotificationPayload.fromData(
    Map<String, dynamic> data, {
    String? title,
    String? body,
  }) {
    return CaregiverNotificationPayload(
      notificationId: data['notification_id']?.toString(),
      patientId: data['patient_id']?.toString(),
      notificationType: data['notification_type']?.toString(),
      title: title ?? data['title']?.toString(),
      body: body ?? data['body']?.toString(),
      relatedReminderId: data['related_reminder_id']?.toString(),
      relatedGameSessionId: data['related_game_session_id']?.toString(),
      rawData: data,
    );
  }
}

class CaregiverPushNotificationService {
  static final CaregiverPushNotificationService _instance =
      CaregiverPushNotificationService._internal();

  factory CaregiverPushNotificationService() => _instance;

  CaregiverPushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'nirvana_caregiver_alerts';
  static const String channelName = 'NIRVANA Caregiver Alerts';
  static const String channelDescription =
      'Real-time alerts for medication adherence, game activity, and patient status.';

  bool _isInitialized = false;
  bool _isFirebaseAvailable = false;
  String? _currentToken;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;

  // Stream controller for tapped notifications to drive UI deep-linking
  final StreamController<CaregiverNotificationPayload> _notificationTapController =
      StreamController<CaregiverNotificationPayload>.broadcast();

  Stream<CaregiverNotificationPayload> get onNotificationTapped =>
      _notificationTapController.stream;

  bool get isAvailable => _isFirebaseAvailable;
  String? get currentFcmToken => _currentToken;

  /// Safely initializes Firebase and FCM listeners.
  /// Does NOT throw or block app startup if Firebase is unconfigured.
  Future<bool> initialize() async {
    if (_isInitialized) return _isFirebaseAvailable;

    try {
      // 1. Initialize Firebase App if not already initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _isFirebaseAvailable = true;
      debugPrint('✅ Firebase initialized successfully for push notifications.');
    } catch (e) {
      _isFirebaseAvailable = false;
      debugPrint(
        'ℹ️ Firebase not configured or unavailable on this platform ($e). '
        'Push notifications disabled. In-app realtime feed will be used.',
      );
      _isInitialized = true;
      return false;
    }

    try {
      // 2. Set up background messaging handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 3. Initialize high-priority local notification channel for foreground display
      await _setupLocalNotificationChannel();

      // 4. Listen to foreground FCM messages
      _foregroundMessageSubscription =
          FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 5. Listen to notification click when app is opened from background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🔔 App opened from background push notification: ${message.data}');
        final payload = CaregiverNotificationPayload.fromData(
          message.data,
          title: message.notification?.title,
          body: message.notification?.body,
        );
        _notificationTapController.add(payload);
      });

      // 6. Check if app was opened directly from a terminated state notification
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🔔 App launched from terminated state push notification: ${initialMessage.data}');
        final payload = CaregiverNotificationPayload.fromData(
          initialMessage.data,
          title: initialMessage.notification?.title,
          body: initialMessage.notification?.body,
        );
        // Delay slightly to let router and UI listeners attach
        Future.delayed(const Duration(milliseconds: 500), () {
          _notificationTapController.add(payload);
        });
      }

      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('⚠️ Error setting up FCM listeners: $e');
      _isInitialized = true;
      return false;
    }
  }

  /// Sets up Android notification channel and local notification response handling
  Future<void> _setupLocalNotificationChannel() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final uri = Uri.splitQueryString(response.payload!);
            final payload = CaregiverNotificationPayload.fromData(uri);
            _notificationTapController.add(payload);
          } catch (e) {
            debugPrint('⚠️ Error parsing local notification payload: $e');
          }
        }
      },
    );

    // Create high-importance Android notification channel
    const androidChannel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final androidImpl = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(androidChannel);
    }
  }

  /// Request push notification permissions (Android 13+ & iOS)
  Future<bool> requestNotificationPermissions() async {
    if (!_isFirebaseAvailable) return false;

    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      debugPrint('🔔 FCM Notification Permission Status: ${settings.authorizationStatus}');
      return granted;
    } catch (e) {
      debugPrint('⚠️ Error requesting FCM permissions: $e');
      return false;
    }
  }

  /// Retrieves the device FCM push token safely
  Future<String?> getDeviceToken() async {
    if (!_isFirebaseAvailable) return null;

    try {
      _currentToken = await FirebaseMessaging.instance.getToken();
      return _currentToken;
    } catch (e) {
      debugPrint('⚠️ Error getting FCM device token: $e');
      return null;
    }
  }

  /// Synchronizes the device FCM token with the backend (Supabase)
  Future<void> registerDeviceTokenForCaregiver(String caregiverId) async {
    if (!_isFirebaseAvailable || caregiverId.isEmpty) return;

    try {
      final token = await getDeviceToken();
      if (token == null || token.isEmpty) {
        debugPrint('⚠️ No FCM token available to register.');
        return;
      }

      final client = Supabase.instance.client;
      final platformStr = defaultTargetPlatform.name.toLowerCase();

      // Register or update token in caregiver_push_tokens table
      try {
        await client.rpc('register_caregiver_push_token', params: {
          'p_fcm_token': token,
          'p_device_platform': platformStr,
          'p_device_name': 'Caregiver Device ($platformStr)',
        });
        debugPrint('✅ FCM device token synced with Supabase for caregiver: $caregiverId');
      } catch (rpcError) {
        // Fallback to direct upsert if RPC is not yet created in the database
        debugPrint('ℹ️ RPC fallback to direct upsert for push token: $rpcError');
        await client.from('caregiver_push_tokens').upsert({
          'caregiver_id': caregiverId,
          'fcm_token': token,
          'device_platform': platformStr,
          'device_name': 'Caregiver Device ($platformStr)',
          'is_active': true,
          'last_used_at': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'caregiver_id, fcm_token');
        debugPrint('✅ FCM token registered via direct upsert.');
      }

      // Listen for token rotations
      _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription =
          FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        _currentToken = newToken;
        try {
          await client.rpc('register_caregiver_push_token', params: {
            'p_fcm_token': newToken,
            'p_device_platform': platformStr,
            'p_device_name': 'Caregiver Device ($platformStr)',
          });
          debugPrint('🔄 FCM token refreshed and synced with Supabase.');
        } catch (e) {
          debugPrint('⚠️ Error updating refreshed FCM token: $e');
        }
      });
    } catch (e) {
      debugPrint('⚠️ Error in registerDeviceTokenForCaregiver: $e');
    }
  }

  /// Deactivates push token upon logout
  Future<void> unregisterDeviceToken() async {
    if (!_isFirebaseAvailable || _currentToken == null) return;

    try {
      final token = _currentToken!;
      _tokenRefreshSubscription?.cancel();
      _currentToken = null;

      final client = Supabase.instance.client;
      try {
        await client.rpc('deactivate_caregiver_push_token', params: {
          'p_fcm_token': token,
        });
      } catch (_) {
        await client
            .from('caregiver_push_tokens')
            .update({'is_active': false})
            .eq('fcm_token', token);
      }
      debugPrint('🔕 FCM token unregistered on logout.');
    } catch (e) {
      debugPrint('⚠️ Error unregistering FCM token: $e');
    }
  }

  /// Handles foreground notification display via FlutterLocalNotifications
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint(
      '🔔 Foreground FCM Push Message received: '
      'Title: ${message.notification?.title} | Body: ${message.notification?.body}',
    );

    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'NIRVANA Alert';
    final body = notification?.body ?? message.data['message'] ?? 'New caregiver notification';

    // Build payload query string for tap callback
    final queryMap = <String, String>{
      if (message.data['notification_id'] != null)
        'notification_id': message.data['notification_id'].toString(),
      if (message.data['patient_id'] != null)
        'patient_id': message.data['patient_id'].toString(),
      if (message.data['notification_type'] != null)
        'notification_type': message.data['notification_type'].toString(),
      if (message.data['related_reminder_id'] != null)
        'related_reminder_id': message.data['related_reminder_id'].toString(),
      if (message.data['related_game_session_id'] != null)
        'related_game_session_id': message.data['related_game_session_id'].toString(),
      'title': title,
      'body': body,
    };
    final payloadString = Uri(queryParameters: queryMap).query;

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      showWhen: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    await _localNotifications.show(
      id,
      title,
      body,
      details,
      payload: payloadString,
    );
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _foregroundMessageSubscription?.cancel();
    _notificationTapController.close();
  }
}
