// ==============================================================================
// NIRVANA - Caregiver Event Notification Service
// Description: Centralized event dispatcher creating telemetry alerts for:
// reminder_completed, reminder_missed, reminder_snoozed, game_completed,
// device_paired, device_revoked, sync_restored, sync_error.
// ==============================================================================

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../database/hive_database.dart';
import '../models/caregiver_models.dart';
import '../repositories/caregiver_notification_repository.dart';

class CaregiverEventNotificationService {
  final ICaregiverNotificationRepository _repository;
  final SupabaseClient? _client;

  CaregiverEventNotificationService({
    required ICaregiverNotificationRepository repository,
    SupabaseClient? client,
  })  : _repository = repository,
        _client = client;

  SupabaseClient? get _activeClient {
    if (_client != null) return _client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static String _generateUuid() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // Version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // Variant RFC 4122
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  /// Resolves the primary caregiver ID for a given patient
  Future<String?> _resolveCaregiverId(String patientId, {String? explicitCaregiverId}) async {
    if (explicitCaregiverId != null && explicitCaregiverId.isNotEmpty) {
      return explicitCaregiverId;
    }

    final client = _activeClient;
    final currentUser = client?.auth.currentUser;
    if (currentUser != null) {
      return currentUser.id;
    }

    if (client != null && patientId.isNotEmpty) {
      try {
        final link = await client
            .from('caregiver_patient_links')
            .select('caregiver_id')
            .eq('patient_id', patientId)
            .maybeSingle();

        if (link != null && link['caregiver_id'] != null) {
          return link['caregiver_id'] as String;
        }

        final patient = await client
            .from('patients')
            .select('primary_caregiver_id')
            .eq('id', patientId)
            .maybeSingle();

        if (patient != null && patient['primary_caregiver_id'] != null) {
          return patient['primary_caregiver_id'] as String;
        }
      } catch (e) {
        debugPrint('⚠️ Could not resolve caregiver ID from Supabase: $e');
      }
    }

    return null;
  }

  /// Resolves patient display name
  String _resolvePatientName(String? name) {
    if (name != null && name.trim().isNotEmpty) return name.trim();
    final session = HiveDatabase.currentPatientSession;
    if (session != null && session.preferredName.isNotEmpty) {
      return session.preferredName;
    }
    return 'Loved One';
  }

  // ----------------------------------------------------------------------------
  // 1. Reminder Completed Event
  // ----------------------------------------------------------------------------
  Future<void> notifyReminderCompleted({
    required String patientId,
    required String reminderTitle,
    String? reminderId,
    String? patientName,
    String? caregiverId,
  }) async {
    final cId = await _resolveCaregiverId(patientId, explicitCaregiverId: caregiverId);
    if (cId == null) return;

    final name = _resolvePatientName(patientName);
    final notification = CaregiverNotification(
      id: _generateUuid(),
      caregiverId: cId,
      patientId: patientId,
      notificationType: 'reminder_completed',
      title: 'Reminder Completed',
      message: '$name completed their "$reminderTitle" reminder.',
      relatedReminderId: reminderId,
      createdAt: DateTime.now(),
      patientName: name,
    );

    await _repository.createNotification(notification);
  }

  // ----------------------------------------------------------------------------
  // 2. Reminder Snoozed Event
  // ----------------------------------------------------------------------------
  Future<void> notifyReminderSnoozed({
    required String patientId,
    required String reminderTitle,
    required DateTime snoozedUntil,
    String? reminderId,
    String? patientName,
    String? caregiverId,
  }) async {
    final cId = await _resolveCaregiverId(patientId, explicitCaregiverId: caregiverId);
    if (cId == null) return;

    final name = _resolvePatientName(patientName);
    final local = snoozedUntil.toLocal();
    final h = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
    final p = local.hour >= 12 ? 'PM' : 'AM';
    final m = local.minute.toString().padLeft(2, '0');
    final timeStr = '$h:$m $p';

    final notification = CaregiverNotification(
      id: _generateUuid(),
      caregiverId: cId,
      patientId: patientId,
      notificationType: 'reminder_snoozed',
      title: 'Reminder Snoozed',
      message: '$name snoozed "$reminderTitle" until $timeStr.',
      relatedReminderId: reminderId,
      createdAt: DateTime.now(),
      patientName: name,
    );

    await _repository.createNotification(notification);
  }

  // ----------------------------------------------------------------------------
  // 3. Reminder Missed Event
  // ----------------------------------------------------------------------------
  Future<void> notifyReminderMissed({
    required String patientId,
    required String reminderTitle,
    required String scheduledTime,
    String? reminderId,
    String? patientName,
    String? caregiverId,
  }) async {
    final cId = await _resolveCaregiverId(patientId, explicitCaregiverId: caregiverId);
    if (cId == null) return;

    final name = _resolvePatientName(patientName);
    final notification = CaregiverNotification(
      id: _generateUuid(),
      caregiverId: cId,
      patientId: patientId,
      notificationType: 'reminder_missed',
      title: 'Missed Reminder',
      message: '$name missed their $scheduledTime "$reminderTitle" reminder.',
      relatedReminderId: reminderId,
      createdAt: DateTime.now(),
      patientName: name,
    );

    await _repository.createNotification(notification);
  }

  // ----------------------------------------------------------------------------
  // 4. Game Completed Event
  // ----------------------------------------------------------------------------
  Future<void> notifyGameCompleted({
    required String patientId,
    required String gameTitle,
    required int score,
    int? correctAnswers,
    int? totalQuestions,
    String? gameSessionId,
    String? patientName,
    String? caregiverId,
  }) async {
    final cId = await _resolveCaregiverId(patientId, explicitCaregiverId: caregiverId);
    if (cId == null) return;

    final name = _resolvePatientName(patientName);
    final scoreDetail = (correctAnswers != null && totalQuestions != null && totalQuestions > 0)
        ? ' ($correctAnswers/$totalQuestions items found)'
        : '';

    final notification = CaregiverNotification(
      id: _generateUuid(),
      caregiverId: cId,
      patientId: patientId,
      notificationType: 'game_completed',
      title: 'Activity Completed',
      message: '$name completed $gameTitle$scoreDetail.',
      relatedGameSessionId: gameSessionId,
      createdAt: DateTime.now(),
      patientName: name,
    );

    await _repository.createNotification(notification);
  }

  // ----------------------------------------------------------------------------
  // 5. Device Paired Event
  // ----------------------------------------------------------------------------
  Future<void> notifyDevicePaired({
    required String patientId,
    required String deviceName,
    String? patientName,
    String? caregiverId,
  }) async {
    final cId = await _resolveCaregiverId(patientId, explicitCaregiverId: caregiverId);
    if (cId == null) return;

    final name = _resolvePatientName(patientName);
    final notification = CaregiverNotification(
      id: _generateUuid(),
      caregiverId: cId,
      patientId: patientId,
      notificationType: 'device_paired',
      title: 'Device Paired',
      message: '$deviceName was successfully connected for $name.',
      createdAt: DateTime.now(),
      patientName: name,
    );

    await _repository.createNotification(notification);
  }

  // ----------------------------------------------------------------------------
  // 6. Device Revoked Event
  // ----------------------------------------------------------------------------
  Future<void> notifyDeviceRevoked({
    required String patientId,
    String? patientName,
    String? caregiverId,
  }) async {
    final cId = await _resolveCaregiverId(patientId, explicitCaregiverId: caregiverId);
    if (cId == null) return;

    final name = _resolvePatientName(patientName);
    final notification = CaregiverNotification(
      id: _generateUuid(),
      caregiverId: cId,
      patientId: patientId,
      notificationType: 'device_revoked',
      title: 'Device Access Revoked',
      message: 'A device connection was disconnected for $name.',
      createdAt: DateTime.now(),
      patientName: name,
    );

    await _repository.createNotification(notification);
  }

  // ----------------------------------------------------------------------------
  // 7. Sync Restored Event
  // ----------------------------------------------------------------------------
  Future<void> notifySyncRestored({
    required String patientId,
    int syncedEventCount = 0,
    String? patientName,
    String? caregiverId,
  }) async {
    final cId = await _resolveCaregiverId(patientId, explicitCaregiverId: caregiverId);
    if (cId == null) return;

    final name = _resolvePatientName(patientName);
    final countText = syncedEventCount > 0 ? ' ($syncedEventCount updates synced)' : '';

    final notification = CaregiverNotification(
      id: _generateUuid(),
      caregiverId: cId,
      patientId: patientId,
      notificationType: 'sync_restored',
      title: 'Sync Restored',
      message: 'Connection restored for $name$countText. All activity is up to date.',
      createdAt: DateTime.now(),
      patientName: name,
    );

    await _repository.createNotification(notification);
  }

  // ----------------------------------------------------------------------------
  // 8. Sync Error Event
  // ----------------------------------------------------------------------------
  Future<void> notifySyncError({
    required String patientId,
    required String errorMessage,
    String? patientName,
    String? caregiverId,
  }) async {
    final cId = await _resolveCaregiverId(patientId, explicitCaregiverId: caregiverId);
    if (cId == null) return;

    final name = _resolvePatientName(patientName);
    final notification = CaregiverNotification(
      id: _generateUuid(),
      caregiverId: cId,
      patientId: patientId,
      notificationType: 'sync_error',
      title: 'Sync Warning',
      message: 'Could not sync latest activities for $name: $errorMessage',
      createdAt: DateTime.now(),
      patientName: name,
    );

    await _repository.createNotification(notification);
  }
}
