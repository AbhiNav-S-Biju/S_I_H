// ==============================================================================
// NIRVANA - Game Level & Journey Progression Tests
// Tests: 8-level journeys for 4 activities, sequential unlock, star accumulation,
// and Dementia-Friendly level map widget rendering.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirvana/features/games/games.dart';

void main() {
  setUp(() {
    // Reset service state before each test
    GameProgressService.instance.resetForTesting();
  });

  group('GameLevel Domain Model Tests', () {
    test('All 4 activities have exactly 8 curated levels', () {
      for (final type in GameType.values) {
        final levels = GameLevel.getLevelsForGame(type);
        expect(levels.length, 8, reason: 'Game $type must have 8 levels');

        // Check sequential numbering
        for (int i = 0; i < 8; i++) {
          expect(levels[i].levelNumber, i + 1);
        }

        // Verify progressive difficulty
        expect(levels[0].difficulty, GameDifficulty.easy);
        expect(levels[1].difficulty, GameDifficulty.easy);
        expect(levels[2].difficulty, GameDifficulty.easy);
        expect(levels[3].difficulty, GameDifficulty.medium);
        expect(levels[4].difficulty, GameDifficulty.medium);
        expect(levels[5].difficulty, GameDifficulty.medium);
        expect(levels[6].difficulty, GameDifficulty.hard);
        expect(levels[7].difficulty, GameDifficulty.hard);
      }
    });

    test('Journey titles and subtitles localize properly across languages', () {
      for (final type in GameType.values) {
        for (final lang in ['en', 'as', 'hi', 'bn']) {
          final title = GameLevel.getJourneyTitle(type, lang);
          final subtitle = GameLevel.getJourneySubtitle(type, lang);
          expect(title.isNotEmpty, isTrue);
          expect(subtitle.isNotEmpty, isTrue);
        }
      }
    });

    test('Familiar Jigsaw levels specify valid puzzle images and grid dimensions', () {
      final jigsawLevels = GameLevel.getLevelsForGame(GameType.jigsawPuzzle);
      for (final level in jigsawLevels) {
        expect(level.config.containsKey('image'), isTrue);
        expect(level.config['image'], isA<PuzzleImage>());
        expect(level.config.containsKey('rows'), isTrue);
        expect(level.config.containsKey('cols'), isTrue);
      }
      // Level 1 should be 2 pieces (1x2)
      expect(jigsawLevels[0].config['rows'], 1);
      expect(jigsawLevels[0].config['cols'], 2);

      // Level 4 (Milestone) should be 4 pieces (2x2)
      expect(jigsawLevels[3].config['rows'], 2);
      expect(jigsawLevels[3].config['cols'], 2);

      // Level 8 (Summit) should be 6 pieces (2x3)
      expect(jigsawLevels[7].config['rows'], 2);
      expect(jigsawLevels[7].config['cols'], 3);
    });
  });

  group('GameProgressService Progression & Star Logic Tests', () {
    test('Level 1 is unlocked initially; other levels are locked', () {
      final service = GameProgressService.instance;
      expect(service.isLevelUnlocked(GameType.jigsawPuzzle, 1), isTrue);
      expect(service.isLevelUnlocked(GameType.jigsawPuzzle, 2), isFalse);
      expect(service.isLevelUnlocked(GameType.jigsawPuzzle, 8), isFalse);
      expect(service.getHighestUnlockedLevel(GameType.jigsawPuzzle), 1);
      expect(service.getTotalStarsEarned(GameType.jigsawPuzzle), 0);
    });

    test('Completing level unlocks the next level and accumulates stars', () {
      final service = GameProgressService.instance;

      // Complete Level 1 with 3 stars
      service.completeLevel(
        gameType: GameType.jigsawPuzzle,
        levelNumber: 1,
        stars: 3,
        timeSeconds: 45,
      );

      expect(service.isLevelUnlocked(GameType.jigsawPuzzle, 2), isTrue);
      expect(service.getHighestUnlockedLevel(GameType.jigsawPuzzle), 2);
      expect(service.getTotalStarsEarned(GameType.jigsawPuzzle), 3);

      final progress1 = service.getLevelProgress(GameType.jigsawPuzzle, 1);
      expect(progress1?.isCompleted, isTrue);
      expect(progress1?.starsEarned, 3);
      expect(progress1?.timesPlayed, 1);

      // Complete Level 2 with 2 stars
      service.completeLevel(
        gameType: GameType.jigsawPuzzle,
        levelNumber: 2,
        stars: 2,
        timeSeconds: 60,
      );

      expect(service.isLevelUnlocked(GameType.jigsawPuzzle, 3), isTrue);
      expect(service.getHighestUnlockedLevel(GameType.jigsawPuzzle), 3);
      expect(service.getTotalStarsEarned(GameType.jigsawPuzzle), 5); // 3 + 2 = 5
    });

    test('Replaying a level with fewer stars does not degrade best score', () {
      final service = GameProgressService.instance;

      // First run: 3 stars
      service.completeLevel(
        gameType: GameType.rememberObjects,
        levelNumber: 1,
        stars: 3,
        timeSeconds: 30,
      );
      expect(service.getTotalStarsEarned(GameType.rememberObjects), 3);

      // Replay: 1 star
      service.completeLevel(
        gameType: GameType.rememberObjects,
        levelNumber: 1,
        stars: 1,
        timeSeconds: 50,
      );

      final p = service.getLevelProgress(GameType.rememberObjects, 1);
      expect(p?.starsEarned, 3, reason: 'High score of 3 stars must be preserved');
      expect(p?.timesPlayed, 2);
      expect(service.getTotalStarsEarned(GameType.rememberObjects), 3);
    });

    test('Completing Level 8 keeps highest unlocked at 8', () {
      final service = GameProgressService.instance;
      for (int i = 1; i <= 8; i++) {
        service.completeLevel(
          gameType: GameType.groceryMemory,
          levelNumber: i,
          stars: 3,
        );
      }
      expect(service.getHighestUnlockedLevel(GameType.groceryMemory), 8);
      expect(service.getTotalStarsEarned(GameType.groceryMemory), 24); // 8 * 3
      expect(service.areAllLevelsCompleted(GameType.groceryMemory), isTrue);
    });

    test('Daily Reset resets completed 8 levels on next calendar day', () {
      final service = GameProgressService.instance;
      final today = DateTime.now();

      // Complete all 8 levels today
      for (int i = 1; i <= 8; i++) {
        service.completeLevel(
          gameType: GameType.jigsawPuzzle,
          levelNumber: i,
          stars: 3,
        );
      }
      expect(service.areAllLevelsCompleted(GameType.jigsawPuzzle), isTrue);
      expect(service.getTotalStarsEarned(GameType.jigsawPuzzle), 24);

      // Checking on same day does NOT reset
      final resetSameDay = service.checkAndPerformDailyReset(
        GameType.jigsawPuzzle,
        now: today,
      );
      expect(resetSameDay, isFalse);
      expect(service.areAllLevelsCompleted(GameType.jigsawPuzzle), isTrue);

      // Checking on the NEXT day triggers daily reset for fresh journey
      final tomorrow = today.add(const Duration(days: 1));
      final resetNextDay = service.checkAndPerformDailyReset(
        GameType.jigsawPuzzle,
        now: tomorrow,
      );
      expect(resetNextDay, isTrue);

      // After reset: Level 1 is unlocked, Level 2 is locked, stars are 0
      expect(service.isLevelUnlocked(GameType.jigsawPuzzle, 1), isTrue);
      expect(service.isLevelUnlocked(GameType.jigsawPuzzle, 2), isFalse);
      expect(service.getHighestUnlockedLevel(GameType.jigsawPuzzle), 1);
      expect(service.getTotalStarsEarned(GameType.jigsawPuzzle), 0);
      expect(service.areAllLevelsCompleted(GameType.jigsawPuzzle), isFalse);
    });

    test('Manual resetGameProgress clears journey back to Level 1', () async {
      final service = GameProgressService.instance;
      service.completeLevel(
        gameType: GameType.whoIsThis,
        levelNumber: 1,
        stars: 3,
      );
      service.completeLevel(
        gameType: GameType.whoIsThis,
        levelNumber: 2,
        stars: 2,
      );
      expect(service.getHighestUnlockedLevel(GameType.whoIsThis), 3);

      await service.resetGameProgress(GameType.whoIsThis);

      expect(service.isLevelUnlocked(GameType.whoIsThis, 1), isTrue);
      expect(service.isLevelUnlocked(GameType.whoIsThis, 2), isFalse);
      expect(service.getTotalStarsEarned(GameType.whoIsThis), 0);
    });
  });

  group('Game Level UI & Map Widget Tests', () {
    testWidgets('GameLevelMapPath renders all 8 level nodes and milestone tags', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final levels = GameLevel.getLevelsForGame(GameType.jigsawPuzzle);
      GameLevel? tappedLevel;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GameLevelMapPath(
                levels: levels,
                progressMap: const {},
                highestUnlockedLevel: 8,
                langCode: 'en',
                onLevelTapped: (lvl) => tappedLevel = lvl,
              ),
            ),
          ),
        ),
      );

      // All 8 level numbers should be visible when unlocked
      for (int i = 1; i <= 8; i++) {
        expect(find.text('$i'), findsOneWidget);
      }

      // Tap level 1 node
      await tester.tap(find.text('1'));
      await tester.pump();
      expect(tappedLevel?.levelNumber, 1);
    });

    testWidgets('LevelPreviewSheet displays level title and triggers start', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final level = GameLevel.getLevelsForGame(GameType.jigsawPuzzle).first;
      bool started = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () {
                    LevelPreviewSheet.show(
                      ctx,
                      level: level,
                      progress: null,
                      langCode: 'en',
                      onStart: () => started = true,
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Kaziranga Gentle Start'), findsOneWidget);
      expect(find.text('LEVEL 1'), findsOneWidget);

      await tester.tap(find.text('Start Level ➔'));
      await tester.pumpAndSettle();

      expect(started, isTrue);
    });

    testWidgets('GameLevelMapScreen loads with header, stars counter, and map path', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GameLevelMapScreen(gameType: GameType.jigsawPuzzle),
          ),
        ),
      );

      expect(find.text('North East Expedition'), findsOneWidget);
      expect(find.text('0 / 24'), findsOneWidget);
      expect(find.text('Start Level 1 ➔'), findsOneWidget);
    });
  });
}
