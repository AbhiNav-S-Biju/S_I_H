// ==============================================================================
// NIRVANA — AppIconGrid
// Description: Responsive home-screen-icon launcher grid for the patient
// dashboard ("What would you like to do?").
//
// Responsiveness (spec §3) — this is where the hard requirement lives:
//   * It is a [GridView.builder], never a ListView, so icons flow into columns.
//   * [crossAxisCount] is DERIVED from the measured width via [LayoutBuilder]
//     (`width ~/ targetCellWidth`, clamped 3–4), not hardcoded — this is what
//     prevents cramped icons on 320px and sparse icons on 480px.
//   * [childAspectRatio] is computed from a measured cell so the badge plus two
//     lines of 14sp label always fit; it is not a guessed constant.
//   * The grid scrolls as part of the parent SingleChildScrollView
//     (`shrinkWrap` + [NeverScrollableScrollPhysics]) so there is never a
//     nested-scroll conflict or an unbounded-height assertion.
// ==============================================================================

import 'package:flutter/material.dart';

import 'app_icon_tile.dart';

/// One launcher entry: icon + short label + accent gradient + tap target.
class AppIconItem {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;

  const AppIconItem({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });
}

class AppIconGrid extends StatelessWidget {
  final List<AppIconItem> items;

  /// Roughly how wide each launcher cell should be before a new column starts.
  /// Dividing the available width by this yields the column count.
  final double targetCellWidth;

  const AppIconGrid({
    super.key,
    required this.items,
    this.targetCellWidth = 110.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;

        // -------------------------------------------------------------------
        // DYNAMIC COLUMN COUNT — clamp between 3 and 4 as the spec requires.
        //
        //   width ~/ 110  →  320px ⇒ 2 (clamped up to 3)
        //                    360px ⇒ 3
        //                    480px ⇒ 4
        // This keeps icons a similar physical size on every phone.
        // -------------------------------------------------------------------
        final int rawColumns = (available / targetCellWidth).floor();
        final int columns = rawColumns.clamp(
          3,
          items.length < 3 ? items.length : 4,
        );

        // Badge shrinks a little on very narrow phones but never below 56px,
        // so tap targets stay comfortable even at 3 columns on a 320px screen.
        final double cellWidth = available / columns;
        final double badgeSize = (cellWidth * 0.58).clamp(56.0, 72.0);

        // -------------------------------------------------------------------
        // MEASURED CELL HEIGHT — rather than guessing `aspectRatio: 1.0`, we
        // measure the ACTUAL rendered height of two label lines with a
        // [TextPainter] against the resolved label style (which already
        // includes the system text scale), then add the fixed badge/gap/padding.
        // A small safety margin absorbs sub-pixel rounding so the cell can never
        // come out a pixel or two short on any device (the spec's build-blocking
        // overflow rule).
        // -------------------------------------------------------------------
        final labelStyle =
            (Theme.of(context).textTheme.bodyMedium ??
                    const TextStyle(fontSize: 14.0))
                .copyWith(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                );
        final textScaler = MediaQuery.textScalerOf(context);
        final labelPainter = TextPainter(
          text: TextSpan(text: 'Ag', style: labelStyle),
          textDirection: TextDirection.ltr,
          textScaler: textScaler,
          maxLines: 1,
        )..layout();
        // Two label lines + a small margin for ascenders/descenders.
        final double labelBlock =
            (labelPainter.height.ceilToDouble() + 2.0) * 2;

        // Exact cell height in logical pixels. Using [mainAxisExtent] instead of
        // an aspect ratio means the cell is this tall to the pixel — no width→
        // height rounding that could shave off the last row of glyphs.
        final double cellHeight =
            6.0 + // tile top padding
            badgeSize +
            10.0 + // gap between badge and label
            labelBlock +
            8.0; // tile bottom padding + safety margin

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12.0,
            mainAxisSpacing: 16.0,
            // Explicit, content-measured cell height — the grid no longer
            // infers height from width, so nothing is clipped at any width or
            // text scale.
            mainAxisExtent: cellHeight,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return AppIconTile(
              icon: item.icon,
              label: item.label,
              gradient: item.gradient,
              onTap: item.onTap,
              badgeSize: badgeSize,
            );
          },
        );
      },
    );
  }
}
