import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirvana/features/games/games.dart';
import 'package:nirvana/main.dart';

import 'package:nirvana/l10n/app_localizations.dart';

void main() {
  testWidgets('App smoke test launches GamesHubScreen directly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GamesHubScreen(),
        ),
      ),
    );

    expect(find.text('Daily Activities'), findsOneWidget);
  });

  testWidgets('NirvanaApp smoke test launches with ProviderScope and router', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: NirvanaApp()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to NIRVANA'), findsOneWidget);
    expect(find.text('Patient Portal'), findsOneWidget);
    expect(find.text('Caregiver Portal'), findsOneWidget);
  });
}
