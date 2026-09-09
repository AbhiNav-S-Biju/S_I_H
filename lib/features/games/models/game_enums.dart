// ==============================================================================
// NIRVANA - Game Domain Enums
// Description: Non-clinical game types and difficulty tiers
// ==============================================================================

import '../../../l10n/app_localizations.dart';

/// The 3 cognitive engagement activity types in NIRVANA
enum GameType {
  rememberObjects,
  whoIsThis,
  groceryMemory,
  jigsawPuzzle,
  myDays;

  String get id {
    switch (this) {
      case GameType.rememberObjects:
        return 'remember_objects';
      case GameType.whoIsThis:
        return 'who_is_this';
      case GameType.groceryMemory:
        return 'grocery_memory';
      case GameType.jigsawPuzzle:
        return 'jigsaw_puzzle';
      case GameType.myDays:
        return 'my_days';
    }
  }

  String get displayName {
    switch (this) {
      case GameType.rememberObjects:
        return 'Remember Objects';
      case GameType.whoIsThis:
        return 'Who Is This?';
      case GameType.groceryMemory:
        return 'Grocery Memory';
      case GameType.jigsawPuzzle:
        return 'Familiar Jigsaw';
      case GameType.myDays:
        return 'My Days';
    }
  }

  String get subtitle {
    switch (this) {
      case GameType.rememberObjects:
        return 'Look at the friendly items, then tap what you saw';
      case GameType.whoIsThis:
        return 'Recognize familiar faces and loved ones';
      case GameType.groceryMemory:
        return 'Collect everyday items from your shopping list';
      case GameType.jigsawPuzzle:
        return 'Put together comforting pictures piece by piece';
      case GameType.myDays:
        return 'Gentle activities about a familiar daily routine';
    }
  }

  String localizedTitle(AppLocalizations? l10n) {
    if (l10n == null) return displayName;
    switch (this) {
      case GameType.rememberObjects:
        return l10n.gameRememberObjectsTitle;
      case GameType.whoIsThis:
        return l10n.gameWhoIsThisTitle;
      case GameType.groceryMemory:
        return l10n.gameGroceryMemoryTitle;
      case GameType.jigsawPuzzle:
        return l10n.gameJigsawPuzzleTitle;
      case GameType.myDays:
        return l10n.gameMyDaysTitle;
    }
  }

  String localizedSubtitle(AppLocalizations? l10n) {
    if (l10n == null) return subtitle;
    switch (this) {
      case GameType.rememberObjects:
        return l10n.gameRememberObjectsSubtitle;
      case GameType.whoIsThis:
        return l10n.gameWhoIsThisSubtitle;
      case GameType.groceryMemory:
        return l10n.gameGroceryMemorySubtitle;
      case GameType.jigsawPuzzle:
        return l10n.gameJigsawPuzzleSubtitle;
      case GameType.myDays:
        return l10n.gameMyDaysSubtitle;
    }
  }
}

/// Difficulty settings designed for accessibility
enum GameDifficulty {
  easy,
  medium,
  hard;

  String get id => name;

  String get label {
    switch (this) {
      case GameDifficulty.easy:
        return 'Gentle';
      case GameDifficulty.medium:
        return 'Standard';
      case GameDifficulty.hard:
        return 'Challenge';
    }
  }

  String localizedLabel(AppLocalizations? l10n) {
    if (l10n == null) return label;
    switch (this) {
      case GameDifficulty.easy:
        return l10n.paceGentle;
      case GameDifficulty.medium:
        return l10n.paceStandard;
      case GameDifficulty.hard:
        return l10n.paceChallenge;
    }
  }

  /// Number of items to remember in Remember Objects
  int get rememberObjectsCount {
    switch (this) {
      case GameDifficulty.easy:
        return 3;
      case GameDifficulty.medium:
        return 4;
      case GameDifficulty.hard:
        return 5;
    }
  }

  /// Total options displayed in selection grid for Remember Objects
  int get rememberObjectsTotalOptions {
    switch (this) {
      case GameDifficulty.easy:
        return 6;
      case GameDifficulty.medium:
        return 8;
      case GameDifficulty.hard:
        return 10;
    }
  }

  /// Number of grocery items in Grocery Memory list
  int get groceryItemsCount {
    switch (this) {
      case GameDifficulty.easy:
        return 3;
      case GameDifficulty.medium:
        return 4;
      case GameDifficulty.hard:
        return 5;
    }
  }

  /// Total shelf items to pick from in Grocery Memory
  int get groceryShelfCount {
    switch (this) {
      case GameDifficulty.easy:
        return 6;
      case GameDifficulty.medium:
        return 8;
      case GameDifficulty.hard:
        return 10;
    }
  }

  /// Number of questions in "Who Is This?"
  int get whoIsThisQuestionCount {
    switch (this) {
      case GameDifficulty.easy:
        return 2;
      case GameDifficulty.medium:
        return 3;
      case GameDifficulty.hard:
        return 4;
    }
  }

  /// Grid rows for Dementia-Friendly Jigsaw Puzzle
  int get jigsawRows {
    switch (this) {
      case GameDifficulty.easy:
        return 1;
      case GameDifficulty.medium:
        return 2;
      case GameDifficulty.hard:
        return 2;
    }
  }

  /// Grid columns for Dementia-Friendly Jigsaw Puzzle
  int get jigsawCols {
    switch (this) {
      case GameDifficulty.easy:
        return 2;
      case GameDifficulty.medium:
        return 2;
      case GameDifficulty.hard:
        return 3;
    }
  }

  /// Total piece count for Jigsaw Puzzle (2 in Easy, 4 in Medium, 6 in Hard)
  int get jigsawPieceCount => jigsawRows * jigsawCols;

  /// Number of familiar daily activities used in My Days
  int get myDaysActivityCount {
    switch (this) {
      case GameDifficulty.easy:
        return 3;
      case GameDifficulty.medium:
        return 4;
      case GameDifficulty.hard:
        return 5;
    }
  }

  /// Number of large answer choices in My Days
  int get myDaysChoiceCount {
    switch (this) {
      case GameDifficulty.easy:
        return 3;
      case GameDifficulty.medium:
        return 4;
      case GameDifficulty.hard:
        return 4;
    }
  }

  /// Memorization wait for Remember My Day. Easy has no auto-hide.
  Duration get myDaysMemorizeDuration {
    switch (this) {
      case GameDifficulty.easy:
        return Duration.zero;
      case GameDifficulty.medium:
        return const Duration(seconds: 8);
      case GameDifficulty.hard:
        return const Duration(seconds: 5);
    }
  }
}
