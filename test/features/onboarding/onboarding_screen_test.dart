// ==============================================================================
// NIRVANA - OnboardingScreen Test Suite
// Description: Component tests verifying the multi-step onboarding flow.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/features/onboarding/presentation/onboarding_screen.dart';
import 'package:nirvana/l10n/app_localizations.dart';

void main() {
  testWidgets('OnboardingScreen navigates across steps', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ElderTheme.buildStandardTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const OnboardingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Step 1 check
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('A Gentle Companion'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    // Tap Continue -> Step 2
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text('Designed for Easy Reading'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);

    // Tap Continue -> Step 3
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('3 / 3'), findsOneWidget);
    expect(find.text('Ready Whenever You Are'), findsOneWidget);
    expect(find.text('Enter Nirvana'), findsOneWidget);
  });
}
