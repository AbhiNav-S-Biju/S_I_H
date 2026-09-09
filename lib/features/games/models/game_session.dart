// ==============================================================================
// NIRVANA - GameSession Model
// Description: Immutable record of completed non-clinical cognitive engagement
// ==============================================================================

import 'game_enums.dart';

/// Represents a completed non-clinical activity session.
///
/// Strictly conforms to safety guidelines:
/// - No cognitive diagnostic claims
/// - No dementia stage evaluations
/// - No "memory loss" or "brain health" scoring
class GameSession {
  final String id;
  final GameType gameType;
  final GameDifficulty difficulty;
  final int score;
  final int correctAnswers;
  final int totalQuestions;
  final int hintsUsed;
  final int durationSeconds;
  final DateTime completedAt;
  final Map<String, dynamic> activityMetadata;

  const GameSession({
    required this.id,
    required this.gameType,
    required this.difficulty,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.hintsUsed,
    required this.durationSeconds,
    required this.completedAt,
    this.activityMetadata = const {},
  });

  /// Non-clinical completion rate percentage (e.g. 100 for 3/3)
  double get completionRate {
    if (totalQuestions <= 0) return 0.0;
    return (correctAnswers / totalQuestions).clamp(0.0, 1.0);
  }

  /// Uplifting, supportive non-clinical feedback message
  String get supportiveFeedbackMessage {
    return localizedSupportiveFeedback('en');
  }

  /// Uplifting, supportive feedback message localized for the user's language
  String localizedSupportiveFeedback(String languageCode) {
    if (correctAnswers == totalQuestions) {
      switch (languageCode) {
        case 'hi':
          return 'अद्भुत कार्य! आपने बहुत ध्यान से आज की गतिविधि पूरी की।';
        case 'bn':
          return 'চমৎকার কাজ! আপনি অত্যন্ত মনোযোগ দিয়ে আজকের কার্যকলাপ সম্পন্ন করেছেন।';
        case 'as':
          return 'চমৎকাৰ কাম! আপুনি অতি মনোযোগেৰে আজিৰ কাৰ্য্য সম্পূৰ্ণ কৰিলে।';
        case 'ne':
          return 'अद्भूत काम! तपाईंले निकै ध्यान दिएर आजको गतिविधि पूरा गर्नुभयो।';
        default:
          return 'Wonderful work! You completed today’s activity with great focus.';
      }
    } else if (correctAnswers > 0) {
      switch (languageCode) {
        case 'hi':
          return 'सराहनीय प्रयास! आज अपने मन को सक्रिय रखने के लिए धन्यवाद।';
        case 'bn':
          return 'চমৎকার প্রচেষ্টা! আজ আপনার মন সক্রিয় রাখার জন্য ধন্যবাদ।';
        case 'as':
          return 'উত্তম প্ৰচেষ্টা! আজি আপোনাৰ মন সক্ৰিয় ৰখাৰ বাবে ধন্যবাদ।';
        case 'ne':
          return 'राम्रो प्रयास! आज आफ्नो दिमागलाई सक्रिय राख्नुभएकोमा धन्यवाद।';
        default:
          return 'Nice effort! Thank you for spending time engaging your mind today.';
      }
    } else {
      switch (languageCode) {
        case 'hi':
          return 'बहुत अच्छा प्रयास! हर पल का अभ्यास खुशी और ऊर्जा लाता है।';
        case 'bn':
          return 'দারুণ চেষ্টা! অনুশীলনের প্রতিটি মুহূর্ত আনন্দ ও উদ্দীপনা আনে।';
        case 'as':
          return 'ভাল চেষ্টা! অনুশীলনৰ প্ৰতিটো মুহূৰ্তই আনন্দ আৰু উদ্যম আনে।';
        case 'ne':
          return 'धेरै राम्रो प्रयास! अभ्यासको हरेक पलले आनन्द र ऊर्जा ल्याउँछ।';
        default:
          return 'Great try! Every moment of practice brings joy and activity.';
      }
    }
  }

  /// Safe, non-clinical summary for display in elder view
  String get elderSummaryText {
    return '$correctAnswers of $totalQuestions items found';
  }

  /// Converts model to standard JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'game_type': gameType.id,
      'difficulty': difficulty.id,
      'score': score,
      'correct_answers': correctAnswers,
      'total_questions': totalQuestions,
      'hints_used': hintsUsed,
      'duration_seconds': durationSeconds,
      'completed_at': completedAt.toIso8601String(),
      'activity_metadata': activityMetadata,
    };
  }

  /// Creates GameSession from JSON map
  factory GameSession.fromJson(Map<String, dynamic> json) {
    final gameTypeId = json['game_type'] as String? ?? 'remember_objects';
    final difficultyId = json['difficulty'] as String? ?? 'easy';

    final gameType = GameType.values.firstWhere(
      (g) => g.id == gameTypeId || g.name == gameTypeId,
      orElse: () => GameType.rememberObjects,
    );

    final difficulty = GameDifficulty.values.firstWhere(
      (d) => d.id == difficultyId || d.name == difficultyId,
      orElse: () => GameDifficulty.easy,
    );

    return GameSession(
      id: json['id'] as String,
      gameType: gameType,
      difficulty: difficulty,
      score: (json['score'] as num?)?.toInt() ?? 0,
      correctAnswers: (json['correct_answers'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['total_questions'] as num?)?.toInt() ?? 0,
      hintsUsed: (json['hints_used'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      completedAt: DateTime.parse(json['completed_at'] as String),
      activityMetadata:
          (json['activity_metadata'] as Map<String, dynamic>?) ?? {},
    );
  }

  @override
  String toString() {
    return 'GameSession(id: $id, gameType: ${gameType.id}, difficulty: ${difficulty.id}, score: $score, correct: $correctAnswers/$totalQuestions, hints: $hintsUsed, duration: ${durationSeconds}s)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameSession &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          gameType == other.gameType &&
          difficulty == other.difficulty &&
          score == other.score &&
          correctAnswers == other.correctAnswers &&
          totalQuestions == other.totalQuestions &&
          hintsUsed == other.hintsUsed &&
          durationSeconds == other.durationSeconds &&
          completedAt == other.completedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      gameType.hashCode ^
      difficulty.hashCode ^
      score.hashCode ^
      correctAnswers.hashCode ^
      totalQuestions.hashCode ^
      hintsUsed.hashCode ^
      durationSeconds.hashCode ^
      completedAt.hashCode;
}
