// ==============================================================================
// NIRVANA - Who Is This? Unit Tests
// Tests: Scoring, Difficulty, Hints, Completion, Invalid Selections, Non-Clinical Safety
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:nirvana/features/games/games.dart';

void main() {
  group('Who Is This? Game Tests', () {
    test('Difficulty settings accurately generate 2, 3, and 4 questions', () {
      final controllerEasy = WhoIsThisController(initialDifficulty: GameDifficulty.easy);
      expect(controllerEasy.state.questions.length, equals(2));

      final controllerMedium = WhoIsThisController(initialDifficulty: GameDifficulty.medium);
      expect(controllerMedium.state.questions.length, equals(3));

      final controllerHard = WhoIsThisController(initialDifficulty: GameDifficulty.hard);
      expect(controllerHard.state.questions.length, equals(4));
    });

    test('Selecting relationship records valid answer', () {
      final controller = WhoIsThisController();
      final currentQ = controller.state.currentQuestion!;
      final correctChoice = currentQ.relationship;

      controller.selectRelationship(correctChoice);
      expect(controller.state.selectedRelationship, equals(correctChoice));
      expect(controller.state.answers[0], equals(correctChoice));
      expect(controller.state.lastFeedback, contains('Wonderful!'));
    });

    test('Invalid selections: selecting option not in question is ignored', () {
      final controller = WhoIsThisController();
      controller.selectRelationship('Astronaut_Extraterrestrial_999');
      expect(controller.state.selectedRelationship, isNull);
      expect(controller.state.answers, isEmpty);
    });

    test('Hints feature: eliminates a wrong answer and increments hint counter', () {
      final controller = WhoIsThisController();
      final currentQ = controller.state.currentQuestion!;

      expect(controller.state.hintsUsed, equals(0));
      expect(controller.state.eliminatedDistractors, isEmpty);

      final hintUsed = controller.useHint();
      expect(hintUsed, isTrue);
      expect(controller.state.hintsUsed, equals(1));
      expect(controller.state.eliminatedDistractors.length, equals(1));
      expect(controller.state.activeHintText, equals(currentQ.hintDescription));

      // Attempting to select the eliminated option is blocked
      final eliminatedOption = controller.state.eliminatedDistractors.first;
      controller.selectRelationship(eliminatedOption);
      expect(controller.state.selectedRelationship, isNull);
    });

    test('Multi-card progression through to completion', () {
      final controller = WhoIsThisController(initialDifficulty: GameDifficulty.easy);
      expect(controller.state.questions.length, equals(2));

      // Answer Question 1 correctly
      final q1 = controller.state.currentQuestion!;
      controller.selectRelationship(q1.relationship);
      expect(controller.state.isLastQuestion, isFalse);

      // Advance to Question 2
      controller.nextQuestion();
      expect(controller.state.currentQuestionIndex, equals(1));
      expect(controller.state.selectedRelationship, isNull);
      expect(controller.state.isLastQuestion, isTrue);

      // Answer Question 2
      final q2 = controller.state.currentQuestion!;
      controller.selectRelationship(q2.relationship);

      final startTime = controller.state.startTime;
      final completedTime = startTime.add(const Duration(seconds: 60));

      final session = controller.completeGame(completionTime: completedTime);

      expect(session.id, isNotEmpty);
      expect(session.gameType, equals(GameType.whoIsThis));
      expect(session.difficulty, equals(GameDifficulty.easy));
      expect(session.correctAnswers, equals(2));
      expect(session.totalQuestions, equals(2));
      expect(session.score, equals(290)); // (2 * 120) + 50 (no hint bonus)
      expect(session.durationSeconds, equals(60));
      expect(controller.state.isCompleted, isTrue);

      // Safety check
      expect(session.supportiveFeedbackMessage.toLowerCase(), isNot(contains('dementia')));
      expect(session.supportiveFeedbackMessage.toLowerCase(), isNot(contains('brain score')));
    });

    test('Post-completion interaction is blocked', () {
      final controller = WhoIsThisController();
      controller.selectRelationship(controller.state.currentQuestion!.relationship);
      controller.completeGame();

      // Attempts after completion
      controller.selectRelationship(controller.state.currentQuestion!.relationship);
      final hintRes = controller.useHint();
      expect(hintRes, isFalse);
    });
  });
}
