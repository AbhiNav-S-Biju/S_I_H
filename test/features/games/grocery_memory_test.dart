// ==============================================================================
// NIRVANA - Grocery Memory Unit Tests
// Tests: Scoring, Difficulty, Hints, Completion, Invalid Selections, Non-Clinical Safety
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:nirvana/features/games/games.dart';

void main() {
  group('Grocery Memory Game Tests', () {
    test('Difficulty settings accurately generate 3, 4, and 5 shopping list items', () {
      final controllerEasy = GroceryMemoryController(initialDifficulty: GameDifficulty.easy);
      expect(controllerEasy.state.shoppingList.length, equals(3));
      expect(controllerEasy.state.shelfItems.length, equals(6));

      final controllerMedium = GroceryMemoryController(initialDifficulty: GameDifficulty.medium);
      expect(controllerMedium.state.shoppingList.length, equals(4));
      expect(controllerMedium.state.shelfItems.length, equals(8));

      final controllerHard = GroceryMemoryController(initialDifficulty: GameDifficulty.hard);
      expect(controllerHard.state.shoppingList.length, equals(5));
      expect(controllerHard.state.shelfItems.length, equals(10));
    });

    test('Phase transitions: cannot pick items during shopping list review phase', () {
      final controller = GroceryMemoryController();
      expect(controller.state.isListPhase, isTrue);

      final firstShelfItem = controller.state.shelfItems.first.id;
      controller.toggleBasketItem(firstShelfItem);
      expect(controller.state.basketItemIds, isEmpty);

      // Advance to shelf phase
      controller.proceedToShelf();
      expect(controller.state.isListPhase, isFalse);

      // Now basket picking succeeds
      controller.toggleBasketItem(firstShelfItem);
      expect(controller.state.basketItemIds.contains(firstShelfItem), isTrue);

      // Toggling again removes from basket
      controller.toggleBasketItem(firstShelfItem);
      expect(controller.state.basketItemIds.contains(firstShelfItem), isFalse);
    });

    test('Invalid selections: selecting non-existent item id is ignored', () {
      final controller = GroceryMemoryController();
      controller.proceedToShelf();

      controller.toggleBasketItem('fake_grocery_item_xyz_999');
      expect(controller.state.basketItemIds, isEmpty);
    });

    test('Hints feature: highlights uncollected shopping list item', () {
      final controller = GroceryMemoryController();
      controller.proceedToShelf();

      expect(controller.state.hintsUsed, equals(0));
      expect(controller.state.hintHighlightedItemId, isNull);

      final hintUsed = controller.useHint();
      expect(hintUsed, isTrue);
      expect(controller.state.hintsUsed, equals(1));
      expect(controller.state.hintHighlightedItemId, isNotNull);

      // Verify that hint highlighted item is one of the shopping list items
      final listIds = controller.state.shoppingList.map((e) => e.id).toSet();
      expect(listIds.contains(controller.state.hintHighlightedItemId), isTrue);
    });

    test('Hints when all shopping list items collected', () {
      final controller = GroceryMemoryController();
      controller.proceedToShelf();

      for (final item in controller.state.shoppingList) {
        controller.toggleBasketItem(item.id);
      }

      final hintUsed = controller.useHint();
      expect(hintUsed, isTrue);
      expect(controller.state.hintsUsed, equals(1));
      expect(controller.state.lastFeedback, contains('Your basket contains all items'));
    });

    test('Scoring and Completion: constructs valid GameSession', () {
      final controller = GroceryMemoryController(initialDifficulty: GameDifficulty.easy);
      controller.proceedToShelf();

      // Collect all 3 target items
      for (final item in controller.state.shoppingList) {
        controller.toggleBasketItem(item.id);
      }

      final startTime = controller.state.startTime;
      final completedTime = startTime.add(const Duration(seconds: 50));

      final session = controller.completeGame(completionTime: completedTime);

      expect(session.id, isNotEmpty);
      expect(session.gameType, equals(GameType.groceryMemory));
      expect(session.difficulty, equals(GameDifficulty.easy));
      expect(session.correctAnswers, equals(3));
      expect(session.totalQuestions, equals(3));
      expect(session.hintsUsed, equals(0));
      expect(session.durationSeconds, equals(50));
      expect(session.score, equals(350)); // (3 * 100) + 50 (no hint bonus)
      expect(controller.state.isCompleted, isTrue);

      // Safety check
      expect(session.supportiveFeedbackMessage.toLowerCase(), isNot(contains('dementia')));
      expect(session.supportiveFeedbackMessage.toLowerCase(), isNot(contains('memory loss')));
      expect(session.supportiveFeedbackMessage.toLowerCase(), isNot(contains('brain score')));
    });

    test('Post-completion interaction is blocked', () {
      final controller = GroceryMemoryController();
      controller.proceedToShelf();
      controller.toggleBasketItem(controller.state.shelfItems.first.id);
      controller.completeGame();

      // Attempt changes after completion
      final countBefore = controller.state.basketItemIds.length;
      controller.toggleBasketItem(controller.state.shelfItems.last.id);
      expect(controller.state.basketItemIds.length, equals(countBefore));

      final hintRes = controller.useHint();
      expect(hintRes, isFalse);
    });
  });
}
