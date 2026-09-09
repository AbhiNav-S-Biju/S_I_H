// ==============================================================================
// NIRVANA - Jigsaw Puzzle Controller
// Description: Pure business logic & state manager for Dementia-Friendly Jigsaw
// ==============================================================================

import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/game_enums.dart';
import '../models/game_session.dart';
import '../models/puzzle_item.dart';

/// Represents an individual puzzle piece
class JigsawPiece {
  final int id;
  final int row;
  final int col;
  final bool isPlaced;

  const JigsawPiece({
    required this.id,
    required this.row,
    required this.col,
    this.isPlaced = false,
  });

  JigsawPiece copyWith({bool? isPlaced}) {
    return JigsawPiece(
      id: id,
      row: row,
      col: col,
      isPlaced: isPlaced ?? this.isPlaced,
    );
  }
}

/// Immutable state for the Jigsaw Puzzle activity
class JigsawPuzzleState {
  final GameDifficulty difficulty;
  final PuzzleImage activeImage;
  final int rows;
  final int cols;
  final List<JigsawPiece> allPieces;
  final List<JigsawPiece> trayPieces;
  final Set<int> placedPieceIds;
  final int? selectedPieceId;
  final int? highlightedSlotIndex;
  final int hintsUsed;
  final int misplacedAttempts;
  final int consecutiveSuccessCount;
  final GameDifficulty? adaptiveDifficultySuggestion;
  final bool isCompleted;
  final DateTime startTime;
  final String? lastFeedback;
  final String? voicePrompt;

  const JigsawPuzzleState({
    required this.difficulty,
    required this.activeImage,
    required this.rows,
    required this.cols,
    required this.allPieces,
    required this.trayPieces,
    required this.placedPieceIds,
    this.selectedPieceId,
    this.highlightedSlotIndex,
    required this.hintsUsed,
    required this.misplacedAttempts,
    required this.consecutiveSuccessCount,
    this.adaptiveDifficultySuggestion,
    required this.isCompleted,
    required this.startTime,
    this.lastFeedback,
    this.voicePrompt,
  });

  int get totalPieces => rows * cols;
  int get placedCount => placedPieceIds.length;
  bool isSlotFilled(int r, int c) {
    return allPieces.any(
      (p) => p.row == r && p.col == c && placedPieceIds.contains(p.id),
    );
  }

  JigsawPiece? getPieceAtSlot(int r, int c) {
    return allPieces
        .where(
          (p) => p.row == r && p.col == c && placedPieceIds.contains(p.id),
        )
        .firstOrNull;
  }

  JigsawPuzzleState copyWith({
    GameDifficulty? difficulty,
    PuzzleImage? activeImage,
    int? rows,
    int? cols,
    List<JigsawPiece>? allPieces,
    List<JigsawPiece>? trayPieces,
    Set<int>? placedPieceIds,
    int? selectedPieceId,
    bool clearSelectedPieceId = false,
    int? highlightedSlotIndex,
    bool clearHighlightedSlotIndex = false,
    int? hintsUsed,
    int? misplacedAttempts,
    int? consecutiveSuccessCount,
    GameDifficulty? adaptiveDifficultySuggestion,
    bool clearAdaptiveSuggestion = false,
    bool? isCompleted,
    DateTime? startTime,
    String? lastFeedback,
    String? voicePrompt,
  }) {
    return JigsawPuzzleState(
      difficulty: difficulty ?? this.difficulty,
      activeImage: activeImage ?? this.activeImage,
      rows: rows ?? this.rows,
      cols: cols ?? this.cols,
      allPieces: allPieces ?? this.allPieces,
      trayPieces: trayPieces ?? this.trayPieces,
      placedPieceIds: placedPieceIds ?? this.placedPieceIds,
      selectedPieceId: clearSelectedPieceId
          ? null
          : (selectedPieceId ?? this.selectedPieceId),
      highlightedSlotIndex: clearHighlightedSlotIndex
          ? null
          : (highlightedSlotIndex ?? this.highlightedSlotIndex),
      hintsUsed: hintsUsed ?? this.hintsUsed,
      misplacedAttempts: misplacedAttempts ?? this.misplacedAttempts,
      consecutiveSuccessCount:
          consecutiveSuccessCount ?? this.consecutiveSuccessCount,
      adaptiveDifficultySuggestion: clearAdaptiveSuggestion
          ? null
          : (adaptiveDifficultySuggestion ?? this.adaptiveDifficultySuggestion),
      isCompleted: isCompleted ?? this.isCompleted,
      startTime: startTime ?? this.startTime,
      lastFeedback: lastFeedback ?? this.lastFeedback,
      voicePrompt: voicePrompt ?? this.voicePrompt,
    );
  }
}

/// Business logic controller for Jigsaw Puzzle
class JigsawPuzzleController {
  final List<PuzzleImage> availableImages;
  final Random _random;
  final Uuid _uuid;

  late JigsawPuzzleState _state;
  JigsawPuzzleState get state => _state;

  /// Global non-repeating randomized cycle manager across activity launches
  static final List<String> _globalShuffledCycleIds = [];
  static int _globalCycleCursor = 0;
  static String? _globalLastOpenedImageId;

  /// Visible for testing: resets the static cycle
  static void resetCycleForTesting() {
    _globalShuffledCycleIds.clear();
    _globalCycleCursor = 0;
    _globalLastOpenedImageId = null;
  }

  /// Obtains the next random picture from a randomized shuffled sequence,
  /// guaranteeing that the picture changes every single time the activity is opened
  /// and never repeats consecutively.
  static PuzzleImage getNextRotatingImage({
    List<PuzzleImage>? pool,
    Random? rng,
  }) {
    final images = pool ?? PuzzleImage.defaultFamiliarImages;
    if (images.isEmpty) return PuzzleImage.defaultFamiliarImages.first;
    if (images.length == 1) return images.first;

    final random = rng ?? Random();

    // If cycle is empty or exhausted, generate a new shuffled permutation
    if (_globalShuffledCycleIds.isEmpty ||
        _globalCycleCursor >= _globalShuffledCycleIds.length) {
      final ids = images.map((img) => img.id).toList()..shuffle(random);

      // Ensure the first image in the new cycle is not the same as the last seen image
      if (_globalLastOpenedImageId != null &&
          ids.first == _globalLastOpenedImageId &&
          ids.length > 1) {
        final swapIdx = 1 + random.nextInt(ids.length - 1);
        final temp = ids[0];
        ids[0] = ids[swapIdx];
        ids[swapIdx] = temp;
      }

      _globalShuffledCycleIds
        ..clear()
        ..addAll(ids);
      _globalCycleCursor = 0;
    }

    final nextId = _globalShuffledCycleIds[_globalCycleCursor++];
    _globalLastOpenedImageId = nextId;

    return images.firstWhere(
      (img) => img.id == nextId,
      orElse: () => images.first,
    );
  }

  JigsawPuzzleController({
    List<PuzzleImage>? images,
    Random? random,
    Uuid? uuid,
    GameDifficulty initialDifficulty = GameDifficulty.easy,
    PuzzleImage? initialImage,
  })  : availableImages = images ?? PuzzleImage.defaultFamiliarImages,
        _random = random ?? Random(),
        _uuid = uuid ?? const Uuid() {
    // If initialImage is not explicitly specified, obtain the next rotating random image
    // ensuring that every time the activity is opened, a different picture is presented.
    final chosenImage = initialImage ??
        getNextRotatingImage(pool: availableImages, rng: _random);
    _globalLastOpenedImageId = chosenImage.id;

    startNewGame(
      difficulty: initialDifficulty,
      image: chosenImage,
    );
  }

  /// Randomly selects a different familiar scene for variety
  PuzzleImage pickRandomImage({bool avoidCurrent = true}) {
    final newImage =
        getNextRotatingImage(pool: availableImages, rng: _random);
    changeImage(newImage);
    return newImage;
  }

  /// Initializes a new puzzle round with chosen difficulty and image
  void startNewGame({
    GameDifficulty difficulty = GameDifficulty.easy,
    PuzzleImage? image,
    int consecutiveSuccessCount = 0,
  }) {
    final activeImg = image ?? _stateOrRandom();
    final rows = difficulty.jigsawRows;
    final cols = difficulty.jigsawCols;

    final pieces = <JigsawPiece>[];
    int idCounter = 0;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        pieces.add(JigsawPiece(id: idCounter++, row: r, col: c));
      }
    }

    // Shuffled unplaced tray pieces
    final trayPieces = List<JigsawPiece>.from(pieces)..shuffle(_random);

    final initialPrompt = activeImg.getLandmarkClue(
      row: trayPieces.first.row,
      col: trayPieces.first.col,
      totalRows: rows,
      totalCols: cols,
      langCode: 'en',
    );

    _state = JigsawPuzzleState(
      difficulty: difficulty,
      activeImage: activeImg,
      rows: rows,
      cols: cols,
      allPieces: pieces,
      trayPieces: trayPieces,
      placedPieceIds: {},
      hintsUsed: 0,
      misplacedAttempts: 0,
      consecutiveSuccessCount: consecutiveSuccessCount,
      isCompleted: false,
      startTime: DateTime.now(),
      voicePrompt: initialPrompt,
    );
  }

  PuzzleImage _stateOrRandom() {
    try {
      return _state.activeImage;
    } catch (_) {
      return getNextRotatingImage(pool: availableImages, rng: _random);
    }
  }

  /// Selects a piece in the tray (for tap-to-place mode)
  void selectPieceInTray(int pieceId, {String langCode = 'en'}) {
    if (_state.isCompleted) return;

    // Tapping already selected piece unselects it
    if (_state.selectedPieceId == pieceId) {
      _state = _state.copyWith(
        clearSelectedPieceId: true,
        clearHighlightedSlotIndex: true,
      );
      return;
    }

    final piece = _state.trayPieces.where((p) => p.id == pieceId).firstOrNull;
    if (piece == null) return;

    final landmark = _state.activeImage.getLandmarkClue(
      row: piece.row,
      col: piece.col,
      totalRows: _state.rows,
      totalCols: _state.cols,
      langCode: langCode,
    );

    // IMPORTANT: Do NOT reveal target slot on tray selection.
    // The patient must choose where to place the piece themselves.
    // The target slot is ONLY revealed when the patient explicitly requests a Hint.
    _state = _state.copyWith(
      selectedPieceId: pieceId,
      clearHighlightedSlotIndex: true,
      voicePrompt: landmark,
    );
  }

  /// Places a piece into a board slot at (slotRow, slotCol)
  /// Returns true if successfully matched and placed
  bool placePieceInSlot(
    int pieceId,
    int slotRow,
    int slotCol, {
    String langCode = 'en',
  }) {
    if (_state.isCompleted) return false;

    final piece = _state.trayPieces.where((p) => p.id == pieceId).firstOrNull;
    if (piece == null) return false;

    // Check if slot coordinates match piece target
    final isMatch = piece.row == slotRow && piece.col == slotCol;

    if (isMatch) {
      final updatedPlaced = Set<int>.from(_state.placedPieceIds)..add(pieceId);
      final updatedTray =
          _state.trayPieces.where((p) => p.id != pieceId).toList();
      final isNowCompleted = updatedPlaced.length == _state.totalPieces;

      // Positive reinforcement
      final positiveClues = [
        'Wonderful!',
        'You’re doing great!',
        'Fits just right!',
        'That looks lovely.',
      ];
      final feedback = positiveClues[_random.nextInt(positiveClues.length)];

      GameDifficulty? nextSuggestion;
      int nextSuccessCount = _state.consecutiveSuccessCount;

      if (isNowCompleted) {
        nextSuccessCount += 1;
        // Progressive difficulty check: 2 consecutive smooth puzzles offers next tier
        if (nextSuccessCount >= 2 && _state.difficulty != GameDifficulty.hard) {
          nextSuggestion = _state.difficulty == GameDifficulty.easy
              ? GameDifficulty.medium
              : GameDifficulty.hard;
        }
      }

      // If next unplaced piece exists, prepare landmark clue
      String? nextClue;
      if (!isNowCompleted && updatedTray.isNotEmpty) {
        final nextUnplaced = updatedTray.first;
        nextClue = _state.activeImage.getLandmarkClue(
          row: nextUnplaced.row,
          col: nextUnplaced.col,
          totalRows: _state.rows,
          totalCols: _state.cols,
          langCode: langCode,
        );
      }

      _state = _state.copyWith(
        placedPieceIds: updatedPlaced,
        trayPieces: updatedTray,
        clearSelectedPieceId: true,
        clearHighlightedSlotIndex: true,
        isCompleted: isNowCompleted,
        consecutiveSuccessCount: nextSuccessCount,
        adaptiveDifficultySuggestion: nextSuggestion,
        lastFeedback: feedback,
        voicePrompt: nextClue ?? feedback,
      );

      return true;
    } else {
      // Gentle, non-judgmental response for misplacement
      final misplaces = _state.misplacedAttempts + 1;
      final gentlePrompt = 'Take your time, let’s try another spot.';

      GameDifficulty? calmerPaceSuggestion;
      // If struggling repeatedly on medium/hard (3+ misplaced drops)
      if (misplaces >= 3 && _state.difficulty != GameDifficulty.easy) {
        calmerPaceSuggestion = GameDifficulty.easy;
      }

      _state = _state.copyWith(
        clearSelectedPieceId: true,
        clearHighlightedSlotIndex: true,
        misplacedAttempts: misplaces,
        adaptiveDifficultySuggestion: calmerPaceSuggestion,
        lastFeedback: gentlePrompt,
        voicePrompt: gentlePrompt,
      );

      return false;
    }
  }

  /// Triggers a gentle hint: highlights the next unplaced piece and its target slot
  String useHint({String langCode = 'en'}) {
    if (_state.isCompleted || _state.trayPieces.isEmpty) {
      return 'You’ve placed all the pieces!';
    }

    final piece = _state.trayPieces.first;
    final slotIndex = piece.row * _state.cols + piece.col;
    final landmark = _state.activeImage.getLandmarkClue(
      row: piece.row,
      col: piece.col,
      totalRows: _state.rows,
      totalCols: _state.cols,
      langCode: langCode,
    );

    _state = _state.copyWith(
      selectedPieceId: piece.id,
      highlightedSlotIndex: slotIndex,
      hintsUsed: _state.hintsUsed + 1,
      voicePrompt: landmark,
      lastFeedback: landmark,
    );

    return landmark;
  }

  /// Changes active familiar scene
  void changeImage(PuzzleImage image) {
    _globalLastOpenedImageId = image.id;
    startNewGame(
      difficulty: _state.difficulty,
      image: image,
      consecutiveSuccessCount: _state.consecutiveSuccessCount,
    );
  }

  /// Switches difficulty pace
  void changeDifficulty(GameDifficulty newDifficulty) {
    startNewGame(
      difficulty: newDifficulty,
      image: _state.activeImage,
      consecutiveSuccessCount: 0,
    );
  }

  /// Finalizes completed game session for safe non-clinical telemetry
  GameSession completeGame() {
    final now = DateTime.now();
    final duration = now.difference(_state.startTime).inSeconds.clamp(5, 3600);

    return GameSession(
      id: _uuid.v4(),
      gameType: GameType.jigsawPuzzle,
      difficulty: _state.difficulty,
      score: _state.placedCount * 10,
      correctAnswers: _state.placedCount,
      totalQuestions: _state.totalPieces,
      hintsUsed: _state.hintsUsed,
      durationSeconds: duration,
      completedAt: now,
      activityMetadata: {
        'image_id': _state.activeImage.id,
        'image_title': _state.activeImage.title,
        'pieces_count': _state.totalPieces,
        'misplaced_attempts': _state.misplacedAttempts,
        'consecutive_success': _state.consecutiveSuccessCount,
      },
    );
  }
}
