// ==============================================================================
// NIRVANA - Game Progress Service
// Description: Offline-first persistence for game level progression and stars
// ==============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/game_enums.dart';
import '../models/game_level.dart';

/// Riverpod provider for GameProgressService
final gameProgressServiceProvider = Provider<GameProgressService>((ref) {
  return GameProgressService.instance;
});

/// Riverpod provider for a specific game's level progress map
final gameLevelProgressProvider =
    StateNotifierProvider.family<GameLevelNotifier, Map<int, GameLevelProgress>, GameType>(
  (ref, gameType) {
    final service = ref.watch(gameProgressServiceProvider);
    return GameLevelNotifier(service, gameType);
  },
);

class GameLevelNotifier extends StateNotifier<Map<int, GameLevelProgress>> {
  final GameProgressService _service;
  final GameType _gameType;

  GameLevelNotifier(this._service, this._gameType)
      : super(_service.getLevelProgressMap(_gameType)) {
    _service.addListener(_onServiceChanged);
  }

  void _onServiceChanged() {
    state = _service.getLevelProgressMap(_gameType);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    super.dispose();
  }
}

/// Service managing offline persistence of level maps and milestone stars
class GameProgressService extends ChangeNotifier {
  GameProgressService._();
  static final GameProgressService instance = GameProgressService._();

  static const String _boxName = 'nirvana_game_levels';
  Box? _box;

  // In-memory cache: GameType -> LevelNumber -> GameLevelProgress
  final Map<GameType, Map<int, GameLevelProgress>> _cache = {};
  // In-memory completion dates: GameType -> DateTime
  final Map<GameType, DateTime> _allCompletedDates = {};

  bool _initialized = false;

  /// Initializes the storage box if available
  Future<void> init() async {
    if (_initialized) return;
    try {
      if (Hive.isBoxOpen(_boxName)) {
        _box = Hive.box(_boxName);
      } else {
        _box = await Hive.openBox(_boxName);
      }
      _loadFromBox();
    } catch (e) {
      debugPrint('⚠️ GameProgressService: Running in-memory mode ($e)');
    }
    _initialized = true;
  }

  void _loadFromBox() {
    if (_box == null) return;
    for (final type in GameType.values) {
      final gameMap = <int, GameLevelProgress>{};
      for (int lvl = 1; lvl <= 8; lvl++) {
        final key = '${type.name}_level_$lvl';
        final raw = _box!.get(key);
        if (raw != null && raw is Map) {
          gameMap[lvl] = GameLevelProgress.fromMap(raw.cast<String, dynamic>());
        } else {
          gameMap[lvl] = GameLevelProgress.initial(lvl);
        }
      }
      _cache[type] = gameMap;

      // Load all-completed date if available
      final compDateRaw = _box!.get('${type.name}_all_completed_date');
      if (compDateRaw is String) {
        final parsed = DateTime.tryParse(compDateRaw);
        if (parsed != null) {
          _allCompletedDates[type] = parsed;
        }
      }

      // Check if this game was completed on a previous day and needs daily reset
      checkAndPerformDailyReset(type);
    }
  }

  /// Checks if all 8 levels have been completed for a game type
  bool areAllLevelsCompleted(GameType gameType) {
    final map = _cache[gameType];
    if (map == null || map.length < 8) return false;
    for (int lvl = 1; lvl <= 8; lvl++) {
      if (map[lvl]?.isCompleted != true) {
        return false;
      }
    }
    return true;
  }

  /// Returns date when all 8 levels were completed
  DateTime? getAllCompletedDate(GameType gameType) {
    if (_allCompletedDates.containsKey(gameType)) {
      return _allCompletedDates[gameType];
    }
    if (_box != null && _box!.isOpen) {
      final val = _box!.get('${gameType.name}_all_completed_date');
      if (val is String) {
        final parsed = DateTime.tryParse(val);
        if (parsed != null) {
          _allCompletedDates[gameType] = parsed;
          return parsed;
        }
      }
    }
    // Fallback: check completion date of Level 8 if all 8 are completed
    if (areAllLevelsCompleted(gameType)) {
      return _cache[gameType]?[8]?.completedAt;
    }
    return null;
  }

  /// Checks if all 8 levels were completed on a prior day and resets them if a new day has arrived.
  /// Allows the dementia patient to experience all 8 levels again afresh each day.
  bool checkAndPerformDailyReset(GameType gameType, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    if (!areAllLevelsCompleted(gameType)) return false;

    final completedDate = getAllCompletedDate(gameType);
    if (completedDate == null) return false;

    // Check if currentDate is a subsequent calendar day
    final isNewDay = (currentTime.year > completedDate.year) ||
        (currentTime.year == completedDate.year && currentTime.month > completedDate.month) ||
        (currentTime.year == completedDate.year &&
            currentTime.month == completedDate.month &&
            currentTime.day > completedDate.day);

    if (isNewDay) {
      resetGameProgress(gameType);
      debugPrint('🌅 Daily Reset: Reset 8 levels for $gameType for the new day.');
      return true;
    }
    return false;
  }

  /// Resets a game type back to Level 1 unlocked and 0 completed levels
  Future<void> resetGameProgress(GameType gameType) async {
    final initialMap = <int, GameLevelProgress>{};
    for (int lvl = 1; lvl <= 8; lvl++) {
      initialMap[lvl] = GameLevelProgress.initial(lvl);
      final key = '${gameType.name}_level_$lvl';
      if (_box != null && _box!.isOpen) {
        try {
          await _box!.delete(key);
        } catch (_) {}
      }
    }
    final compKey = '${gameType.name}_all_completed_date';
    if (_box != null && _box!.isOpen) {
      try {
        await _box!.delete(compKey);
      } catch (_) {}
    }
    _allCompletedDates.remove(gameType);
    _cache[gameType] = initialMap;
    notifyListeners();
  }

  /// Ensures cache is populated for game type
  Map<int, GameLevelProgress> getLevelProgressMap(GameType gameType) {
    if (!_cache.containsKey(gameType)) {
      final initialMap = <int, GameLevelProgress>{};
      for (int lvl = 1; lvl <= 8; lvl++) {
        initialMap[lvl] = GameLevelProgress.initial(lvl);
      }
      _cache[gameType] = initialMap;
    }

    // Auto-check for daily reset when accessing progress map
    checkAndPerformDailyReset(gameType);

    return Map.unmodifiable(_cache[gameType]!);
  }

  /// Alias for getLevelProgressMap
  Map<int, GameLevelProgress> getProgressForGame(GameType gameType) =>
      getLevelProgressMap(gameType);

  /// Returns individual level progress
  GameLevelProgress getProgress(GameType gameType, int levelNumber) {
    final map = getLevelProgressMap(gameType);
    return map[levelNumber] ?? GameLevelProgress.initial(levelNumber);
  }

  /// Alias for getProgress
  GameLevelProgress? getLevelProgress(GameType gameType, int levelNumber) =>
      getProgress(gameType, levelNumber);

  /// Returns the highest level unlocked for this game (1 to 8)
  int getHighestUnlockedLevel(GameType gameType) {
    final map = getLevelProgressMap(gameType);
    int highest = 1;
    for (int lvl = 1; lvl <= 8; lvl++) {
      if (map[lvl]?.isCompleted == true) {
        if (lvl + 1 <= 8 && lvl + 1 > highest) {
          highest = lvl + 1;
        }
      }
    }
    return highest;
  }

  /// Checks if a specific level is unlocked
  bool isLevelUnlocked(GameType gameType, int levelNumber) {
    if (levelNumber <= 1) return true; // Level 1 is always unlocked
    final highest = getHighestUnlockedLevel(gameType);
    return levelNumber <= highest;
  }

  /// Total stars earned across this game type (out of 24)
  int getTotalStarsEarned(GameType gameType) {
    final map = getLevelProgressMap(gameType);
    int total = 0;
    for (final p in map.values) {
      total += p.starsEarned;
    }
    return total;
  }

  /// Records completion of a level with earned stars and score
  Future<void> completeLevel({
    required GameType gameType,
    required int levelNumber,
    required int stars, // 1 to 3
    int score = 100,
    int timeSeconds = 0,
  }) async {
    final current = getProgress(gameType, levelNumber);
    final updatedStars = stars > current.starsEarned ? stars : current.starsEarned;
    final updatedScore = score > current.bestScore ? score : current.bestScore;

    final updated = GameLevelProgress(
      levelNumber: levelNumber,
      isCompleted: true,
      starsEarned: updatedStars,
      bestScore: updatedScore,
      timesPlayed: current.timesPlayed + 1,
      completedAt: DateTime.now(),
    );

    _cache[gameType] ??= {};
    _cache[gameType]![levelNumber] = updated;

    // Persist to Hive if available
    try {
      if (_box != null && _box!.isOpen) {
        final key = '${gameType.name}_level_$levelNumber';
        await _box!.put(key, updated.toMap());
      }
    } catch (e) {
      debugPrint('⚠️ Error persisting level progress: $e');
    }

    // If all 8 levels are now completed, record completion date for daily reset
    if (areAllLevelsCompleted(gameType)) {
      final now = DateTime.now();
      _allCompletedDates[gameType] = now;
      try {
        if (_box != null && _box!.isOpen) {
          await _box!.put(
            '${gameType.name}_all_completed_date',
            now.toIso8601String(),
          );
        }
      } catch (_) {}
    }

    notifyListeners();
  }

  /// Resets progress for testing
  @visibleForTesting
  void resetForTesting() {
    _cache.clear();
    _allCompletedDates.clear();
    _box?.clear();
    notifyListeners();
  }
}
