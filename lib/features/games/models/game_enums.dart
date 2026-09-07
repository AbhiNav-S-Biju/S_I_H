// ==============================================================================
// NIRVANA - Game Domain Enums
// Description: Non-clinical game types and difficulty tiers
// ==============================================================================

/// The 3 cognitive engagement activity types in NIRVANA
enum GameType {
  rememberObjects,
  whoIsThis,
  groceryMemory;

  String get id {
    switch (this) {
      case GameType.rememberObjects:
        return 'remember_objects';
      case GameType.whoIsThis:
        return 'who_is_this';
      case GameType.groceryMemory:
        return 'grocery_memory';
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
}
