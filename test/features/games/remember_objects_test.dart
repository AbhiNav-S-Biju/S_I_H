// ==============================================================================
// NIRVANA - Remember Objects Unit Tests
// Tests: Scoring, Difficulty, Hints, Completion, Invalid Selections, Non-Clinical Safety
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:nirvana/features/games/games.dart';

void main() {
  group('Remember Objects Game Tests', () {
    test('Difficulty settings accurately generate 3, 4, and 5 target items', () {
      final controllerEasy = RememberObjectsController(initialDifficulty: GameDifficulty.easy);
      expect(controllerEasy.state.targetItems.length, equals(3));
      expect(controllerEasy.state.selectionOptions.length, equals(6));

      final controllerMedium = RememberObjectsController(initialDifficulty: GameDifficulty.medium);
      expect(controllerMedium.state.targetItems.length, equals(4));
      expect(controllerMedium.state.selectionOptions.length, equals(8));

      final controllerHard = RememberObjectsController(initialDifficulty: GameDifficulty.hard);
      expect(controllerHard.state.targetItems.length, equals(5));
      expect(controllerHard.state.selectionOptions.length, equals(10));
    });

    test('Phase transitions: cannot select items during memorization phase', () {
      final controller = RememberObjectsController();
      expect(controller.state.isMemorizationPhase, isTrue);

      final firstOptionId = controller.state.selectionOptions.first.id;
      controller.toggleItemSelection(firstOptionId);
      // Selection must be blocked during memorization
      expect(controller.state.selectedItemIds, isEmpty);

      // Transition to recall phase
      controller.proceedToRecall();
      expect(controller.state.isMemorizationPhase, isFalse);

      // Now selection succeeds
      controller.toggleItemSelection(firstOptionId);
      expect(controller.state.selectedItemIds.contains(firstOptionId), isTrue);

      // Toggling again unselects the item
      controller.toggleItemSelection(firstOptionId);
      expect(controller.state.selectedItemIds.contains(firstOptionId), isFalse);
    });

    test('Invalid selections: selecting non-existent item id is ignored', () {
      final controller = RememberObjectsController();
      controller.proceedToRecall();

      controller.toggleItemSelection('non_existent_fake_item_12345');
      expect(controller.state.selectedItemIds, isEmpty);
    });

    test('Hints feature: increments count and highlights an unselected target item', () {
      final controller = RememberObjectsController();
      controller.proceedToRecall();

      expect(controller.state.hintsUsed, equals(0));
      expect(controller.state.hintHighlightedItemId, isNull);

      final hintUsed = controller.useHint();
      expect(hintUsed, isTrue);
      expect(controller.state.hintsUsed, equals(1));
      expect(controller.state.hintHighlightedItemId, isNotNull);

      // Verify that the highlighted item is indeed one of the targets
      final targetIds = controller.state.targetItems.map((e) => e.id).toSet();
      expect(targetIds.contains(controller.state.hintHighlightedItemId), isTrue);
    });

    test('Hints when all targets already selected provides supportive message', () {
      final controller = RememberObjectsController();
      controller.proceedToRecall();

      // Select all target items
      for (final target in controller.state.targetItems) {
        controller.toggleItemSelection(target.id);
      }

      final hintUsed = controller.useHint();
      expect(hintUsed, isTrue);
      expect(controller.state.hintsUsed, equals(1));
      expect(controller.state.lastFeedback, contains('You have found all the items'));
    });

    test('Scoring and Completion: returns complete GameSession with positive reinforcement', () {
      final controller = RememberObjectsController(initialDifficulty: GameDifficulty.easy);
      controller.proceedToRecall();

      // Select all 3 correct items
      for (final target in controller.state.targetItems) {
        controller.toggleItemSelection(target.id);
      }

      final startTime = controller.state.startTime;
      final completedTime = startTime.add(const Duration(seconds: 45));

      final session = controller.completeGame(completionTime: completedTime);

      expect(session.id, isNotEmpty);
      expect(session.gameType, equals(GameType.rememberObjects));
      expect(session.difficulty, equals(GameDifficulty.easy));
      expect(session.correctAnswers, equals(3));
      expect(session.totalQuestions, equals(3));
      expect(session.hintsUsed, equals(0));
      expect(session.durationSeconds, equals(45));
      expect(session.score, equals(350)); // (3 * 100) + 50 (no hint bonus)
      expect(controller.state.isCompleted, isTrue);

      // Non-clinical feedback safety verification
      expect(session.supportiveFeedbackMessage, isNotEmpty);
      expect(session.supportiveFeedbackMessage.toLowerCase(), isNot(contains('dementia')));
      expect(session.supportiveFeedbackMessage.toLowerCase(), isNot(contains('memory loss')));
      expect(session.supportiveFeedbackMessage.toLowerCase(), isNot(contains('brain score')));
      expect(session.supportiveFeedbackMessage.toLowerCase(), isNot(contains('cognitive decline')));
    });

    test('Post-completion interaction is disabled', () {
      final controller = RememberObjectsController();
      controller.proceedToRecall();
      controller.toggleItemSelection(controller.state.selectionOptions.first.id);
      controller.completeGame();

      // Attempt further selections
      final countBefore = controller.state.selectedItemIds.length;
      controller.toggleItemSelection(controller.state.selectionOptions.last.id);
      expect(controller.state.selectedItemIds.length, equals(countBefore));

      // Attempt hint
      final hintRes = controller.useHint();
      expect(hintRes, isFalse);
    });
  });
}
