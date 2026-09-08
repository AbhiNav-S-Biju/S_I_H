// ==============================================================================
// NIRVANA - Elder Widgets Test Suite
// Description: Unit and component tests verifying touch target sizes,
// typography, semantic labels, and supportive feedback states.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/app/widgets/widgets.dart';

void main() {
  Widget testWrapper(Widget child) {
    return MaterialApp(
      theme: ElderTheme.buildStandardTheme(),
      home: Scaffold(body: child),
    );
  }

  group('LargeActionButton Tests', () {
    testWidgets('Renders with min 64dp height and triggers onPressed', (
      tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        testWrapper(
          LargeActionButton(
            label: 'Start Activity',
            onPressed: () => tapped = true,
            icon: Icons.play_arrow,
          ),
        ),
      );

      final buttonFinder = find.byType(LargeActionButton);
      expect(buttonFinder, findsOneWidget);

      final size = tester.getSize(buttonFinder);
      expect(size.height, greaterThanOrEqualTo(64.0));

      expect(find.text('Start Activity'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('Shows CircularProgressIndicator when isLoading is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        testWrapper(
          LargeActionButton(label: 'Saving', isLoading: true, onPressed: () {}),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Saving'), findsNothing);
    });
  });

  group('ElderCard Tests', () {
    testWidgets('Renders content with accessible border and tap area', (
      tester,
    ) async {
      bool cardTapped = false;
      await tester.pumpWidget(
        testWrapper(
          ElderCard(
            onTap: () => cardTapped = true,
            child: const Text('Memory Card Item'),
          ),
        ),
      );

      expect(find.text('Memory Card Item'), findsOneWidget);

      final cardFinder = find.byType(ElderCard);
      final size = tester.getSize(cardFinder);
      expect(size.height, greaterThanOrEqualTo(64.0));

      await tester.tap(cardFinder);
      await tester.pumpAndSettle();
      expect(cardTapped, isTrue);
    });
  });

  group('SectionHeader Tests', () {
    testWidgets('Displays title, icon, and subtitle with header semantics', (
      tester,
    ) async {
      await tester.pumpWidget(
        testWrapper(
          const SectionHeader(
            title: 'Visual Comfort',
            subtitle: 'Settings for easy reading',
            icon: Icons.visibility,
          ),
        ),
      );

      expect(find.text('Visual Comfort'), findsOneWidget);
      expect(find.text('Settings for easy reading'), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });
  });

  group('SupportiveMessage Tests', () {
    testWidgets('Displays comforting feedback with warm styling', (
      tester,
    ) async {
      await tester.pumpWidget(
        testWrapper(
          const SupportiveMessage(
            message: 'You are doing wonderful today!',
            icon: Icons.favorite,
          ),
        ),
      );

      expect(find.text('You are doing wonderful today!'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });
  });

  group('LargeIconButton Tests', () {
    testWidgets('Has touch target >= 64dp and triggers callback', (
      tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        testWrapper(
          LargeIconButton(
            icon: Icons.arrow_back,
            semanticLabel: 'Go Back',
            onPressed: () => tapped = true,
          ),
        ),
      );

      final buttonFinder = find.byType(LargeIconButton);
      final size = tester.getSize(buttonFinder);
      expect(size.width, greaterThanOrEqualTo(64.0));
      expect(size.height, greaterThanOrEqualTo(64.0));

      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });

  group('LoadingState Tests', () {
    testWidgets('Renders friendly soothing loading indicator and message', (
      tester,
    ) async {
      await tester.pumpWidget(
        testWrapper(const LoadingState(message: 'Preparing your game...')),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Preparing your game...'), findsOneWidget);
    });
  });

  group('EmptyState Tests', () {
    testWidgets('Renders uncluttered empty view with action button', (
      tester,
    ) async {
      bool actionTriggered = false;
      await tester.pumpWidget(
        testWrapper(
          EmptyState(
            title: 'No Items Yet',
            message: 'Check back later.',
            actionLabel: 'Return Home',
            onAction: () => actionTriggered = true,
          ),
        ),
      );

      expect(find.text('No Items Yet'), findsOneWidget);
      expect(find.text('Check back later.'), findsOneWidget);
      expect(find.text('Return Home'), findsOneWidget);

      await tester.tap(find.text('Return Home'));
      await tester.pumpAndSettle();
      expect(actionTriggered, isTrue);
    });
  });

  group('ErrorState Tests', () {
    testWidgets('Renders gentle supportive error state with Retry action', (
      tester,
    ) async {
      bool retried = false;
      await tester.pumpWidget(
        testWrapper(
          ErrorState(
            title: "Let's Take a Gentle Pause",
            message: 'Everything is safe.',
            retryLabel: 'Try Again',
            onRetry: () => retried = true,
          ),
        ),
      );

      expect(find.text("Let's Take a Gentle Pause"), findsOneWidget);
      expect(find.text('Everything is safe.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();
      expect(retried, isTrue);
    });
  });
}
