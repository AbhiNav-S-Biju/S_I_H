// ==============================================================================
// NIRVANA - Grocery Memory Controller
// Description: Pure business logic & state manager for Grocery Memory game
// ==============================================================================

import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/game_enums.dart';
import '../models/game_item.dart';
import '../models/game_session.dart';

class GroceryMemoryState {
  final GameDifficulty difficulty;
  final List<GameItem> shoppingList;
  final List<GameItem> shelfItems;
  final Set<String> basketItemIds;
  final bool isListPhase;
  final int hintsUsed;
  final String? hintHighlightedItemId;
  final bool isCompleted;
  final DateTime startTime;
  final String? lastFeedback;

  const GroceryMemoryState({
    required this.difficulty,
    required this.shoppingList,
    required this.shelfItems,
    required this.basketItemIds,
    required this.isListPhase,
    required this.hintsUsed,
    this.hintHighlightedItemId,
    required this.isCompleted,
    required this.startTime,
    this.lastFeedback,
  });

  GroceryMemoryState copyWith({
    GameDifficulty? difficulty,
    List<GameItem>? shoppingList,
    List<GameItem>? shelfItems,
    Set<String>? basketItemIds,
    bool? isListPhase,
    int? hintsUsed,
    String? hintHighlightedItemId,
    bool? isCompleted,
    DateTime? startTime,
    String? lastFeedback,
  }) {
    return GroceryMemoryState(
      difficulty: difficulty ?? this.difficulty,
      shoppingList: shoppingList ?? this.shoppingList,
      shelfItems: shelfItems ?? this.shelfItems,
      basketItemIds: basketItemIds ?? this.basketItemIds,
      isListPhase: isListPhase ?? this.isListPhase,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      hintHighlightedItemId:
          hintHighlightedItemId ?? this.hintHighlightedItemId,
      isCompleted: isCompleted ?? this.isCompleted,
      startTime: startTime ?? this.startTime,
      lastFeedback: lastFeedback ?? this.lastFeedback,
    );
  }
}

class GroceryMemoryController {
  final List<GameItem> availableGroceries;
  final Random _random;
  final Uuid _uuid;

  late GroceryMemoryState _state;
  GroceryMemoryState get state => _state;

  GroceryMemoryController({
    List<GameItem>? groceries,
    Random? random,
    Uuid? uuid,
    GameDifficulty initialDifficulty = GameDifficulty.easy,
  }) : availableGroceries = groceries ?? GameItem.defaultGroceryItems,
       _random = random ?? Random(),
       _uuid = uuid ?? const Uuid() {
    startNewGame(difficulty: initialDifficulty);
  }

  /// Initializes a new grocery shopping run
  void startNewGame({GameDifficulty difficulty = GameDifficulty.easy}) {
    final count = difficulty.groceryItemsCount;
    final totalShelf = difficulty.groceryShelfCount;

    final shuffled = List<GameItem>.from(availableGroceries)..shuffle(_random);
    final targetList = shuffled.take(count).toList();

    final shelfDistractors = shuffled
        .skip(count)
        .take(totalShelf - count)
        .toList();
    final allShelf = [...targetList, ...shelfDistractors]..shuffle(_random);

    _state = GroceryMemoryState(
      difficulty: difficulty,
      shoppingList: targetList,
      shelfItems: allShelf,
      basketItemIds: {},
      isListPhase: true,
      hintsUsed: 0,
      hintHighlightedItemId: null,
      isCompleted: false,
      startTime: DateTime.now(),
      lastFeedback:
          'Here is your shopping list with ${targetList.length} items. Review it at your own pace.',
    );
  }

  /// Advances from shopping list view to the supermarket shelf
  void proceedToShelf() {
    _state = _state.copyWith(
      isListPhase: false,
      lastFeedback:
          'Tap items from your list to put them into your shopping cart.',
    );
  }

  /// Adds or removes an item from the elder's shopping basket
  void toggleBasketItem(String itemId) {
    if (_state.isCompleted || _state.isListPhase) return;

    // Validate that the item exists on the shelf
    final existsOnShelf = _state.shelfItems.any((item) => item.id == itemId);
    if (!existsOnShelf) return;

    final updatedBasket = Set<String>.from(_state.basketItemIds);
    if (updatedBasket.contains(itemId)) {
      updatedBasket.remove(itemId);
    } else {
      updatedBasket.add(itemId);
    }

    _state = _state.copyWith(
      basketItemIds: updatedBasket,
      hintHighlightedItemId: null,
    );
  }

  /// Provides supportive clue by highlighting a missing shopping list item on shelf
  bool useHint() {
    if (_state.isCompleted || _state.isListPhase) return false;

    // Find items in the shopping list not yet in the basket
    final uncollected = _state.shoppingList
        .where((item) => !_state.basketItemIds.contains(item.id))
        .toList();

    if (uncollected.isEmpty) {
      _state = _state.copyWith(
        hintsUsed: _state.hintsUsed + 1,
        lastFeedback:
            'Your basket contains all items from the list! Tap "Checkout" when ready.',
      );
      return true;
    }

    final hintItem = uncollected.first;
    _state = _state.copyWith(
      hintsUsed: _state.hintsUsed + 1,
      hintHighlightedItemId: hintItem.id,
      lastFeedback:
          'Hint: Look for the ${hintItem.name} ${hintItem.emoji} on the shelf!',
    );
    return true;
  }

  /// Completes the grocery activity and builds the non-clinical GameSession
  GameSession completeGame({DateTime? completionTime}) {
    final now = completionTime ?? DateTime.now();
    final duration = now.difference(_state.startTime).inSeconds.clamp(1, 7200);

    final listIds = _state.shoppingList.map((e) => e.id).toSet();
    final correctCount = _state.basketItemIds
        .where((id) => listIds.contains(id))
        .length;
    final totalListItems = _state.shoppingList.length;

    final calculatedScore =
        (correctCount * 100) + (_state.hintsUsed == 0 ? 50 : 20);

    final session = GameSession(
      id: _uuid.v4(),
      gameType: GameType.groceryMemory,
      difficulty: _state.difficulty,
      score: calculatedScore,
      correctAnswers: correctCount,
      totalQuestions: totalListItems,
      hintsUsed: _state.hintsUsed,
      durationSeconds: duration,
      completedAt: now,
      activityMetadata: {
        'shopping_list_names': _state.shoppingList.map((e) => e.name).toList(),
        'basket_count': _state.basketItemIds.length,
        'all_found': correctCount == totalListItems,
      },
    );

    _state = _state.copyWith(
      isCompleted: true,
      lastFeedback: session.supportiveFeedbackMessage,
    );

    return session;
  }
}
