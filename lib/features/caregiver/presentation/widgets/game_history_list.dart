// ==============================================================================
// NIRVANA - Game History List Widget
// Description: Displays recent memory and engagement activities played by the patient
// with claymorphic card styling.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/app/widgets/widgets.dart';
import 'package:nirvana/features/caregiver/providers/caregiver_providers.dart';

class GameHistoryList extends ConsumerWidget {
  const GameHistoryList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(selectedPatientGameHistoryProvider);

    return historyAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return ElderCard(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: const [
                  Icon(Icons.extension_rounded, size: 38, color: ElderColors.textMuted),
                  SizedBox(height: 8),
                  Text(
                    'No game activity recorded yet.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: ElderColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ElderCard(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: records.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: ElderColors.borderLight),
            itemBuilder: (context, index) {
              final game = records[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ElderColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.videogame_asset_rounded,
                    color: ElderColors.clayLavender,
                    size: 24,
                  ),
                ),
                title: Text(
                  game.gameTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: ElderColors.textPrimary,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    '${game.difficulty.toUpperCase()} • ${game.correctCount}/${game.totalCount} correct • ${game.durationSeconds}s',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: ElderColors.textSecondary,
                    ),
                  ),
                ),
                trailing: Text(
                  _formatTimeAgo(game.playedAt),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ElderColors.textMuted,
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(color: ElderColors.clayLavender),
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
