// ==============================================================================
// NIRVANA - Games Widget & Interaction Tests
// Tests: Widget rendering, touch target sizes, phase progression, completion dialog
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirvana/features/games/games.dart';

void main() {
  group('Games Widget Smoke & UI Tests', () {
    testWidgets('GamesHubScreen renders all 3 cognitive engagement games', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: GamesHubScreen()),
        ),
      );

      expect(find.text('Daily Activities'), findsOneWidget);
      expect(find.text('Remember Objects'), findsOneWidget);
      expect(find.text('Who Is This?'), findsOneWidget);
      expect(find.text('Grocery Memory'), findsOneWidget);
      expect(find.text('Activity Pace:'), findsOneWidget);
    });

    testWidgets(
      'RememberObjectsScreen progresses through memorization to recall',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        GameSession? completedSession;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: RememberObjectsScreen(
                difficulty: GameDifficulty.easy,
                onGameCompleted: (session) {
                  completedSession = session;
                },
              ),
            ),
          ),
        );

        // Verify Memorization View is active
        expect(find.text('I am Ready ➔'), findsOneWidget);
        expect(find.byType(ElderGameCard), findsNWidgets(3));

        // Tap "I am Ready ➔"
        await tester.tap(find.text('I am Ready ➔'));
        await tester.pumpAndSettle();

        // Verify Recall View is active with selection options
        expect(find.byType(ElderGameCard), findsNWidgets(6));
        expect(find.text('Complete Activity ➔'), findsOneWidget);

        // Tap the first card to select it
        await tester.ensureVisible(find.byType(ElderGameCard).first);
        await tester.tap(find.byType(ElderGameCard).first);
        await tester.pumpAndSettle();

        // Tap "Complete Activity ➔" button
        await tester.ensureVisible(find.text('Complete Activity ➔'));
        await tester.tap(find.text('Complete Activity ➔'));
        await tester.pumpAndSettle();

        // Verify GameCompletionDialog appears
        expect(find.text('Activity Completed!'), findsOneWidget);
        expect(find.text('All Done'), findsOneWidget);

        // Tap "All Done"
        await tester.tap(find.text('All Done'));
        await tester.pumpAndSettle();

        expect(completedSession, isNotNull);
        expect(completedSession!.gameType, equals(GameType.rememberObjects));
      },
    );

    testWidgets(
      'WhoIsThisScreen renders family card and relationship choices',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        GameSession? completedSession;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: WhoIsThisScreen(
                difficulty: GameDifficulty.easy,
                onGameCompleted: (session) {
                  completedSession = session;
                },
              ),
            ),
          ),
        );

        expect(find.text('Who Is This?'), findsOneWidget);
        expect(find.text('Family & Friends'), findsOneWidget);
        expect(find.text('Hint'), findsOneWidget);

        // Tap Hint button
        await tester.tap(find.text('Hint'));
        await tester.pumpAndSettle();

        // Select an option using Semantics label or option text
        // Options are displayed on screen
        final optionTexts = [
          'Granddaughter',
          'Daughter',
          'Son',
          'Family Pet',
          'Doctor',
          'Neighbor',
          'Teacher',
          'Sister',
          'Cousin',
          'Nurse',
        ];
        for (final opt in optionTexts) {
          final finder = find.widgetWithText(Semantics, opt);
          if (finder.evaluate().isNotEmpty) {
            await tester.ensureVisible(finder.first);
            await tester.tap(finder.first);
            await tester.pumpAndSettle();
            break;
          }
        }

        // Tap next person button
        await tester.ensureVisible(find.text('Next Person ➔'));
        await tester.tap(find.text('Next Person ➔'));
        await tester.pumpAndSettle();

        // Second question: select an available option
        for (final opt in optionTexts) {
          final finder = find.widgetWithText(Semantics, opt);
          if (finder.evaluate().isNotEmpty) {
            await tester.ensureVisible(finder.first);
            await tester.tap(finder.first);
            await tester.pumpAndSettle();
            break;
          }
        }

        // Tap complete activity button
        await tester.ensureVisible(find.text('Complete Activity ➔'));
        await tester.tap(find.text('Complete Activity ➔'));
        await tester.pumpAndSettle();

        expect(find.text('Activity Completed!'), findsOneWidget);
        await tester.tap(find.text('All Done'));
        await tester.pumpAndSettle();

        expect(completedSession, isNotNull);
        expect(completedSession!.gameType, equals(GameType.whoIsThis));
      },
    );

    testWidgets(
      'GroceryMemoryScreen progresses from list to supermarket shelf',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        GameSession? completedSession;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: GroceryMemoryScreen(
                difficulty: GameDifficulty.easy,
                onGameCompleted: (session) {
                  completedSession = session;
                },
              ),
            ),
          ),
        );

        expect(find.text('Grocery Memory'), findsOneWidget);
        expect(find.text('Go to Market ➔'), findsOneWidget);

        // Tap "Go to Market ➔"
        await tester.ensureVisible(find.text('Go to Market ➔'));
        await tester.tap(find.text('Go to Market ➔'));
        await tester.pumpAndSettle();

        // Shelf items rendered
        expect(find.byType(ElderGameCard), findsNWidgets(6));
        expect(find.text('Complete Shopping ➔'), findsOneWidget);

        // Pick an item
        await tester.ensureVisible(find.byType(ElderGameCard).first);
        await tester.tap(find.byType(ElderGameCard).first);
        await tester.pumpAndSettle();

        // Tap Complete Shopping
        await tester.ensureVisible(find.text('Complete Shopping ➔'));
        await tester.tap(find.text('Complete Shopping ➔'));
        await tester.pumpAndSettle();

        expect(find.text('Activity Completed!'), findsOneWidget);
        await tester.tap(find.text('All Done'));
        await tester.pumpAndSettle();

        expect(completedSession, isNotNull);
        expect(completedSession!.gameType, equals(GameType.groceryMemory));
      },
    );
  });
}
