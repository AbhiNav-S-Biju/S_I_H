// ==============================================================================
// NIRVANA - Caregiver Notifications Panel Widget
// Description: Live real-time notification alert feed for caregivers with
// claymorphic design and high-contrast readability.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/app/widgets/widgets.dart';
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
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_active_rounded,
                    size: 22,
                    color: ElderColors.clayLavender,
                  ),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: Text(
                      'Recent Alerts & Activities',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: ElderColors.textPrimary,
                      ),
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
                        color: ElderColors.clayPeach,
                        borderRadius: BorderRadius.circular(NirvanaRadii.pill),
                      ),
                      child: Text(
                        '$unreadCount NEW',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (unreadCount > 0 && caregiver != null)
              TextButton.icon(
                onPressed: () async {
                  await ref
                      .read(caregiverNotificationsNotifierProvider.notifier)
                      .markAllAsRead(caregiver.id);
                },
                icon: const Icon(Icons.done_all_rounded, size: 16),
                label: const Text(
                  'Mark all read',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: ElderColors.clayLavender,
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
              return ElderCard(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 20,
                ),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ElderColors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          size: 32,
                          color: ElderColors.clayLavender,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'No recent alerts',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: ElderColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Everything looks good.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: ElderColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final displayList = notifications.take(10).toList();

            return ElderCard(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayList.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFF1EDE6)),
                itemBuilder: (context, index) {
                  final notification = displayList[index];
                  return _NotificationTile(notification: notification);
                },
              ),
            );
          },
          loading: () => const ElderCard(
            padding: EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(color: ElderColors.clayLavender),
            ),
          ),
          error: (e, _) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ElderColors.clayPeach.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ElderColors.clayPeach),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFC2410C),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to load notifications: $e',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9A3412),
                    ),
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
              content: Text(
                'Viewing reminder related to "${notification.title}"',
              ),
              backgroundColor: ElderColors.clayLavender,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isUnread
              ? style.bgColor.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Badge
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: style.bgColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
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
                                      ? FontWeight.w900
                                      : FontWeight.w700,
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
                                  color: ElderColors.clayLavender,
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
                          color: ElderColors.textMuted,
                          fontWeight: isUnread
                              ? FontWeight.w700
                              : FontWeight.normal,
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
                          : ElderColors.textSecondary,
                    ),
                  ),

                  // Footer badges
                  if (notification.patientName != null &&
                      notification.patientName!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1EDE6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        notification.patientName!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: ElderColors.textSecondary,
                          fontWeight: FontWeight.w600,
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
          icon: Icons.check_circle_outline_rounded,
          iconColor: ElderColors.claySage,
          bgColor: ElderColors.claySage,
        );
      case 'reminder_snoozed':
        return const _NotificationVisual(
          icon: Icons.snooze_rounded,
          iconColor: ElderColors.clayButtercup,
          bgColor: ElderColors.clayButtercup,
        );
      case 'reminder_missed':
        return const _NotificationVisual(
          icon: Icons.alarm_off_rounded,
          iconColor: ElderColors.clayPeach,
          bgColor: ElderColors.clayPeach,
        );
      case 'game_completed':
        return const _NotificationVisual(
          icon: Icons.emoji_events_outlined,
          iconColor: ElderColors.clayLavender,
          bgColor: ElderColors.clayLavender,
        );
      case 'device_paired':
        return const _NotificationVisual(
          icon: Icons.phonelink_setup_rounded,
          iconColor: ElderColors.clayLavender,
          bgColor: ElderColors.clayLavender,
        );
      case 'device_revoked':
        return const _NotificationVisual(
          icon: Icons.phonelink_erase_rounded,
          iconColor: ElderColors.clayPeach,
          bgColor: ElderColors.clayPeach,
        );
      case 'sync_restored':
        return const _NotificationVisual(
          icon: Icons.cloud_done_rounded,
          iconColor: ElderColors.claySage,
          bgColor: ElderColors.claySage,
        );
      case 'sync_error':
        return const _NotificationVisual(
          icon: Icons.cloud_off_rounded,
          iconColor: ElderColors.clayButtercup,
          bgColor: ElderColors.clayButtercup,
        );
      default:
        return const _NotificationVisual(
          icon: Icons.notifications_outlined,
          iconColor: ElderColors.clayLavender,
          bgColor: ElderColors.clayLavender,
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
      final h = local.hour > 12
          ? local.hour - 12
          : (local.hour == 0 ? 12 : local.hour);
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
