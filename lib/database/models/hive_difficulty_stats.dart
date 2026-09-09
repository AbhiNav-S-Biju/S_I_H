// ==============================================================================
// NIRVANA - HiveDifficultyStats Model
// Description: Persists per-patient, per-game, per-difficulty sliding-window
// reward scores for the Smart Difficulty (epsilon-greedy) recommender.
// Purely local offline storage.
// ==============================================================================

import 'package:hive/hive.dart';

/// Stores a sliding window of recent session rewards (up to 8) for a specific
/// patient + game + difficulty combination.
///
/// Hive box key: "${patientId}_${gameTypeId}_${difficultyId}"
class HiveDifficultyStats extends HiveObject {
  /// Unique identifier of the patient (or 'default_patient')
  String patientId;

  /// Matches [GameType.id] — e.g. 'remember_objects'
  String gameTypeId;

  /// Matches [GameDifficulty.id] — 'easy' | 'medium' | 'hard'
  String difficultyId;

  /// Sliding window of the last up to 8 session reward scores in [0.0, 1.0].
  List<double> rewardScores;

  /// Timestamp when this difficulty was last played by this patient.
  DateTime lastPlayedAt;

  HiveDifficultyStats({
    required this.patientId,
    required this.gameTypeId,
    required this.difficultyId,
    List<double>? rewardScores,
    DateTime? lastPlayedAt,
  })  : rewardScores = rewardScores ?? [],
        lastPlayedAt = lastPlayedAt ?? DateTime.now();

  /// Total count of recorded sessions in the current sliding window.
  int get sessionCount => rewardScores.length;

  /// Arithmetic mean of all reward scores in the current sliding window.
  double get averageReward {
    if (rewardScores.isEmpty) return 0.0;
    final sum = rewardScores.reduce((a, b) => a + b);
    return sum / rewardScores.length;
  }
}
