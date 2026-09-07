// ==============================================================================
// NIRVANA - GameSession Model Unit Tests
// Tests: Serialization, Non-Clinical Assertions, Equality, Edge Cases
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:nirvana/features/games/games.dart';

void main() {
  group('GameSession Model Tests', () {
    test('JSON serialization and deserialization roundtrip', () {
      final now = DateTime.utc(2026, 9, 7, 12, 30);
      final original = GameSession(
        id: 'test-session-uuid-12345',
        gameType: GameType.rememberObjects,
        difficulty: GameDifficulty.medium,
        score: 450,
        correctAnswers: 4,
        totalQuestions: 4,
        hintsUsed: 1,
        durationSeconds: 90,
        completedAt: now,
        activityMetadata: {'test_key': 'test_val'},
      );

      final json = original.toJson();
      expect(json['id'], equals('test-session-uuid-12345'));
      expect(json['game_type'], equals('remember_objects'));
      expect(json['difficulty'], equals('medium'));
      expect(json['score'], equals(450));
      expect(json['correct_answers'], equals(4));
      expect(json['total_questions'], equals(4));
      expect(json['hints_used'], equals(1));
      expect(json['duration_seconds'], equals(90));
      expect(json['completed_at'], equals(now.toIso8601String()));

      final reconstructed = GameSession.fromJson(json);
      expect(reconstructed.id, equals(original.id));
      expect(reconstructed.gameType, equals(original.gameType));
      expect(reconstructed.difficulty, equals(original.difficulty));
      expect(reconstructed.score, equals(original.score));
      expect(reconstructed.correctAnswers, equals(original.correctAnswers));
      expect(reconstructed.totalQuestions, equals(original.totalQuestions));
      expect(reconstructed.hintsUsed, equals(original.hintsUsed));
      expect(reconstructed.durationSeconds, equals(original.durationSeconds));
      expect(reconstructed.completedAt, equals(original.completedAt));
    });

    test('Completion rate calculation and edge cases', () {
      final sessionPerfect = GameSession(
        id: '1',
        gameType: GameType.groceryMemory,
        difficulty: GameDifficulty.easy,
        score: 300,
        correctAnswers: 3,
        totalQuestions: 3,
        hintsUsed: 0,
        durationSeconds: 30,
        completedAt: DateTime.now(),
      );
      expect(sessionPerfect.completionRate, equals(1.0));

      final sessionPartial = GameSession(
        id: '2',
        gameType: GameType.whoIsThis,
        difficulty: GameDifficulty.medium,
        score: 150,
        correctAnswers: 1,
        totalQuestions: 3,
        hintsUsed: 1,
        durationSeconds: 40,
        completedAt: DateTime.now(),
      );
      expect(sessionPartial.completionRate, closeTo(0.333, 0.001));

      final sessionZero = GameSession(
        id: '3',
        gameType: GameType.rememberObjects,
        difficulty: GameDifficulty.easy,
        score: 0,
        correctAnswers: 0,
        totalQuestions: 0,
        hintsUsed: 0,
        durationSeconds: 10,
        completedAt: DateTime.now(),
      );
      expect(sessionZero.completionRate, equals(0.0));
    });

    test('Strict non-clinical terminology verification', () {
      final session = GameSession(
        id: '1',
        gameType: GameType.rememberObjects,
        difficulty: GameDifficulty.hard,
        score: 500,
        correctAnswers: 5,
        totalQuestions: 5,
        hintsUsed: 0,
        durationSeconds: 120,
        completedAt: DateTime.now(),
      );

      final msg = session.supportiveFeedbackMessage.toLowerCase();
      final forbiddenTerms = [
        'dementia',
        'alzheimer',
        'cognitive decline',
        'memory loss',
        'brain score',
        'mental age',
        'severity',
        'diagnos',
        'fail',
      ];

      for (final term in forbiddenTerms) {
        expect(msg, isNot(contains(term)), reason: 'Forbidden term "$term" found in message');
      }
    });
  });
}
