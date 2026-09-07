import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirvana/features/games/games.dart';

void main() {
  testWidgets('App smoke test launches GamesHubScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GamesHubScreen(),
      ),
    );

    expect(find.text('Daily Activities'), findsOneWidget);
  });
}
