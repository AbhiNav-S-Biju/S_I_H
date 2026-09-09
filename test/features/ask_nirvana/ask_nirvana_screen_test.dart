// ==============================================================================
// NIRVANA - Ask NIRVANA Screen Widget Test
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/features/ask_nirvana/ask_nirvana.dart';
import 'package:nirvana/l10n/app_localizations.dart';

void main() {
  testWidgets('Ask NIRVANA Screen renders core elder-facing UI components',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ElderTheme.buildStandardTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const AskNirvanaScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Large title
    expect(find.text('Ask NIRVANA'), findsOneWidget);

    // 2. Friendly assistant status area
    expect(find.text('NIRVANA Companion'), findsOneWidget);

    // 3. Conversation greeting
    expect(
      find.text(
        'Hello! I am NIRVANA, your companion. Tap the large microphone below to talk with me, or type your question.',
      ),
      findsOneWidget,
    );

    // 4. Primary microphone button with "Tap to speak"
    expect(find.text('Tap to speak'), findsOneWidget);
    expect(find.byIcon(Icons.mic_rounded), findsWidgets);

    // 5. Secondary text input and Send button
    expect(find.text('Or type here...'), findsOneWidget);
    expect(find.byIcon(Icons.send_rounded), findsOneWidget);

    // 6. Clear conversation option
    expect(find.text('Clear'), findsOneWidget);
  });

  testWidgets('Typing a question submits message and shows thinking/speaking state',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ElderTheme.buildStandardTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const AskNirvanaScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Enter typed question
    await tester.enterText(find.byType(TextField), 'How are you today?');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();

    // Verify user message appears
    expect(find.text('How are you today?'), findsOneWidget);

    // Verify thinking state label (appears in status pill and under mic)
    expect(find.text('Let me think...'), findsWidgets);

    // Wait for the simulated thinking delay (1200ms)
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump();

    // Verify read aloud button appears for assistant message
    expect(find.text('Read Aloud'), findsWidgets);
  });
}
