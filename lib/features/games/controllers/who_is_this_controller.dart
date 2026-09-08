// ==============================================================================
// NIRVANA - Who Is This? Controller
// Description: Pure business logic & state manager for Who Is This? relationship game
// ==============================================================================

import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/family_member_item.dart';
import '../models/game_enums.dart';
import '../models/game_session.dart';

class WhoIsThisState {
  final GameDifficulty difficulty;
  final List<FamilyMemberItem> questions;
  final int currentQuestionIndex;
  final String? selectedRelationship;
  final Map<int, String> answers; // question index -> chosen relationship
  final Set<String> eliminatedDistractors;
  final int hintsUsed;
  final String? activeHintText;
  final bool isCompleted;
  final DateTime startTime;
  final String? lastFeedback;

  const WhoIsThisState({
    required this.difficulty,
    required this.questions,
    required this.currentQuestionIndex,
    this.selectedRelationship,
    required this.answers,
    required this.eliminatedDistractors,
    required this.hintsUsed,
    this.activeHintText,
    required this.isCompleted,
    required this.startTime,
    this.lastFeedback,
  });

  FamilyMemberItem? get currentQuestion =>
      (currentQuestionIndex >= 0 && currentQuestionIndex < questions.length)
      ? questions[currentQuestionIndex]
      : null;

  bool get isLastQuestion => currentQuestionIndex >= questions.length - 1;

  WhoIsThisState copyWith({
    GameDifficulty? difficulty,
    List<FamilyMemberItem>? questions,
    int? currentQuestionIndex,
    String? selectedRelationship,
    bool clearSelectedRelationship = false,
    Map<int, String>? answers,
    Set<String>? eliminatedDistractors,
    int? hintsUsed,
    String? activeHintText,
    bool clearActiveHintText = false,
    bool? isCompleted,
    DateTime? startTime,
    String? lastFeedback,
  }) {
    return WhoIsThisState(
      difficulty: difficulty ?? this.difficulty,
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      selectedRelationship: clearSelectedRelationship
          ? null
          : (selectedRelationship ?? this.selectedRelationship),
      answers: answers ?? this.answers,
      eliminatedDistractors:
          eliminatedDistractors ?? this.eliminatedDistractors,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      activeHintText: clearActiveHintText
          ? null
          : (activeHintText ?? this.activeHintText),
      isCompleted: isCompleted ?? this.isCompleted,
      startTime: startTime ?? this.startTime,
      lastFeedback: lastFeedback ?? this.lastFeedback,
    );
  }
}

class WhoIsThisController {
  final List<FamilyMemberItem> availableFamily;
  final Random _random;
  final Uuid _uuid;

  late WhoIsThisState _state;
  WhoIsThisState get state => _state;

  WhoIsThisController({
    List<FamilyMemberItem>? familyMembers,
    Random? random,
    Uuid? uuid,
    GameDifficulty initialDifficulty = GameDifficulty.easy,
  }) : availableFamily = familyMembers ?? FamilyMemberItem.defaultFamilyMembers,
       _random = random ?? Random(),
       _uuid = uuid ?? const Uuid() {
    startNewGame(difficulty: initialDifficulty);
  }

  /// Initializes game questions based on difficulty tier
  void startNewGame({GameDifficulty difficulty = GameDifficulty.easy}) {
    final count = min(
      difficulty.whoIsThisQuestionCount,
      availableFamily.length,
    );
    final shuffled = List<FamilyMemberItem>.from(availableFamily)
      ..shuffle(_random);
    final chosenQuestions = shuffled.take(count).toList();

    _state = WhoIsThisState(
      difficulty: difficulty,
      questions: chosenQuestions,
      currentQuestionIndex: 0,
      selectedRelationship: null,
      answers: {},
      eliminatedDistractors: {},
      hintsUsed: 0,
      activeHintText: null,
      isCompleted: false,
      startTime: DateTime.now(),
      lastFeedback: 'Look at the friendly picture. Who is this person to you?',
    );
  }

  /// Selects an option for the current active question
  void selectRelationship(String choice) {
    if (_state.isCompleted) return;
    final current = _state.currentQuestion;
    if (current == null) return;

    // Reject selection if option was eliminated via hint
    if (_state.eliminatedDistractors.contains(choice)) return;

    // Validate that the choice belongs to this question's options
    if (!current.alternativeRelationshipOptions.contains(choice)) return;

    final updatedAnswers = Map<int, String>.from(_state.answers);
    updatedAnswers[_state.currentQuestionIndex] = choice;

    final isCorrect =
        choice.toLowerCase() == current.relationship.toLowerCase();

    _state = _state.copyWith(
      selectedRelationship: choice,
      answers: updatedAnswers,
      lastFeedback: isCorrect
          ? 'Yes, that’s ${current.name}! Wonderful!'
          : 'Thank you for your answer. Let\'s continue together.',
    );
  }

  /// Provides supportive hint (reveals hint text + removes one incorrect option)
  bool useHint() {
    if (_state.isCompleted) return false;
    final current = _state.currentQuestion;
    if (current == null) return false;

    final wrongOptions = current.alternativeRelationshipOptions
        .where(
          (opt) =>
              opt.toLowerCase() != current.relationship.toLowerCase() &&
              !_state.eliminatedDistractors.contains(opt),
        )
        .toList();

    final updatedEliminated = Set<String>.from(_state.eliminatedDistractors);
    if (wrongOptions.isNotEmpty) {
      updatedEliminated.add(wrongOptions.first);
    }

    _state = _state.copyWith(
      hintsUsed: _state.hintsUsed + 1,
      eliminatedDistractors: updatedEliminated,
      activeHintText: current.hintDescription,
      lastFeedback: 'Hint: ${current.hintDescription}',
    );
    return true;
  }

  /// Moves to the next family member card
  void nextQuestion() {
    if (_state.isCompleted || _state.isLastQuestion) return;

    _state = _state.copyWith(
      currentQuestionIndex: _state.currentQuestionIndex + 1,
      clearSelectedRelationship: true,
      eliminatedDistractors: {},
      clearActiveHintText: true,
      lastFeedback: 'Who is smiling in this picture?',
    );
  }

  /// Finalizes the activity and returns a non-clinical GameSession
  GameSession completeGame({DateTime? completionTime}) {
    final now = completionTime ?? DateTime.now();
    final duration = now.difference(_state.startTime).inSeconds.clamp(1, 7200);

    int correctCount = 0;
    for (int i = 0; i < _state.questions.length; i++) {
      final chosen = _state.answers[i];
      final target = _state.questions[i].relationship;
      if (chosen != null && chosen.toLowerCase() == target.toLowerCase()) {
        correctCount++;
      }
    }

    final totalQuestions = _state.questions.length;
    final calculatedScore =
        (correctCount * 120) + (_state.hintsUsed == 0 ? 50 : 20);

    final session = GameSession(
      id: _uuid.v4(),
      gameType: GameType.whoIsThis,
      difficulty: _state.difficulty,
      score: calculatedScore,
      correctAnswers: correctCount,
      totalQuestions: totalQuestions,
      hintsUsed: _state.hintsUsed,
      durationSeconds: duration,
      completedAt: now,
      activityMetadata: {
        'questions_count': totalQuestions,
        'family_names': _state.questions.map((q) => q.name).toList(),
      },
    );

    _state = _state.copyWith(
      isCompleted: true,
      lastFeedback: session.supportiveFeedbackMessage,
    );

    return session;
  }
}
