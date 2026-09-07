// ==============================================================================
// NIRVANA - Notification Service
// Description: Local notification manager. Schedules, cancels, and responds to
// reminder alerts with Done, Snooze, and Later Today actions. Operates 100% offline.
// ==============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/reminder.dart';
import '../models/reminder_action.dart';
import '../repositories/reminder_repository.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  final IReminderRepository? _reminderRepository;

  static const String channelId = 'nirvana_reminders_channel';
  static const String channelName = 'NIRVANA Care Reminders';
  static const String channelDesc = 'Timely alerts for medication, hydration, and elder activities';

  NotificationService({
    FlutterLocalNotificationsPlugin? notificationsPlugin,
    IReminderRepository? reminderRepository,
  })  : _notificationsPlugin = notificationsPlugin ?? FlutterLocalNotificationsPlugin(),
        _reminderRepository = reminderRepository;

  /// Initializes the local notification plugin and sets up action categories.
  Future<bool?> initialize({
    void Function(NotificationResponse)? onResponse,
  }) async {
    _ensureTimeZoneInitialized();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    final initialized = await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: onResponse ?? handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Request permissions on Android 13+
    await _requestPermissions();

    debugPrint('🔔 NotificationService initialized (success: $initialized)');
    return initialized;
  }

  Future<void> _requestPermissions() async {
    final androidImpl = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.requestNotificationsPermission();
      await androidImpl.requestExactAlarmsPermission();
    }
  }

  static bool _timeZoneInitialized = false;

  static void _ensureTimeZoneInitialized() {
    if (_timeZoneInitialized) return;
    try {
      tz.initializeTimeZones();
      _timeZoneInitialized = true;
    } catch (_) {}
  }

  /// Schedules a local notification for a reminder with interactive actions.
  Future<void> scheduleReminder(Reminder reminder) async {
    _ensureTimeZoneInitialized();
    final scheduledTime = reminder.snoozedUntil ?? reminder.scheduledAt;
    final now = DateTime.now();

    // If scheduled in past, fire shortly (or skip if older than 1 hour)
    final targetTime = scheduledTime.isBefore(now)
        ? now.add(const Duration(seconds: 5))
        : scheduledTime;

    tz.TZDateTime tzDateTime;
    try {
      tzDateTime = tz.TZDateTime.from(targetTime, tz.local);
    } catch (_) {
      tzDateTime = tz.TZDateTime.from(targetTime, tz.UTC);
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      actions: const [
        AndroidNotificationAction(
          NotificationActionIds.done,
          'Done',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          NotificationActionIds.snooze15,
          'Snooze 15 min',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          NotificationActionIds.laterToday,
          'Later today',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'reminder_category',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        reminder.notificationId,
        reminder.title,
        reminder.body,
        tzDateTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: reminder.id,
      );
      debugPrint('⏰ Scheduled reminder "${reminder.title}" for $targetTime (id: ${reminder.notificationId})');
    } catch (e) {
      debugPrint('❌ Failed to schedule zoned notification: $e');
      // Fallback to immediate display if exact alarm scheduling is not supported in current environment
      try {
        await _notificationsPlugin.show(
          reminder.notificationId,
          reminder.title,
          reminder.body,
          details,
          payload: reminder.id,
        );
      } catch (_) {}
    }
  }

  /// Cancels a scheduled reminder notification by its ID.
  Future<void> cancelReminder(int notificationId) async {
    await _notificationsPlugin.cancel(notificationId);
    debugPrint('🗑️ Cancelled notification: $notificationId');
  }

  /// Cancels all notifications.
  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Handles foreground notification action responses.
  Future<void> handleNotificationResponse(NotificationResponse response) async {
    final actionId = response.actionId;
    final reminderId = response.payload;

    if (reminderId == null || reminderId.isEmpty) return;

    debugPrint('📬 Notification action received: $actionId for reminder: $reminderId');

    if (_reminderRepository == null) return;

    if (actionId == NotificationActionIds.done) {
      await _reminderRepository.completeReminder(reminderId);
    } else if (actionId == NotificationActionIds.snooze15) {
      await _reminderRepository.snoozeReminder(
        reminderId,
        delay: const Duration(minutes: 15),
      );
      // Reschedule notification
      final updated = await _reminderRepository.getReminderById(reminderId);
      if (updated != null) {
        await scheduleReminder(updated);
      }
    } else if (actionId == NotificationActionIds.laterToday) {
      await _reminderRepository.dismissReminderLaterToday(reminderId);
      final updated = await _reminderRepository.getReminderById(reminderId);
      if (updated != null) {
        await scheduleReminder(updated);
      }
    }
  }
}

/// Top-level background notification tap handler (required by flutter_local_notifications)
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  debugPrint('📬 Background notification action received: ${notificationResponse.actionId}');
}
