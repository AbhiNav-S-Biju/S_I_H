// ==============================================================================
// NIRVANA - Jigsaw Puzzle Unit Tests
// Description: Tests difficulty scaling, error-tolerant placement, hints, landmarks,
// and progressive non-clinical adaptive difficulty.
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:nirvana/features/games/games.dart';

void main() {
  group('Jigsaw Puzzle Game Tests', () {
    test('Difficulty settings accurately generate 2, 4, and 6 pieces', () {
      final controllerEasy = JigsawPuzzleController(
        initialDifficulty: GameDifficulty.easy,
      );
      expect(controllerEasy.state.difficulty, equals(GameDifficulty.easy));
      expect(controllerEasy.state.rows, equals(1));
      expect(controllerEasy.state.cols, equals(2));
      expect(controllerEasy.state.totalPieces, equals(2));
      expect(controllerEasy.state.trayPieces.length, equals(2));

      final controllerMedium = JigsawPuzzleController(
        initialDifficulty: GameDifficulty.medium,
      );
      expect(controllerMedium.state.difficulty, equals(GameDifficulty.medium));
      expect(controllerMedium.state.rows, equals(2));
      expect(controllerMedium.state.cols, equals(2));
      expect(controllerMedium.state.totalPieces, equals(4));
      expect(controllerMedium.state.trayPieces.length, equals(4));

      final controllerHard = JigsawPuzzleController(
        initialDifficulty: GameDifficulty.hard,
      );
      expect(controllerHard.state.difficulty, equals(GameDifficulty.hard));
      expect(controllerHard.state.rows, equals(2));
      expect(controllerHard.state.cols, equals(3));
      expect(controllerHard.state.totalPieces, equals(6));
      expect(controllerHard.state.trayPieces.length, equals(6));
    });

    test('Initial state contains familiar image and landmark guidance', () {
      final controller = JigsawPuzzleController(
        initialImage: PuzzleImage.morningTea,
        initialDifficulty: GameDifficulty.easy,
      );

      expect(controller.state.activeImage.id, equals('puzzle_morning_tea'));
      expect(controller.state.placedPieceIds, isEmpty);
      expect(controller.state.isCompleted, isFalse);
      expect(controller.state.voicePrompt, isNotNull);
      expect(controller.state.voicePrompt!.isNotEmpty, isTrue);
    });

    test('Tap-to-place selection does not reveal target slot until hint requested', () {
      final controller = JigsawPuzzleController(
        initialDifficulty: GameDifficulty.easy,
      );

      final firstPiece = controller.state.trayPieces.first;
      controller.selectPieceInTray(firstPiece.id);

      expect(controller.state.selectedPieceId, equals(firstPiece.id));
      // Clinical rule: Selecting a piece in tray must NOT reveal where to place it
      expect(controller.state.highlightedSlotIndex, isNull);

      // Tapping same piece again deselects it
      controller.selectPieceInTray(firstPiece.id);
      expect(controller.state.selectedPieceId, isNull);
      expect(controller.state.highlightedSlotIndex, isNull);
    });

    test('Correct piece placement snaps piece and provides positive feedback', () {
      final controller = JigsawPuzzleController(
        initialDifficulty: GameDifficulty.easy,
      );

      final piece = controller.state.trayPieces.first;
      final success = controller.placePieceInSlot(
        piece.id,
        piece.row,
        piece.col,
      );

      expect(success, isTrue);
      expect(controller.state.placedPieceIds.contains(piece.id), isTrue);
      expect(controller.state.trayPieces.any((p) => p.id == piece.id), isFalse);
      expect(controller.state.isSlotFilled(piece.row, piece.col), isTrue);
      expect(controller.state.lastFeedback, isNotNull);
    });

    test('Misplaced attempt returns false and provides gentle non-punitive prompt', () {
      final controller = JigsawPuzzleController(
        initialDifficulty: GameDifficulty.easy,
      );

      final piece = controller.state.trayPieces.first;
      // Wrong row/col
      final wrongCol = (piece.col + 1) % controller.state.cols;
      final success = controller.placePieceInSlot(
        piece.id,
        piece.row,
        wrongCol,
      );

      expect(success, isFalse);
      expect(controller.state.placedPieceIds.contains(piece.id), isFalse);
      expect(controller.state.misplacedAttempts, equals(1));
      expect(controller.state.lastFeedback, equals('Take your time, let’s try another spot.'));
    });

    test('Repeated misplaces (3+) on Standard pace suggest a calmer pace', () {
      final controller = JigsawPuzzleController(
        initialDifficulty: GameDifficulty.medium,
      );

      final piece = controller.state.trayPieces.first;
      final wrongCol = (piece.col + 1) % controller.state.cols;

      // Make 3 misplaced attempts
      controller.placePieceInSlot(piece.id, piece.row, wrongCol);
      controller.placePieceInSlot(piece.id, piece.row, wrongCol);
      controller.placePieceInSlot(piece.id, piece.row, wrongCol);

      expect(controller.state.misplacedAttempts, equals(3));
      expect(
        controller.state.adaptiveDifficultySuggestion,
        equals(GameDifficulty.easy),
      );
    });

    test('Hint feature reveals next unplaced piece and pulses its slot', () {
      final controller = JigsawPuzzleController(
        initialDifficulty: GameDifficulty.easy,
      );

      expect(controller.state.hintsUsed, equals(0));
      final hint = controller.useHint();

      expect(hint.isNotEmpty, isTrue);
      expect(controller.state.hintsUsed, equals(1));
      expect(controller.state.selectedPieceId, isNotNull);
      expect(controller.state.highlightedSlotIndex, isNotNull);
    });

    test('Completing all pieces triggers completion and progressive difficulty', () {
      final controller = JigsawPuzzleController(
        initialDifficulty: GameDifficulty.easy,
      );

      // Place all pieces correctly
      final pieces = List<JigsawPiece>.from(controller.state.trayPieces);
      for (final p in pieces) {
        controller.placePieceInSlot(p.id, p.row, p.col);
      }

      expect(controller.state.isCompleted, isTrue);
      expect(controller.state.placedCount, equals(controller.state.totalPieces));
      expect(controller.state.consecutiveSuccessCount, equals(1));

      // Starting next game and completing it reaches 2 consecutive successes
      controller.startNewGame(
        difficulty: GameDifficulty.easy,
        consecutiveSuccessCount: 1,
      );
      final secondRoundPieces = List<JigsawPiece>.from(controller.state.trayPieces);
      for (final p in secondRoundPieces) {
        controller.placePieceInSlot(p.id, p.row, p.col);
      }

      expect(controller.state.consecutiveSuccessCount, equals(2));
      expect(
        controller.state.adaptiveDifficultySuggestion,
        equals(GameDifficulty.medium),
      );
    });

    test('completeGame() generates valid GameSession with safe non-clinical metadata', () {
      final controller = JigsawPuzzleController(
        initialDifficulty: GameDifficulty.easy,
      );

      for (final p in List<JigsawPiece>.from(controller.state.trayPieces)) {
        controller.placePieceInSlot(p.id, p.row, p.col);
      }

      final session = controller.completeGame();

      expect(session.gameType, equals(GameType.jigsawPuzzle));
      expect(session.difficulty, equals(GameDifficulty.easy));
      expect(session.totalQuestions, equals(2));
      expect(session.correctAnswers, equals(2));
      expect(session.completionRate, equals(1.0));
      expect(session.activityMetadata['pieces_count'], equals(2));
      expect(session.activityMetadata['image_id'], equals(controller.state.activeImage.id));
    });

    test('Image switching updates active scene cleanly', () {
      final controller = JigsawPuzzleController(
        initialImage: PuzzleImage.morningTea,
      );

      expect(controller.state.activeImage.id, equals('puzzle_morning_tea'));
      controller.changeImage(PuzzleImage.courtyardGarden);

      expect(controller.state.activeImage.id, equals('puzzle_courtyard_garden'));
      expect(controller.state.placedPieceIds, isEmpty);
      expect(controller.state.trayPieces.length, equals(2));
    });
  });
}
