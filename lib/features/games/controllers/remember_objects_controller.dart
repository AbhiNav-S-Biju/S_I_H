// ==============================================================================
// NIRVANA - Remember Objects Controller
// Description: Pure business logic & state manager for Remember Objects game
// ==============================================================================

import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/game_enums.dart';
import '../models/game_item.dart';
import '../models/game_session.dart';

class RememberObjectsState {
  final GameDifficulty difficulty;
  final List<GameItem> targetItems;
  final List<GameItem> selectionOptions;
  final Set<String> selectedItemIds;
  final bool isMemorizationPhase;
  final int hintsUsed;
  final String? hintHighlightedItemId;
  final bool isCompleted;
  final DateTime startTime;
  final String? lastFeedback;

  const RememberObjectsState({
    required this.difficulty,
    required this.targetItems,
    required this.selectionOptions,
    required this.selectedItemIds,
    required this.isMemorizationPhase,
    required this.hintsUsed,
    this.hintHighlightedItemId,
    required this.isCompleted,
    required this.startTime,
    this.lastFeedback,
  });

  RememberObjectsState copyWith({
    GameDifficulty? difficulty,
    List<GameItem>? targetItems,
    List<GameItem>? selectionOptions,
    Set<String>? selectedItemIds,
    bool? isMemorizationPhase,
    int? hintsUsed,
    String? hintHighlightedItemId,
    bool? isCompleted,
    DateTime? startTime,
    String? lastFeedback,
  }) {
    return RememberObjectsState(
      difficulty: difficulty ?? this.difficulty,
      targetItems: targetItems ?? this.targetItems,
      selectionOptions: selectionOptions ?? this.selectionOptions,
      selectedItemIds: selectedItemIds ?? this.selectedItemIds,
      isMemorizationPhase: isMemorizationPhase ?? this.isMemorizationPhase,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      hintHighlightedItemId:
          hintHighlightedItemId ?? this.hintHighlightedItemId,
      isCompleted: isCompleted ?? this.isCompleted,
      startTime: startTime ?? this.startTime,
      lastFeedback: lastFeedback ?? this.lastFeedback,
    );
  }
}

class RememberObjectsController {
  final List<GameItem> availableCatalogue;
  final Random _random;
  final Uuid _uuid;

  late RememberObjectsState _state;
  RememberObjectsState get state => _state;

  RememberObjectsController({
    List<GameItem>? catalogue,
    Random? random,
    Uuid? uuid,
    GameDifficulty initialDifficulty = GameDifficulty.easy,
  }) : availableCatalogue = catalogue ?? GameItem.defaultEverydayItems,
       _random = random ?? Random(),
       _uuid = uuid ?? const Uuid() {
    startNewGame(difficulty: initialDifficulty);
  }

  /// Initializes a new game round with configured difficulty
  void startNewGame({GameDifficulty difficulty = GameDifficulty.easy}) {
    final count = difficulty.rememberObjectsCount;
    final totalOptions = difficulty.rememberObjectsTotalOptions;

    // Pick unique target items
    final shuffled = List<GameItem>.from(availableCatalogue)..shuffle(_random);
    final targets = shuffled.take(count).toList();

    // Prepare selection options including all targets + distractors
    final distractors = shuffled
        .skip(count)
        .take(totalOptions - count)
        .toList();
    final allOptions = [...targets, ...distractors]..shuffle(_random);

    _state = RememberObjectsState(
      difficulty: difficulty,
      targetItems: targets,
      selectionOptions: allOptions,
      selectedItemIds: {},
      isMemorizationPhase: true,
      hintsUsed: 0,
      hintHighlightedItemId: null,
      isCompleted: false,
      startTime: DateTime.now(),
      lastFeedback:
          'Look closely at these ${targets.length} items. Take all the time you need.',
    );
  }

  /// Transitions from Memorization screen to Recall screen
  void proceedToRecall() {
    _state = _state.copyWith(
      isMemorizationPhase: false,
      lastFeedback: 'Which items were on the screen? Tap them below.',
    );
  }

  /// Toggles selection of an item in the recall grid
  void toggleItemSelection(String itemId) {
    if (_state.isCompleted || _state.isMemorizationPhase) return;

    // Validate that the item exists in the options
    final itemExists = _state.selectionOptions.any((item) => item.id == itemId);
    if (!itemExists) return;

    final updated = Set<String>.from(_state.selectedItemIds);
    if (updated.contains(itemId)) {
      updated.remove(itemId);
    } else {
      updated.add(itemId);
    }

    _state = _state.copyWith(
      selectedItemIds: updated,
      // Clear specific hint highlight once user interacts
      hintHighlightedItemId: null,
    );
  }

  /// Provides gentle non-penalizing hint by highlighting an unselected target item
  bool useHint() {
    if (_state.isCompleted || _state.isMemorizationPhase) return false;

    // Find target items that the user hasn't selected yet
    final unselectedTargets = _state.targetItems
        .where((item) => !_state.selectedItemIds.contains(item.id))
        .toList();

    if (unselectedTargets.isEmpty) {
      // All correct items already selected
      _state = _state.copyWith(
        hintsUsed: _state.hintsUsed + 1,
        lastFeedback:
            'You have found all the items! Tap "Finish Activity" whenever you are ready.',
      );
      return true;
    }

    final hintTarget = unselectedTargets.first;
    _state = _state.copyWith(
      hintsUsed: _state.hintsUsed + 1,
      hintHighlightedItemId: hintTarget.id,
      lastFeedback: 'Hint: Take a look at the ${hintTarget.name}!',
    );
    return true;
  }

  /// Finalizes the activity and constructs the non-clinical GameSession record
  GameSession completeGame({DateTime? completionTime}) {
    final now = completionTime ?? DateTime.now();
    final duration = now.difference(_state.startTime).inSeconds.clamp(1, 7200);

    // Calculate correct answers
    final targetIds = _state.targetItems.map((e) => e.id).toSet();
    final correctCount = _state.selectedItemIds
        .where((id) => targetIds.contains(id))
        .length;
    final totalRequired = _state.targetItems.length;

    // Non-clinical engagement score (e.g. 100 points per item found + consistency bonus)
    final calculatedScore =
        (correctCount * 100) + (_state.hintsUsed == 0 ? 50 : 20);

    final session = GameSession(
      id: _uuid.v4(),
      gameType: GameType.rememberObjects,
      difficulty: _state.difficulty,
      score: calculatedScore,
      correctAnswers: correctCount,
      totalQuestions: totalRequired,
      hintsUsed: _state.hintsUsed,
      durationSeconds: duration,
      completedAt: now,
      activityMetadata: {
        'target_item_names': _state.targetItems.map((e) => e.name).toList(),
        'selected_item_count': _state.selectedItemIds.length,
        'all_correct': correctCount == totalRequired,
      },
    );

    _state = _state.copyWith(
      isCompleted: true,
      lastFeedback: session.supportiveFeedbackMessage,
    );

    return session;
  }
}
