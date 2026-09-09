// ==============================================================================
// NIRVANA - Caregiver Notification Repository Contract
// Description: Defines operations for fetching real-time caregiver alerts,
// creating telemetry event notifications, and managing read/unread state.
// ==============================================================================

import '../models/caregiver_models.dart';

abstract class ICaregiverNotificationRepository {
  /// Fetches historical notifications for a caregiver, optionally scoped to a patient.
  Future<List<CaregiverNotification>> getNotifications(
    String caregiverId, {
    String? patientId,
    int limit = 100,
  });

  /// Real-time stream of notifications for a caregiver.
  Stream<List<CaregiverNotification>> getNotificationsStream(
    String caregiverId, {
    String? patientId,
  });

  /// Inserts a new notification (when an activity or adherence event occurs).
  Future<void> createNotification(CaregiverNotification notification);

  /// Marks a specific notification as read.
  Future<void> markAsRead(String notificationId);

  /// Marks all notifications for a caregiver as read.
  Future<void> markAllAsRead(String caregiverId);

  /// Returns the current count of unread notifications.
  Future<int> getUnreadCount(String caregiverId);
}
