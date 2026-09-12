// ==============================================================================
// NIRVANA — Caregiver Activity Summary Cards layout test
// Description: Guards the fix for the three stat cards stacking into a tall
// column on normal phones. Asserts the cards sit in a single Row at typical
// content widths and never overflow.
//
// The widget receives CONTENT width (screen width minus the dashboard's 20px
// page padding each side), so we pass content widths directly.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/features/caregiver/presentation/widgets/activity_summary_cards.dart';

Widget _host(Widget child, double contentWidth, double textScale) {
  return ProviderScope(
    child: MaterialApp(
      theme: ElderTheme.buildStandardTheme(),
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(contentWidth, 800),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            // Reproduce the dashboard's 20px page padding so the widget sees
            // the same content width it does in the real screen.
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(width: contentWidth, child: child),
          ),
        ),
      ),
    ),
  );
}

void main() {
  // Content widths for 360 / 400 / 480 dp screens minus 40px page padding.
  const contentWidths = [320.0, 360.0, 400.0, 440.0];
  const textScales = [1.0, 1.3];

  for (final width in contentWidths) {
    for (final scale in textScales) {
      testWidgets(
        'lays out in a Row without overflow @ ${width.toInt()}px / ${scale}x',
        (tester) async {
          await tester.pumpWidget(
            _host(const ActivitySummaryCards(), width, scale),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);

          // The three cards must share a single Row, not stack in a Column.
          final rows = find.descendant(
            of: find.byType(ActivitySummaryCards),
            matching: find.byType(Row),
          );
          expect(rows, findsWidgets);

          final row = tester.widget<Row>(rows.first);
          expect(row.children.length, greaterThanOrEqualTo(3));
        },
      );
    }
  }
}
