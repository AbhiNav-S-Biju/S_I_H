import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirvana/features/games/games.dart';
import 'package:nirvana/main.dart';

void main() {
  testWidgets('App smoke test launches GamesHubScreen directly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GamesHubScreen(),
      ),
    );

    expect(find.text('Daily Activities'), findsOneWidget);
  });

  testWidgets('NirvanaApp smoke test launches with ProviderScope and router', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: NirvanaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NIRVANA'), findsOneWidget);
    expect(find.text('A Gentle Companion'), findsOneWidget);
  });
}
