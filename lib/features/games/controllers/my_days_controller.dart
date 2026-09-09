// ==============================================================================
// NIRVANA - My Days Controller
// Description: Calm daily-routine engagement logic. Local-first, non-clinical.
// ==============================================================================

import 'dart:math';

import 'package:uuid/uuid.dart';

import '../models/daily_activity.dart';
import '../models/game_enums.dart';
import '../models/game_session.dart';

class MyDaysState {
  final GameDifficulty difficulty;
  final MyDaysMode? mode;
  final MyDaysPhase phase;
  final List<MyDaysRound> rounds;
  final int currentRoundIndex;
  final Set<String> selectedChoiceIds;
  final List<String> orderPicks;
  final int hintsUsed;
  final int correctAnswers;
  final int incorrectAttempts;
  final int currentStreak;
  final int bestStreak;
  final int attemptsThisRound;
  final bool scoredThisRound;
  final bool lastAnswerCorrect;
  final MyDaysFeedbackKind feedbackKind;
  final bool isCompleted;
  final DateTime startTime;
  final List<DailyActivity> shuffledOrderCards;

  const MyDaysState({
    required this.difficulty,
    required this.mode,
    required this.phase,
    required this.rounds,
    required this.currentRoundIndex,
    required this.selectedChoiceIds,
    required this.orderPicks,
    required this.hintsUsed,
    required this.correctAnswers,
    required this.incorrectAttempts,
    required this.currentStreak,
    required this.bestStreak,
    required this.attemptsThisRound,
    required this.scoredThisRound,
    required this.lastAnswerCorrect,
    required this.feedbackKind,
    required this.isCompleted,
    required this.startTime,
    required this.shuffledOrderCards,
  });

  MyDaysRound? get currentRound {
    if (rounds.isEmpty) return null;
    if (currentRoundIndex < 0 || currentRoundIndex >= rounds.length) {
      return null;
    }
    return rounds[currentRoundIndex];
  }

  int get totalRounds => rounds.length;

  int get roundsCompleted {
    if (phase == MyDaysPhase.results) return rounds.length;
    return currentRoundIndex;
  }

  MyDaysState copyWith({
    GameDifficulty? difficulty,
    MyDaysMode? mode,
    bool clearMode = false,
    MyDaysPhase? phase,
    List<MyDaysRound>? rounds,
    int? currentRoundIndex,
    Set<String>? selectedChoiceIds,
    List<String>? orderPicks,
    int? hintsUsed,
    int? correctAnswers,
    int? incorrectAttempts,
    int? currentStreak,
    int? bestStreak,
    int? attemptsThisRound,
    bool? scoredThisRound,
    bool? lastAnswerCorrect,
    MyDaysFeedbackKind? feedbackKind,
    bool? isCompleted,
    DateTime? startTime,
    List<DailyActivity>? shuffledOrderCards,
  }) {
    return MyDaysState(
      difficulty: difficulty ?? this.difficulty,
      mode: clearMode ? null : (mode ?? this.mode),
      phase: phase ?? this.phase,
      rounds: rounds ?? this.rounds,
      currentRoundIndex: currentRoundIndex ?? this.currentRoundIndex,
      selectedChoiceIds: selectedChoiceIds ?? this.selectedChoiceIds,
      orderPicks: orderPicks ?? this.orderPicks,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      incorrectAttempts: incorrectAttempts ?? this.incorrectAttempts,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      attemptsThisRound: attemptsThisRound ?? this.attemptsThisRound,
      scoredThisRound: scoredThisRound ?? this.scoredThisRound,
      lastAnswerCorrect: lastAnswerCorrect ?? this.lastAnswerCorrect,
      feedbackKind: feedbackKind ?? this.feedbackKind,
      isCompleted: isCompleted ?? this.isCompleted,
      startTime: startTime ?? this.startTime,
      shuffledOrderCards: shuffledOrderCards ?? this.shuffledOrderCards,
    );
  }
}

class MyDaysController {
  final List<DailyActivity> catalogue;
  final Random _random;
  final Uuid _uuid;

  late MyDaysState _state;
  MyDaysState get state => _state;

  MyDaysController({
    List<DailyActivity>? catalogue,
    Random? random,
    Uuid? uuid,
    GameDifficulty initialDifficulty = GameDifficulty.easy,
  }) : catalogue = catalogue ?? DailyActivity.catalogue,
       _random = random ?? Random(),
       _uuid = uuid ?? const Uuid() {
    startFresh(difficulty: initialDifficulty);
  }

  void startFresh({GameDifficulty? difficulty}) {
    final diff = difficulty ?? _stateOrDefaultDifficulty();
    _state = MyDaysState(
      difficulty: diff,
      mode: null,
      phase: MyDaysPhase.modeSelect,
      rounds: const [],
      currentRoundIndex: 0,
      selectedChoiceIds: {},
      orderPicks: const [],
      hintsUsed: 0,
      correctAnswers: 0,
      incorrectAttempts: 0,
      currentStreak: 0,
      bestStreak: 0,
      attemptsThisRound: 0,
      scoredThisRound: false,
      lastAnswerCorrect: false,
      feedbackKind: MyDaysFeedbackKind.none,
      isCompleted: false,
      startTime: DateTime.now(),
      shuffledOrderCards: const [],
    );
  }

  GameDifficulty _stateOrDefaultDifficulty() {
    try {
      return _state.difficulty;
    } catch (_) {
      return GameDifficulty.easy;
    }
  }

  /// Chooses a mode and builds a full set of calm rounds.
  void selectMode(MyDaysMode mode) {
    final rounds = _buildRounds(mode, _state.difficulty);
    if (rounds.isEmpty) {
      _state = _state.copyWith(
        mode: mode,
        phase: MyDaysPhase.results,
        rounds: const [],
        isCompleted: true,
      );
      return;
    }

    final first = rounds.first;
    final phase = mode == MyDaysMode.rememberMyDay
        ? MyDaysPhase.memorizing
        : MyDaysPhase.playing;

    _state = _state.copyWith(
      mode: mode,
      phase: phase,
      rounds: rounds,
      currentRoundIndex: 0,
      selectedChoiceIds: {},
      orderPicks: const [],
      attemptsThisRound: 0,
      scoredThisRound: false,
      lastAnswerCorrect: false,
      feedbackKind: MyDaysFeedbackKind.none,
      isCompleted: false,
      startTime: DateTime.now(),
      shuffledOrderCards: List<DailyActivity>.from(first.orderedActivities)
        ..shuffle(_random),
    );
  }

  void proceedToRecall() {
    if (_state.phase != MyDaysPhase.memorizing) return;
    _state = _state.copyWith(phase: MyDaysPhase.playing);
  }

  void selectChoice(String activityId) {
    final round = _state.currentRound;
    if (round == null) return;
    if (_state.phase != MyDaysPhase.playing) return;
    if (_state.mode == MyDaysMode.putInOrder) return;

    final exists = round.choices.any((c) => c.id == activityId);
    if (!exists) return;

    final correctId = round.correctAnswer?.id;
    final isCorrect = correctId != null && activityId == correctId;
    final attempts = _state.attemptsThisRound + 1;

    if (isCorrect) {
      var correct = _state.correctAnswers;
      var streak = _state.currentStreak;
      var scored = _state.scoredThisRound;
      if (!scored) {
        correct += 1;
        streak += 1;
        scored = true;
      }
      _state = _state.copyWith(
        selectedChoiceIds: {activityId},
        attemptsThisRound: attempts,
        scoredThisRound: scored,
        correctAnswers: correct,
        currentStreak: streak,
        bestStreak: max(_state.bestStreak, streak),
        lastAnswerCorrect: true,
        phase: MyDaysPhase.feedback,
        feedbackKind: round.mode == MyDaysMode.whatComesNext
            ? MyDaysFeedbackKind.nextCorrect
            : MyDaysFeedbackKind.rememberCorrect,
      );
      return;
    }

    var incorrect = _state.incorrectAttempts;
    var scored = _state.scoredThisRound;
    if (!scored) {
      incorrect += 1;
      scored = true;
    }

    final reveal = attempts >= 2;
    _state = _state.copyWith(
      selectedChoiceIds: {activityId},
      attemptsThisRound: attempts,
      scoredThisRound: scored,
      incorrectAttempts: incorrect,
      currentStreak: 0,
      lastAnswerCorrect: false,
      phase: reveal ? MyDaysPhase.feedback : MyDaysPhase.playing,
      feedbackKind: round.mode == MyDaysMode.whatComesNext
          ? MyDaysFeedbackKind.nextIncorrect
          : MyDaysFeedbackKind.rememberIncorrect,
    );
  }

  void tapOrderActivity(String activityId) {
    final round = _state.currentRound;
    if (round == null) return;
    if (_state.phase != MyDaysPhase.playing) return;
    if (_state.mode != MyDaysMode.putInOrder) return;
    if (_state.orderPicks.contains(activityId)) return;
    if (_state.orderPicks.length >= round.orderedActivities.length) return;

    final exists = round.orderedActivities.any((a) => a.id == activityId);
    if (!exists) return;

    _state = _state.copyWith(
      orderPicks: [..._state.orderPicks, activityId],
      feedbackKind: MyDaysFeedbackKind.none,
    );
  }

  void undoLastOrderPick() {
    if (_state.phase != MyDaysPhase.playing) return;
    if (_state.orderPicks.isEmpty) return;
    final updated = List<String>.from(_state.orderPicks)..removeLast();
    _state = _state.copyWith(orderPicks: updated);
  }

  void checkOrder() {
    final round = _state.currentRound;
    if (round == null) return;
    if (_state.phase != MyDaysPhase.playing) return;
    if (_state.mode != MyDaysMode.putInOrder) return;
    if (_state.orderPicks.length != round.orderedActivities.length) return;

    final expected = round.orderedActivities.map((a) => a.id).toList();
    final isCorrect = _listEquals(_state.orderPicks, expected);
    final attempts = _state.attemptsThisRound + 1;

    if (isCorrect) {
      var correct = _state.correctAnswers;
      var streak = _state.currentStreak;
      var scored = _state.scoredThisRound;
      if (!scored) {
        correct += 1;
        streak += 1;
        scored = true;
      }
      _state = _state.copyWith(
        attemptsThisRound: attempts,
        scoredThisRound: scored,
        correctAnswers: correct,
        currentStreak: streak,
        bestStreak: max(_state.bestStreak, streak),
        lastAnswerCorrect: true,
        phase: MyDaysPhase.feedback,
        feedbackKind: MyDaysFeedbackKind.orderCorrect,
      );
      return;
    }

    var incorrect = _state.incorrectAttempts;
    var scored = _state.scoredThisRound;
    if (!scored) {
      incorrect += 1;
      scored = true;
    }
    final reveal = attempts >= 2;
    _state = _state.copyWith(
      attemptsThisRound: attempts,
      scoredThisRound: scored,
      incorrectAttempts: incorrect,
      currentStreak: 0,
      lastAnswerCorrect: false,
      orderPicks: reveal ? expected : const [],
      phase: reveal ? MyDaysPhase.feedback : MyDaysPhase.playing,
      feedbackKind: MyDaysFeedbackKind.orderIncorrect,
    );
  }

  bool useHint() {
    final round = _state.currentRound;
    if (round == null) return false;
    if (_state.phase != MyDaysPhase.playing) return false;

    _state = _state.copyWith(hintsUsed: _state.hintsUsed + 1);

    if (_state.mode == MyDaysMode.putInOrder) {
      final nextIndex = _state.orderPicks.length;
      if (nextIndex < round.orderedActivities.length) {
        tapOrderActivity(round.orderedActivities[nextIndex].id);
      }
      return true;
    }

    final correctId = round.correctAnswer?.id;
    if (correctId != null) {
      selectChoice(correctId);
    }
    return true;
  }

  void replayRound() {
    final round = _state.currentRound;
    if (round == null) return;
    final phase = round.mode == MyDaysMode.rememberMyDay
        ? MyDaysPhase.memorizing
        : MyDaysPhase.playing;
    _state = _state.copyWith(
      phase: phase,
      selectedChoiceIds: {},
      orderPicks: const [],
      attemptsThisRound: 0,
      scoredThisRound: false,
      lastAnswerCorrect: false,
      feedbackKind: MyDaysFeedbackKind.none,
      shuffledOrderCards: List<DailyActivity>.from(round.orderedActivities)
        ..shuffle(_random),
    );
  }

  void continueAfterFeedback() {
    if (_state.phase != MyDaysPhase.feedback) return;
    final nextIndex = _state.currentRoundIndex + 1;
    if (nextIndex >= _state.rounds.length) {
      _state = _state.copyWith(
        phase: MyDaysPhase.results,
        isCompleted: true,
        currentRoundIndex: _state.rounds.length,
      );
      return;
    }

    final next = _state.rounds[nextIndex];
    final phase = next.mode == MyDaysMode.rememberMyDay
        ? MyDaysPhase.memorizing
        : MyDaysPhase.playing;
    _state = _state.copyWith(
      currentRoundIndex: nextIndex,
      phase: phase,
      selectedChoiceIds: {},
      orderPicks: const [],
      attemptsThisRound: 0,
      scoredThisRound: false,
      lastAnswerCorrect: false,
      feedbackKind: MyDaysFeedbackKind.none,
      shuffledOrderCards: List<DailyActivity>.from(next.orderedActivities)
        ..shuffle(_random),
    );
  }

  GameSession completeGame({DateTime? completionTime}) {
    final now = completionTime ?? DateTime.now();
    final duration = now.difference(_state.startTime).inSeconds.clamp(1, 7200);
    final total = _state.rounds.isEmpty ? 1 : _state.rounds.length;
    final correct = _state.correctAnswers.clamp(0, total);
    final score = (correct * 100) + (_state.hintsUsed == 0 ? 50 : 20);

    final session = GameSession(
      id: _uuid.v4(),
      gameType: GameType.myDays,
      difficulty: _state.difficulty,
      score: score,
      correctAnswers: correct,
      totalQuestions: total,
      hintsUsed: _state.hintsUsed,
      durationSeconds: duration,
      completedAt: now,
      activityMetadata: {
        'mode': _state.mode?.name ?? 'unknown',
        'incorrect_attempts': _state.incorrectAttempts,
        'best_streak': _state.bestStreak,
      },
    );

    _state = _state.copyWith(
      isCompleted: true,
      phase: MyDaysPhase.results,
    );
    return session;
  }

  List<MyDaysRound> _buildRounds(MyDaysMode mode, GameDifficulty difficulty) {
    if (catalogue.isEmpty) return const [];

    final count = difficulty.myDaysActivityCount;
    final choiceCount = difficulty.myDaysChoiceCount;
    final periods = TimeOfDayPeriod.values;
    final rounds = <MyDaysRound>[];

    for (final period in periods) {
      final sequence = catalogue.where((a) => a.timeOfDay == period).toList()
        ..sort((a, b) => a.orderInPeriod.compareTo(b.orderInPeriod));
      if (sequence.length < 2) continue;

      final take = min(count, sequence.length);
      final slice = sequence.take(take).toList();
      if (slice.length < 2) continue;

      switch (mode) {
        case MyDaysMode.whatComesNext:
          rounds.add(_buildNextRound(mode, difficulty, period, slice, choiceCount));
        case MyDaysMode.putInOrder:
          rounds.add(_buildOrderRound(mode, difficulty, period, slice));
        case MyDaysMode.rememberMyDay:
          rounds.add(
            _buildRememberRound(mode, difficulty, period, slice, choiceCount),
          );
      }
    }

    return rounds;
  }

  MyDaysRound _buildNextRound(
    MyDaysMode mode,
    GameDifficulty difficulty,
    TimeOfDayPeriod period,
    List<DailyActivity> slice,
    int choiceCount,
  ) {
    final prefix = slice.sublist(0, slice.length - 1);
    final correct = slice.last;
    final choices = _withDistractors(correct, choiceCount, excludePeriod: period);
    return MyDaysRound(
      id: _uuid.v4(),
      mode: mode,
      difficulty: difficulty,
      period: period,
      activities: slice,
      prefix: prefix,
      correctAnswer: correct,
      choices: choices,
      orderedActivities: slice,
    );
  }

  MyDaysRound _buildOrderRound(
    MyDaysMode mode,
    GameDifficulty difficulty,
    TimeOfDayPeriod period,
    List<DailyActivity> slice,
  ) {
    return MyDaysRound(
      id: _uuid.v4(),
      mode: mode,
      difficulty: difficulty,
      period: period,
      activities: slice,
      orderedActivities: slice,
      choices: slice,
    );
  }

  MyDaysRound _buildRememberRound(
    MyDaysMode mode,
    GameDifficulty difficulty,
    TimeOfDayPeriod period,
    List<DailyActivity> slice,
    int choiceCount,
  ) {
    final mentioned = slice[_random.nextInt(slice.length)];
    DailyActivity correct;
    final others = slice.where((a) => a.id != mentioned.id).toList();
    if (others.isNotEmpty && _random.nextBool()) {
      correct = others[_random.nextInt(others.length)];
    } else {
      correct = slice[_random.nextInt(slice.length)];
    }

    final choices = _withDistractors(
      correct,
      choiceCount,
      excludeIds: {mentioned.id},
      preferSamePeriod: difficulty == GameDifficulty.hard,
      period: period,
    );

    return MyDaysRound(
      id: _uuid.v4(),
      mode: mode,
      difficulty: difficulty,
      period: period,
      activities: slice,
      correctAnswer: correct,
      choices: choices,
      orderedActivities: slice,
      mentionedActivity: mentioned,
    );
  }

  List<DailyActivity> _withDistractors(
    DailyActivity correct,
    int choiceCount, {
    TimeOfDayPeriod? excludePeriod,
    Set<String> excludeIds = const {},
    bool preferSamePeriod = false,
    TimeOfDayPeriod? period,
  }) {
    final blocked = {...excludeIds, correct.id};
    var pool = catalogue.where((a) => !blocked.contains(a.id)).toList();
    if (excludePeriod != null) {
      final other = pool.where((a) => a.timeOfDay != excludePeriod).toList();
      if (other.length >= choiceCount - 1) pool = other;
    }
    if (preferSamePeriod && period != null) {
      final same = pool.where((a) => a.timeOfDay == period).toList();
      if (same.isNotEmpty) {
        pool = [...same, ...pool.where((a) => a.timeOfDay != period)];
      }
    }
    pool.shuffle(_random);
    final needed = max(0, choiceCount - 1);
    final distractors = pool.take(needed).toList();
    final choices = [correct, ...distractors]..shuffle(_random);
    return choices;
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
