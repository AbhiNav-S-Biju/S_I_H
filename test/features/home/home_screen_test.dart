// ==============================================================================
// NIRVANA - HomeScreen Test Suite
// Description: Component tests for HomeScreen greeting, primary action cards,
// and accessible touch targets.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/features/home/presentation/home_screen.dart';
import 'package:nirvana/l10n/app_localizations.dart';

void main() {
  Widget createHomeScreen() {
    return ProviderScope(
      child: MaterialApp(
        theme: ElderTheme.buildStandardTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HomeScreen(),
      ),
    );
  }

  testWidgets(
    'HomeScreen renders greeting, activities card, and settings card',
    (WidgetTester tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Check App bar title
      expect(find.text('NIRVANA'), findsOneWidget);

      // Check Start Activities action button exists
      expect(find.text("Today's Activities"), findsOneWidget);
      expect(find.text('Start Activities'), findsOneWidget);

      // Check Settings action card exists
      expect(find.text('App Settings & Comfort'), findsOneWidget);
      expect(find.text('Settings'), findsWidgets);

      // Check supportive message exists
      expect(find.byIcon(Icons.spa_rounded), findsWidgets);

      // Check Caregiver Portal secondary button exists
      expect(find.text('Caregiver Portal'), findsOneWidget);
    },
  );
}
