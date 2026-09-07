// ==============================================================================
// NIRVANA - Sync Status Card Widget
// Description: Displays network state, pending sync queue count, and cloud sync status.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
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
            ? (hasPending ? Colors.orange : Colors.green)
            : Colors.blueGrey;

        IconData statusIcon = isOnline
            ? (hasPending ? Icons.sync : Icons.cloud_done)
            : Icons.cloud_off;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: badgeColor.withValues(alpha: 0.3), width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
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
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                        Text(
                          isOnline ? 'Online' : 'Offline Mode',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isOnline ? Colors.green[800] : Colors.blueGrey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      info.statusLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        color: ElderColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (info.pendingEventsCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${info.pendingEventsCount} queued',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[900],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 48, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
