// ==============================================================================
// NIRVANA - Game History List Widget
// Description: Displays recent memory and engagement activities played by the patient.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/features/caregiver/providers/caregiver_providers.dart';

class GameHistoryList extends ConsumerWidget {
  const GameHistoryList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(selectedPatientGameHistoryProvider);

    return historyAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.extension_outlined, size: 40, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'No game activity recorded yet.',
                    style: TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
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
            itemCount: records.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
            itemBuilder: (context, index) {
              final game = records[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: CircleAvatar(
                  backgroundColor: ElderColors.primary.withValues(alpha: 0.12),
                  child: const Icon(Icons.videogame_asset_outlined, color: ElderColors.primary),
                ),
                title: Text(
                  game.gameTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: ElderColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '${game.difficulty.toUpperCase()} • ${game.correctCount}/${game.totalCount} correct • ${game.durationSeconds}s',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                trailing: Text(
                  _formatTimeAgo(game.playedAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Text('Error loading game history: $e'),
    );
  }

  static String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
