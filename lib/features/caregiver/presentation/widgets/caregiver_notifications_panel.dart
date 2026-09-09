// ==============================================================================
// NIRVANA - Caregiver Notifications Panel Widget
// Description: Live real-time notification alert feed for caregivers. Displays
// telemetry events (reminders completed/snoozed/missed, games completed,
// device pairing/revocation, sync restoration/errors) with unread status,
// relative time, and interactive mark-as-read actions.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/features/caregiver/models/caregiver_models.dart';
import 'package:nirvana/features/caregiver/providers/caregiver_providers.dart';

class CaregiverNotificationsPanel extends ConsumerWidget {
  const CaregiverNotificationsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(caregiverNotificationsStreamProvider);
    final unreadCount = ref.watch(unreadCaregiverNotificationsCountProvider);
    final authState = ref.watch(caregiverAuthProvider);
    final caregiver = authState.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.notifications_active_outlined,
                  size: 20,
                  color: ElderColors.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Recent Alerts & Activity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ElderColors.textPrimary,
                  ),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: ElderColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$unreadCount NEW',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (unreadCount > 0 && caregiver != null)
              TextButton.icon(
                onPressed: () async {
                  await ref
                      .read(caregiverNotificationsNotifierProvider.notifier)
                      .markAllAsRead(caregiver.id);
                },
                icon: const Icon(Icons.done_all, size: 16),
                label: const Text(
                  'Mark all read',
                  style: TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: ElderColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // Notifications List or Empty State
        notificationsAsync.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ElderColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_none,
                        size: 32,
                        color: ElderColors.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No new alerts',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ElderColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Activity notifications and adherence updates will appear here in real time.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            // Show latest up to 10 notifications
            final displayList = notifications.take(10).toList();

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayList.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: Colors.grey.withValues(alpha: 0.12),
                ),
                itemBuilder: (context, index) {
                  final notification = displayList[index];
                  return _NotificationTile(notification: notification);
                },
              ),
            );
          },
          loading: () => Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.2),
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (e, _) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to load notifications: $e',
                    style: const TextStyle(fontSize: 13, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final CaregiverNotification notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUnread = !notification.isRead;
    final style = _getNotificationStyle(notification.notificationType);

    return InkWell(
      onTap: () async {
        if (isUnread) {
          await ref
              .read(caregiverNotificationsNotifierProvider.notifier)
              .markAsRead(notification.id);
        }

        if (notification.relatedReminderId != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Viewing reminder related to "${notification.title}"'),
              backgroundColor: ElderColors.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        color: isUnread
            ? style.bgColor.withValues(alpha: 0.06)
            : Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Badge
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: style.bgColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(style.icon, size: 20, color: style.iconColor),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontWeight: isUnread
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  fontSize: 14,
                                  color: ElderColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isUnread) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: ElderColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        _formatRelativeTime(notification.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight:
                              isUnread ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Message text
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: isUnread
                          ? ElderColors.textPrimary
                          : Colors.grey[700],
                    ),
                  ),

                  // Footer badges
                  if (notification.patientName != null &&
                      notification.patientName!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        notification.patientName!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static _NotificationVisual _getNotificationStyle(String type) {
    switch (type) {
      case 'reminder_completed':
        return const _NotificationVisual(
          icon: Icons.check_circle_outline,
          iconColor: Color(0xFF2E7D32),
          bgColor: Color(0xFF2E7D32),
        );
      case 'reminder_snoozed':
        return const _NotificationVisual(
          icon: Icons.snooze,
          iconColor: Color(0xFFE65100),
          bgColor: Color(0xFFE65100),
        );
      case 'reminder_missed':
        return const _NotificationVisual(
          icon: Icons.alarm_off,
          iconColor: Color(0xFFC2410C),
          bgColor: Color(0xFFC2410C),
        );
      case 'game_completed':
        return const _NotificationVisual(
          icon: Icons.emoji_events_outlined,
          iconColor: Color(0xFF7C3AED),
          bgColor: Color(0xFF7C3AED),
        );
      case 'device_paired':
        return const _NotificationVisual(
          icon: Icons.phonelink_setup,
          iconColor: ElderColors.primary,
          bgColor: ElderColors.primary,
        );
      case 'device_revoked':
        return const _NotificationVisual(
          icon: Icons.phonelink_erase,
          iconColor: Color(0xFF9A3412),
          bgColor: Color(0xFF9A3412),
        );
      case 'sync_restored':
        return const _NotificationVisual(
          icon: Icons.cloud_done_outlined,
          iconColor: Color(0xFF0F766E),
          bgColor: Color(0xFF0F766E),
        );
      case 'sync_error':
        return const _NotificationVisual(
          icon: Icons.cloud_off_outlined,
          iconColor: Color(0xFFB45309),
          bgColor: Color(0xFFB45309),
        );
      default:
        return const _NotificationVisual(
          icon: Icons.notifications_outlined,
          iconColor: ElderColors.primary,
          bgColor: ElderColors.primary,
        );
    }
  }

  static String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 45) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      final local = dateTime.toLocal();
      final h = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
      final p = local.hour >= 12 ? 'PM' : 'AM';
      final m = local.minute.toString().padLeft(2, '0');
      return 'Yesterday $h:$m $p';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      final local = dateTime.toLocal();
      return '${local.month}/${local.day}/${local.year}';
    }
  }
}

class _NotificationVisual {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _NotificationVisual({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
}
