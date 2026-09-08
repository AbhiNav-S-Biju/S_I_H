// ==============================================================================
// NIRVANA - SettingsScreen Test Suite
// Description: Component tests for accessibility toggles (reduced motion,
// high contrast, text scale) and language navigation.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirvana/app/providers/accessibility_providers.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/features/settings/presentation/settings_screen.dart';
import 'package:nirvana/l10n/app_localizations.dart';

void main() {
  testWidgets('SettingsScreen toggles Reduced Motion and High Contrast', (
    WidgetTester tester,
  ) async {
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
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Reduced Motion'), findsOneWidget);
    expect(find.text('High Contrast Mode'), findsOneWidget);

    // Verify initial values
    expect(container.read(reducedMotionProvider), isFalse);
    expect(container.read(highContrastProvider), isFalse);
    expect(container.read(voiceEnabledProvider), isTrue);

    // Toggle Reduced Motion switch
    final switches = find.byType(Switch);
    expect(switches, findsNWidgets(3));

    await tester.tap(switches.at(0));
    await tester.pumpAndSettle();
    expect(container.read(reducedMotionProvider), isTrue);

    // Toggle High Contrast switch
    await tester.tap(switches.at(1));
    await tester.pumpAndSettle();
    expect(container.read(highContrastProvider), isTrue);

    // Toggle Voice Assistance switch
    await tester.tap(switches.at(2));
    await tester.pumpAndSettle();
    expect(container.read(voiceEnabledProvider), isFalse);

    // Tap Extra Large text size
    final extraLargeFinder = find.text('Extra Large');
    await tester.ensureVisible(extraLargeFinder);
    await tester.tap(extraLargeFinder);
    await tester.pumpAndSettle();
    expect(container.read(textScaleProvider), TextScaleOption.extraLarge);
  });
}
