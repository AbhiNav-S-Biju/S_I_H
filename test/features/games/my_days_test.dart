// ==============================================================================
// NIRVANA - My Days Unit Tests
// Tests: modes, difficulty, scoring, replay, empty data, session metadata
// ==============================================================================

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nirvana/features/games/games.dart';

void main() {
  group('My Days Game Tests', () {
    test('builds four rounds covering morning through night', () {
      final controller = MyDaysController(random: Random(7));
      controller.selectMode(MyDaysMode.whatComesNext);

      expect(controller.state.rounds.length, equals(4));
      expect(
        controller.state.rounds.map((r) => r.period).toSet(),
        equals({
          TimeOfDayPeriod.morning,
          TimeOfDayPeriod.afternoon,
          TimeOfDayPeriod.evening,
          TimeOfDayPeriod.night,
        }),
      );
    });

    test('difficulty changes activity counts', () {
      final easy = MyDaysController(
        random: Random(1),
        initialDifficulty: GameDifficulty.easy,
      )..selectMode(MyDaysMode.putInOrder);
      expect(easy.state.currentRound!.orderedActivities.length, equals(3));

      final medium = MyDaysController(
        random: Random(1),
        initialDifficulty: GameDifficulty.medium,
      )..selectMode(MyDaysMode.putInOrder);
      expect(medium.state.currentRound!.orderedActivities.length, equals(4));

      final hard = MyDaysController(
        random: Random(1),
        initialDifficulty: GameDifficulty.hard,
      )..selectMode(MyDaysMode.putInOrder);
      expect(hard.state.currentRound!.orderedActivities.length, equals(5));
    });

    test('What Comes Next: correct choice completes the round gently', () {
      final controller = MyDaysController(random: Random(3));
      controller.selectMode(MyDaysMode.whatComesNext);
      final correctId = controller.state.currentRound!.correctAnswer!.id;

      controller.selectChoice('missing_id');
      expect(controller.state.selectedChoiceIds, isEmpty);

      controller.selectChoice(correctId);
      expect(controller.state.phase, equals(MyDaysPhase.feedback));
      expect(controller.state.lastAnswerCorrect, isTrue);
      expect(controller.state.correctAnswers, equals(1));
    });

    test('What Comes Next: wrong answers can be retried without punishment tone', () {
      final controller = MyDaysController(random: Random(3));
      controller.selectMode(MyDaysMode.whatComesNext);
      final wrong = controller.state.currentRound!.choices.firstWhere(
        (c) => c.id != controller.state.currentRound!.correctAnswer!.id,
      );

      controller.selectChoice(wrong.id);
      expect(controller.state.phase, equals(MyDaysPhase.playing));
      expect(controller.state.incorrectAttempts, equals(1));
      expect(controller.state.feedbackKind, equals(MyDaysFeedbackKind.nextIncorrect));

      controller.selectChoice(wrong.id);
      expect(controller.state.phase, equals(MyDaysPhase.feedback));
      expect(controller.state.lastAnswerCorrect, isFalse);
    });

    test('Put My Day in Order: tap order, undo, and check', () {
      final controller = MyDaysController(random: Random(11));
      controller.selectMode(MyDaysMode.putInOrder);
      final ordered = controller.state.currentRound!.orderedActivities;

      controller.checkOrder();
      expect(controller.state.phase, equals(MyDaysPhase.playing));

      controller.tapOrderActivity(ordered.last.id);
      expect(controller.state.orderPicks, equals([ordered.last.id]));
      controller.undoLastOrderPick();
      expect(controller.state.orderPicks, isEmpty);

      for (final activity in ordered) {
        controller.tapOrderActivity(activity.id);
      }
      controller.checkOrder();
      expect(controller.state.phase, equals(MyDaysPhase.feedback));
      expect(controller.state.lastAnswerCorrect, isTrue);
    });

    test('Remember My Day starts in memorization then recall', () {
      final controller = MyDaysController(random: Random(5));
      controller.selectMode(MyDaysMode.rememberMyDay);
      expect(controller.state.phase, equals(MyDaysPhase.memorizing));

      controller.selectChoice(controller.state.currentRound!.choices.first.id);
      expect(controller.state.phase, equals(MyDaysPhase.memorizing));

      controller.proceedToRecall();
      expect(controller.state.phase, equals(MyDaysPhase.playing));

      final correctId = controller.state.currentRound!.correctAnswer!.id;
      controller.selectChoice(correctId);
      expect(controller.state.lastAnswerCorrect, isTrue);
    });

    test('continueAfterFeedback walks all rounds then results', () {
      final controller = MyDaysController(random: Random(9));
      controller.selectMode(MyDaysMode.whatComesNext);

      for (var i = 0; i < 4; i++) {
        final correctId = controller.state.currentRound!.correctAnswer!.id;
        controller.selectChoice(correctId);
        controller.continueAfterFeedback();
      }

      expect(controller.state.phase, equals(MyDaysPhase.results));
      final session = controller.completeGame();
      expect(session.gameType, equals(GameType.myDays));
      expect(session.correctAnswers, equals(4));
      expect(session.totalQuestions, equals(4));
      expect(session.supportiveFeedbackMessage.toLowerCase(), isNot(contains('fail')));
      expect(session.supportiveFeedbackMessage.toLowerCase(), isNot(contains('diagnos')));
    });

    test('replayRound and startFresh reset play state', () {
      final controller = MyDaysController(random: Random(2));
      controller.selectMode(MyDaysMode.whatComesNext);
      controller.selectChoice(controller.state.currentRound!.correctAnswer!.id);
      expect(controller.state.phase, equals(MyDaysPhase.feedback));

      controller.replayRound();
      expect(controller.state.phase, equals(MyDaysPhase.playing));
      expect(controller.state.selectedChoiceIds, isEmpty);

      controller.startFresh();
      expect(controller.state.phase, equals(MyDaysPhase.modeSelect));
      expect(controller.state.correctAnswers, equals(0));
      expect(controller.state.mode, isNull);
    });

    test('empty catalogue never throws and completes safely', () {
      final controller = MyDaysController(catalogue: const []);
      controller.selectMode(MyDaysMode.putInOrder);
      expect(controller.state.phase, equals(MyDaysPhase.results));
      final session = controller.completeGame();
      expect(session.gameType, equals(GameType.myDays));
      expect(session.totalQuestions, greaterThan(0));
    });
  });
}
