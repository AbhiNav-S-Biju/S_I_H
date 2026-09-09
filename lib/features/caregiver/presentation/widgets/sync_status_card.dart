// ==============================================================================
// NIRVANA - Sync Status Card Widget
// Description: Displays network state, pending sync queue count, and cloud sync status.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/app/widgets/widgets.dart';
import 'package:nirvana/features/caregiver/providers/caregiver_providers.dart';

class SyncStatusCard extends ConsumerWidget {
  const SyncStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncAsync = ref.watch(caregiverSyncStatusProvider);

    return syncAsync.when(
      data: (info) {
        final isOnline = info.isOnline;
        final hasPending = info.pendingEventsCount > 0;

        Color badgeColor = isOnline
            ? (hasPending ? ElderColors.clayButtercup : ElderColors.claySage)
            : ElderColors.clayPeach;

        IconData statusIcon = isOnline
            ? (hasPending ? Icons.sync_rounded : Icons.cloud_done_rounded)
            : Icons.cloud_off_rounded;

        return ElderCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          backgroundColor: ElderColors.surface,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  boxShadow: NirvanaShadows.float(tint: badgeColor),
                ),
                child: Icon(statusIcon, color: badgeColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Sync status: ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: badgeColor,
                          ),
                        ),
                        Text(
                          isOnline ? 'Online' : 'Offline Mode',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: ElderColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      info.statusLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        color: ElderColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (info.pendingEventsCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ElderColors.amberBg,
                    borderRadius: BorderRadius.circular(NirvanaRadii.pill),
                  ),
                  child: Text(
                    '${info.pendingEventsCount} queued',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: ElderColors.amberDeep,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator(color: ElderColors.clayLavender)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
