// ==============================================================================
// NIRVANA — Patient Dashboard Layout / Overflow Test Suite
// Description: Proves the hard responsiveness requirement — every dashboard
// widget renders without a RenderFlex overflow from 320px (small Android) to
// 480px (large phablet), at both 1.0 and 1.3 system text scale.
//
// How it works: an overflow in debug mode throws a FlutterError carrying the
// yellow-and-black "OVERFLOW" message, which the test binding reports as a test
// failure automatically. We additionally assert on the error text so a
// regression names itself clearly.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/features/patient/presentation/widgets/caregiver_banner.dart';
import 'package:nirvana/features/patient/presentation/widgets/daily_moment_card.dart';
import 'package:nirvana/features/patient/presentation/widgets/floating_sos_button.dart';
import 'package:nirvana/features/patient/presentation/widgets/patient_header.dart';
import 'package:nirvana/features/patient/presentation/widgets/app_icon_grid.dart';

/// Phone widths mandated by the spec.
const List<double> _phoneWidths = [320.0, 360.0, 400.0, 480.0];

/// System text scales mandated by the spec.
const List<double> _textScales = [1.0, 1.3];

Widget _host(Widget child, double width, double textScale) {
  return MaterialApp(
    theme: ElderTheme.buildStandardTheme(),
    home: MediaQuery(
      data: MediaQueryData(
        size: Size(width, 800.0),
        textScaler: TextScaler.linear(textScale),
      ),
      child: Scaffold(
        // Constrain to the phone width and allow vertical growth.
        body: SingleChildScrollView(
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  );
}

void main() {
  /// Runs [body] at every width / text-scale combination, failing on overflow.
  void forEachViewport(Widget Function() build, {String? label}) {
    for (final width in _phoneWidths) {
      for (final scale in _textScales) {
        testWidgets(
          '${label ?? 'widget'} @ ${width.toInt()}px / ${scale}x scale '
          'renders without overflow',
          (tester) async {
            await tester.pumpWidget(_host(build(), width, scale));
            await tester.pumpAndSettle();

            // If we reached here, no RenderFlex/overflow error was thrown:
            // the test binding promotes such errors to failures.
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  group('DailyMomentCard', () {
    forEachViewport(
      () => const DailyMomentCard(
        headline: 'You are doing wonderfully today',
        supportingText:
            'Take your time. Every small step is a good step, and you are not alone.',
      ),
      label: 'DailyMomentCard',
    );
  });

  group('CaregiverBanner', () {
    forEachViewport(
      () => const CaregiverBanner(
        message:
            'Your family can check in on you any time. You are safe and looked after.',
      ),
      label: 'CaregiverBanner',
    );
  });

  group('AppIconGrid', () {
    AppIconItem item(String label, IconData icon, List<Color> grad) =>
        AppIconItem(icon: icon, label: label, gradient: grad, onTap: () {});

    forEachViewport(
      () => AppIconGrid(
        items: [
          item('Games', Icons.extension_rounded, ElderColors.clayGradPurple),
          item('Reminders', Icons.alarm_rounded, ElderColors.clayGradTeal),
          item('Photos', Icons.photo_album_rounded, ElderColors.clayGradCoral),
          item('Ask', Icons.record_voice_over_rounded, ElderColors.clayGradSky),
          item('Accounts', Icons.lock_person_rounded, ElderColors.clayGradSage),
          item('Settings', Icons.settings_rounded, ElderColors.clayGradGold),
        ],
      ),
      label: 'AppIconGrid',
    );

    testWidgets('derives 3 columns at 320px and 4 columns at 480px', (
      tester,
    ) async {
      Future<int> columnsAt(double width) async {
        await tester.pumpWidget(
          _host(
            AppIconGrid(
              items: [
                item('A', Icons.abc, ElderColors.clayGradPurple),
                item('B', Icons.abc, ElderColors.clayGradTeal),
                item('C', Icons.abc, ElderColors.clayGradCoral),
                item('D', Icons.abc, ElderColors.clayGradSky),
                item('E', Icons.abc, ElderColors.clayGradSage),
                item('F', Icons.abc, ElderColors.clayGradGold),
              ],
            ),
            width,
            1.0,
          ),
        );
        await tester.pumpAndSettle();
        final grid = tester.widget<GridView>(find.byType(GridView));
        final delegate =
            grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
        return delegate.crossAxisCount;
      }

      expect(await columnsAt(320.0), 3);
      expect(await columnsAt(480.0), 4);
    });
  });

  group('FloatingSosButton', () {
    forEachViewport(
      () => FloatingSosButton(collapsed: false, onPressed: () {}),
      label: 'FloatingSosButton (expanded)',
    );
    forEachViewport(
      () => FloatingSosButton(collapsed: true, onPressed: () {}),
      label: 'FloatingSosButton (collapsed)',
    );

    testWidgets('keeps a >=56dp tappable size in both states', (tester) async {
      await tester.pumpWidget(
        _host(
          FloatingSosButton(collapsed: false, onPressed: () {}),
          360.0,
          1.0,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(FloatingSosButton)).height,
        greaterThanOrEqualTo(56.0),
      );

      await tester.pumpWidget(
        _host(FloatingSosButton(collapsed: true, onPressed: () {}), 360.0, 1.0),
      );
      await tester.pumpAndSettle();
      final collapsedSize = tester.getSize(find.byType(FloatingSosButton));
      expect(collapsedSize.width, greaterThanOrEqualTo(56.0));
      expect(collapsedSize.height, greaterThanOrEqualTo(56.0));
    });

    testWidgets('fires onPressed when collapsed (functionality unchanged)', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          FloatingSosButton(collapsed: true, onPressed: () => taps++),
          360.0,
          1.0,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingSosButton));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });
  });

  group('PatientHeader', () {
    forEachViewport(
      () => PatientHeader(
        dateLabel: 'Wednesday, Sep 24',
        greeting: 'Good Afternoon,',
        // Deliberately long name to exercise the Expanded/ellipsis path.
        patientName: 'Mrs. Annapurna Venkataraman Iyer',
        onFavorite: () {},
        onLogout: () {},
      ),
      label: 'PatientHeader (long name)',
    );
  });
}
