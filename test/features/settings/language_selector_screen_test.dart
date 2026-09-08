// ==============================================================================
// NIRVANA - LanguageSelectorScreen Test Suite
// Description: Component tests for language selection across regional languages.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirvana/app/providers/accessibility_providers.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/features/settings/presentation/language_selector_screen.dart';
import 'package:nirvana/l10n/app_localizations.dart';

void main() {
  testWidgets('LanguageSelectorScreen renders all 8 Indian & regional languages',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final container = ProviderContainer();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ElderTheme.buildStandardTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LanguageSelectorScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify all 8 language options exist in the list
    expect(find.text('English'), findsWidgets);
    expect(find.text('हिन्दी'), findsOneWidget);
    expect(find.text('অসমীয়া'), findsOneWidget);
    expect(find.text('বাংলা'), findsOneWidget);
    expect(find.text('মৈতৈলোন্'), findsOneWidget);
    expect(find.text('Ka Ktien Khasi'), findsOneWidget);
    expect(find.text('Mizo ṭawng'), findsOneWidget);
    expect(find.text('नेपाली'), findsOneWidget);

    // Tap Assamese
    await tester.tap(find.text('অসমীয়া'));
    await tester.pumpAndSettle();
    expect(container.read(localeProvider).languageCode, equals('as'));

    // Tap Manipuri / Meitei
    await tester.tap(find.text('মৈতৈলোন্'));
    await tester.pumpAndSettle();
    expect(container.read(localeProvider).languageCode, equals('mni'));

    // Tap Khasi
    await tester.tap(find.text('Ka Ktien Khasi'));
    await tester.pumpAndSettle();
    expect(container.read(localeProvider).languageCode, equals('kha'));

    // Tap Mizo
    await tester.tap(find.text('Mizo ṭawng'));
    await tester.pumpAndSettle();
    expect(container.read(localeProvider).languageCode, equals('lus'));

    // Tap Nepali
    await tester.tap(find.text('नेपाली'));
    await tester.pumpAndSettle();
    expect(container.read(localeProvider).languageCode, equals('ne'));

    // Tap Bengali
    await tester.tap(find.text('বাংলা'));
    await tester.pumpAndSettle();
    expect(container.read(localeProvider).languageCode, equals('bn'));
  });
}
