// ==============================================================================
// NIRVANA - DifficultyRecommender
// Description: Epsilon-greedy bandit that recommends an activity pace (difficulty)
// for a given game type, based on the elder's recent sliding-window activity history.
// No ML training required — pure sliding-window bookkeeping in Hive.
//
// Safety note: This class never surfaces numeric scores or clinical language
// to the elder. It only informs the UI which difficulty badge to highlight.
// ==============================================================================

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/hive_database.dart';
import '../../database/models/hive_difficulty_stats.dart';
import '../../features/caregiver/providers/caregiver_providers.dart';
import '../../features/games/models/game_enums.dart';
import '../../features/games/models/game_session.dart';

/// Fraction of the time we explore (pick the least-tried difficulty) rather
/// than exploit the current best estimate.
const double _epsilon = 0.10;

/// Average-reward threshold above which we suggest stepping up a level,
/// provided the elder has enough sessions at the current level to be confident.
const double _stepUpThreshold = 0.85;

/// Minimum sessions in the sliding window before we consider stepping up.
const int _stepUpMinSessions = 3;

/// Average-reward threshold below which we suggest stepping down a level.
const double _stepDownThreshold = 0.50;

/// Maximum number of recent session scores retained per tier in the sliding window.
const int _maxWindowSize = 8;

/// Ordered list of difficulty levels, from easiest to hardest.
const List<GameDifficulty> _orderedDifficulties = [
  GameDifficulty.easy,
  GameDifficulty.medium,
  GameDifficulty.hard,
];

/// Fallback identifier for an unpaired or standalone demo elder device.
const String kDefaultPatientId = 'default_patient';

/// Computes, records, and recommends activity paces using an epsilon-greedy
/// bandit strategy backed by Hive for offline-first persistence.
class DifficultyRecommender {
  final Random _random;

  DifficultyRecommender({Random? random}) : _random = random ?? Random();

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Compound key used as the Hive box lookup key, scoped per patient.
  String _key(String patientId, String gameTypeId, String difficultyId) =>
      '${patientId.isEmpty ? kDefaultPatientId : patientId}_${gameTypeId}_$difficultyId';

  /// Returns the [HiveDifficultyStats] for the given patient + game + difficulty,
  /// or `null` if no sessions have been recorded yet.
  HiveDifficultyStats? _getStats(
    String patientId,
    String gameTypeId,
    String difficultyId,
  ) {
    final box = HiveDatabase.difficultyStatsBox;
    return box.get(_key(patientId, gameTypeId, difficultyId));
  }

  // ---------------------------------------------------------------------------
  // Reward computation
  // ---------------------------------------------------------------------------

  /// Computes a normalised reward in [0.0, 1.0] from a completed [GameSession].
  ///
  /// Combines:
  ///   - Accuracy: correctAnswers / totalQuestions (weight 0.7)
  ///   - Hint usage: 1 - (hintsUsed / maxPossibleHints) (weight 0.3)
  double _computeReward(GameSession session) {
    if (session.totalQuestions <= 0) return 0.0;
    final accuracy = (session.correctAnswers / session.totalQuestions).clamp(0.0, 1.0);
    final maxHints = session.totalQuestions;
    final hintRatio = (session.hintsUsed / maxHints).clamp(0.0, 1.0);
    final hintScore = 1.0 - hintRatio;
    return (accuracy * 0.7 + hintScore * 0.3).clamp(0.0, 1.0);
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Appends the completed session reward to that patient+game+difficulty's
  /// sliding window (max 8 entries, dropping oldest), and updates [lastPlayedAt].
  Future<void> recordSession(String patientId, GameSession session) async {
    try {
      final effectivePatientId = patientId.trim().isEmpty ? kDefaultPatientId : patientId.trim();
      final box = HiveDatabase.difficultyStatsBox;
      final gameTypeId = session.gameType.id;
      final difficultyId = session.difficulty.id;
      final key = _key(effectivePatientId, gameTypeId, difficultyId);
      final reward = _computeReward(session);

      debugPrint('📝 [SmartDifficulty:recordSession] patientId: "$effectivePatientId" | Hive key: "$key" | reward: ${reward.toStringAsFixed(3)}');

      final existing = box.get(key);
      if (existing == null) {
        final record = HiveDifficultyStats(
          patientId: effectivePatientId,
          gameTypeId: gameTypeId,
          difficultyId: difficultyId,
          rewardScores: [reward],
          lastPlayedAt: session.completedAt,
        );
        await box.put(key, record);
      } else {
        existing.rewardScores.add(reward);
        if (existing.rewardScores.length > _maxWindowSize) {
          existing.rewardScores.removeAt(0);
        }
        existing.lastPlayedAt = session.completedAt;
        await existing.save();
      }
    } catch (e) {
      // Non-critical: analytics failure must not interrupt the elder's flow.
      // ignore: avoid_print
      debugPrint('⚠️ DifficultyRecommender.recordSession error: $e');
    }
  }

  /// Returns the recommended [GameDifficulty] for the given [patientId] and [gameType].
  ///
  /// Strategy:
  ///   • 10% of calls (exploration): recommend the tier with the fewest recorded
  ///     sessions in the sliding window.
  ///   • 90% of calls (exploitation):
  ///       - Identifies the "current difficulty" as the tier MOST RECENTLY PLAYED.
  ///       - Using that tier's windowed average:
  ///           - Step up if average > 0.85 and at least 3 sessions in window.
  ///           - Step down if average < 0.50.
  ///           - Otherwise stay.
  ///   • Falls back to [GameDifficulty.easy] when there is no history at all.
  GameDifficulty recommend(String patientId, GameType gameType) {
    final effectivePatientId = patientId.trim().isEmpty ? kDefaultPatientId : patientId.trim();
    final gameTypeId = gameType.id;

    // Gather stats for every difficulty level for this specific patient.
    final statsMap = {
      for (final d in _orderedDifficulties)
        d: _getStats(effectivePatientId, gameTypeId, d.id),
    };

    debugPrint(
      '🔍 [SmartDifficulty:recommend] patientId: "$effectivePatientId" | game: "$gameTypeId" | '
      'Hive keys checked: [${_orderedDifficulties.map((d) => _key(effectivePatientId, gameTypeId, d.id)).join(', ')}]',
    );
    for (final d in _orderedDifficulties) {
      final s = statsMap[d];
      final avg = s != null ? s.averageReward.toStringAsFixed(3) : 'none';
      final scores = s?.rewardScores ?? [];
      final lastPlayed = s?.lastPlayedAt.toIso8601String() ?? 'never';
      debugPrint('   • ${d.name.padRight(6)}: avgReward = $avg, scores = $scores, lastPlayed = $lastPlayed');
    }

    final totalSessions = statsMap.values
        .map((s) => s?.sessionCount ?? 0)
        .fold(0, (a, b) => a + b);

    // ── Exploration (ε-greedy) ──────────────────────────────────────────────
    if (totalSessions == 0 || _random.nextDouble() < _epsilon) {
      return _orderedDifficulties.reduce((least, d) {
        final leastCount = statsMap[least]?.sessionCount ?? 0;
        final dCount = statsMap[d]?.sessionCount ?? 0;
        return dCount < leastCount ? d : least;
      });
    }

    // ── Exploitation (Most Recently Played Tier) ─────────────────────────────
    // Find the tier that was most recently played.
    GameDifficulty? mostRecentTier;
    DateTime? mostRecentTime;

    for (final d in _orderedDifficulties) {
      final stats = statsMap[d];
      if (stats != null && stats.rewardScores.isNotEmpty) {
        if (mostRecentTime == null || stats.lastPlayedAt.isAfter(mostRecentTime)) {
          mostRecentTime = stats.lastPlayedAt;
          mostRecentTier = d;
        }
      }
    }

    if (mostRecentTier == null) {
      return GameDifficulty.easy;
    }

    final currentStats = statsMap[mostRecentTier];
    if (currentStats == null || currentStats.rewardScores.isEmpty) {
      return GameDifficulty.easy;
    }

    final currentIndex = _orderedDifficulties.indexOf(mostRecentTier);
    final avgReward = currentStats.averageReward;
    final count = currentStats.sessionCount;

    // Step up?
    if (avgReward > _stepUpThreshold &&
        count >= _stepUpMinSessions &&
        currentIndex < _orderedDifficulties.length - 1) {
      return _orderedDifficulties[currentIndex + 1];
    }

    // Step down?
    if (avgReward < _stepDownThreshold && currentIndex > 0) {
      return _orderedDifficulties[currentIndex - 1];
    }

    // Stay.
    return mostRecentTier;
  }
}

// ==============================================================================
// Riverpod Providers
// ==============================================================================

/// Provides the singleton [DifficultyRecommender] instance.
final difficultyRecommenderProvider = Provider<DifficultyRecommender>((ref) {
  return DifficultyRecommender();
});

/// Returns the recommended [GameDifficulty] for a given [GameType], automatically
/// watching the currently selected patient in Riverpod.
///
/// Usage in a widget:
/// ```dart
/// final recommended = ref.watch(recommendedDifficultyProvider(GameType.rememberObjects));
/// ```
final recommendedDifficultyProvider =
    Provider.family<GameDifficulty, GameType>((ref, gameType) {
  final patientId = ref.watch(selectedPatientProvider)?.id ?? kDefaultPatientId;
  return ref.watch(difficultyRecommenderProvider).recommend(patientId, gameType);
});
