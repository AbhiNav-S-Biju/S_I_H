// ==============================================================================
// NIRVANA - Notification Service
// Description: Local notification manager. Schedules, cancels, and responds to
// reminder alerts with Done, Snooze, and Later Today actions. Operates 100% offline.
// ==============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../../database/hive_boxes.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../l10n/generated/app_localizations_en.dart';
import '../models/reminder.dart';
import '../models/reminder_action.dart';
import '../repositories/reminder_repository.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  final IReminderRepository? _reminderRepository;

  static const String channelId = 'nirvana_reminders_channel';

  /// Fallback channel copy used before localizations resolve.
  static const String channelName = 'NIRVANA Care Reminders';
  static const String channelDesc =
      'Timely alerts for medication, hydration, and elder activities';

  /// Resolves the [AppLocalizations] for the language the elder has chosen in
  /// Settings (persisted in Hive), so notification copy matches the in-app
  /// language. Falls back to English when the locale is unavailable.
  static AppLocalizations _localizations() {
    try {
      if (Hive.isBoxOpen(HiveBoxes.settings)) {
        final code =
            Hive.box<dynamic>(HiveBoxes.settings).get(
              HiveBoxes.settingsKeyLocale,
            )
            as String?;
        if (code != null && code.isNotEmpty && code != 'en') {
          return lookupAppLocalizations(Locale(code));
        }
      }
    } catch (_) {}
    return AppLocalizationsEn();
  }

  /// Deterministic mapping from a reminder id to the integer notification id
  /// used to schedule/cancel its alarm. Every scheduler must use this so a
  /// cancel always targets the exact alarm that was scheduled.
  static int notificationIdFor(String reminderId) =>
      reminderId.hashCode.abs() % 100000;

  NotificationService({
    FlutterLocalNotificationsPlugin? notificationsPlugin,
    IReminderRepository? reminderRepository,
  }) : _notificationsPlugin =
           notificationsPlugin ?? FlutterLocalNotificationsPlugin(),
       _reminderRepository = reminderRepository;

  /// Initializes the local notification plugin and sets up action categories.
  Future<bool?> initialize({
    void Function(NotificationResponse)? onResponse,
  }) async {
    _ensureTimeZoneInitialized();

    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS &&
            defaultTargetPlatform != TargetPlatform.macOS)) {
      debugPrint(
        '🔔 NotificationService: Local notifications skipped on ${defaultTargetPlatform.name} (desktop/web). Operating in standard UI mode.',
      );
      return false;
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
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
      onDidReceiveNotificationResponse:
          onResponse ?? handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Request permissions on Android 13+
    await _requestPermissions();

    debugPrint('🔔 NotificationService initialized (success: $initialized)');
    return initialized;
  }

  Future<void> _requestPermissions() async {
    final androidImpl = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
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
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
      _timeZoneInitialized = true;
    } catch (_) {}
  }

  /// Schedules a local notification for a reminder with interactive actions.
  ///
  /// The alarm fires **only** at the exact time chosen when the alarm was set
  /// (`scheduledAt`, or `snoozedUntil` when snoozed). A reminder whose time has
  /// already passed is intentionally NOT fired immediately — otherwise merely
  /// opening the dashboard would re-raise old alarms. Past reminders are left
  /// for the caregiver "missed" flow; upcoming ones are scheduled to the second.
  Future<void> scheduleReminder(Reminder reminder) async {
    _ensureTimeZoneInitialized();
    final scheduledTime = reminder.snoozedUntil ?? reminder.scheduledAt;
    final now = DateTime.now();

    if (!scheduledTime.isAfter(now)) {
      debugPrint(
        '⏭️ Skipping "${reminder.title}": scheduled time $scheduledTime is in the past.',
      );
      // Ensure no stale copy of this alarm is still queued.
      await cancelReminder(reminder.notificationId);
      return;
    }

    final targetTime = scheduledTime;

    tz.TZDateTime tzDateTime;
    try {
      tzDateTime = tz.TZDateTime.from(targetTime, tz.local);
    } catch (_) {
      try {
        tzDateTime = tz.TZDateTime.from(targetTime, tz.UTC);
      } catch (_) {
        tzDateTime = tz.TZDateTime.utc(
          targetTime.year,
          targetTime.month,
          targetTime.day,
          targetTime.hour,
          targetTime.minute,
          targetTime.second,
        );
      }
    }

    final l10n = _localizations();
    final androidDetails = AndroidNotificationDetails(
      channelId,
      l10n.notificationChannelName,
      channelDescription: l10n.notificationChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      // Play a sound (and vibrate) so the alarm is heard even if the elder is
      // not looking at the screen. Leaving `sound` unspecified uses the
      // device's default notification tone (no custom asset required).
      playSound: true,
      enableVibration: true,
      autoCancel: true,
      ongoing: false,
      actions: [
        AndroidNotificationAction(
          NotificationActionIds.done,
          l10n.notificationActionDone,
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          NotificationActionIds.snooze15,
          l10n.notificationActionSnooze,
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          NotificationActionIds.laterToday,
          l10n.notificationActionLaterToday,
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
      debugPrint(
        '⏰ Scheduled reminder "${reminder.title}" for $targetTime (id: ${reminder.notificationId})',
      );
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

  /// Cancels the alarm for [reminderId], preferring the id that was actually
  /// used when scheduling (from the stored reminder) and falling back to the
  /// deterministic derivation. Never throws — cancelling is best-effort.
  Future<void> _safeCancel(String reminderId) async {
    var notificationId = notificationIdFor(reminderId);
    if (_reminderRepository != null) {
      try {
        final reminder = await _reminderRepository.getReminderById(reminderId);
        if (reminder != null) notificationId = reminder.notificationId;
      } catch (_) {}
    }
    try {
      await cancelReminder(notificationId);
    } catch (e) {
      debugPrint('⚠️ Could not cancel notification $notificationId: $e');
    }
  }

  /// (Re)schedules local notifications for every active reminder of a patient.
  ///
  /// Reminders are normally scheduled only when a caregiver creates them. A
  /// patient device that syncs reminders down (or a fresh install) would
  /// otherwise never fire a popup, so this reconciles the device's scheduled
  /// alarms with its local reminders. Safe to call on every dashboard load:
  /// scheduling the same notification id simply replaces the previous entry.
  Future<void> rescheduleAllForPatient(Iterable<Reminder> reminders) async {
    for (final reminder in reminders) {
      if (!reminder.isActive || reminder.isCompleted) continue;
      await scheduleReminder(reminder);
    }
  }

  /// Cancels all notifications.
  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Handles foreground notification action responses.
  ///
  /// Handles the four ways a patient can respond to an alarm:
  ///  * tap the notification body / close it (actionId is empty) → treat as
  ///    done: silence the alarm, mark the reminder complete, and tell the
  ///    caregiver portal. This is what "disabled when the patient closes the
  ///    alarm" means — closing the popup stops the sound and records completion.
  ///  * "Done" → same as closing.
  ///  * "Snooze 15 min" → re-arm the alarm 15 minutes later.
  ///  * "Later today" → re-arm the alarm later the same day.
  Future<void> handleNotificationResponse(NotificationResponse response) async {
    final actionId = response.actionId;
    final reminderId = response.payload;

    if (reminderId == null || reminderId.isEmpty) return;

    debugPrint(
      '📬 Notification action received: $actionId for reminder: $reminderId',
    );

    // Closing / tapping the alarm (no action button) counts as acknowledged.
    final isAcknowledged =
        actionId == null ||
        actionId.isEmpty ||
        actionId == NotificationActionIds.done;

    if (isAcknowledged) {
      // Stop the alarm sound immediately. Best-effort: a plugin failure (e.g. in
      // tests or on desktop) must never block recording the completion.
      await _safeCancel(reminderId);
    }

    if (_reminderRepository == null) return;

    if (isAcknowledged) {
      // Marks the reminder complete, logs adherence, queues the sync event and
      // dispatches a "reminder_completed" notification to the caregiver portal.
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

/// Top-level background notification tap handler (required by
/// flutter_local_notifications). Runs in a separate isolate when the app is not
/// in the foreground.
///
/// This at minimum silences the alarm (cancels the notification) so closing it
/// from the lock screen stops the sound. The full completion + caregiver update
/// happens in the foreground handler once the app resumes.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) async {
  debugPrint(
    '📬 Background notification action received: ${notificationResponse.actionId}',
  );

  final reminderId = notificationResponse.payload;
  if (reminderId != null && reminderId.isNotEmpty) {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      await plugin.cancel(NotificationService.notificationIdFor(reminderId));
    } catch (e) {
      debugPrint('⚠️ Could not cancel background notification: $e');
    }
  }
}
