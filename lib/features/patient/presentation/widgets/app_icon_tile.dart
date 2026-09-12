// ==============================================================================
// NIRVANA — AppIconTile
// Description: A home-screen-style launcher tile: a gradient icon badge with a
// short 1–2 word label underneath, both centred.
//
// Accessibility / overflow decisions (spec §3 & §5):
//   * Fixed size is applied ONLY to the badge ([AspectRatio] + [SizedBox]);
//     the tile's parent cell sizes to content. The label may wrap to two lines
//     and the tile grows taller rather than clipping.
//   * Colour is never the only signal — the icon is always accompanied by a
//     text label, which is also exposed as the semantics label.
//   * Minimum tap target is 48x48dp: the badge alone is >=56px, so the whole
//     tile comfortably clears the requirement even on small phones.
//   * The badge holds a single-colour line icon so contrast stays high against
//     the gradient fill.
// ==============================================================================

import 'package:flutter/material.dart';

import '../../../../app/theme/elder_theme.dart';

class AppIconTile extends StatelessWidget {
  /// Line icon centred in the badge.
  final IconData icon;

  /// Short 1–2 word label shown beneath the badge.
  final String label;

  /// Two-stop accent gradient for the badge (see [ElderColors.clayGrad*]).
  final List<Color> gradient;

  /// Tap handler — navigates to the corresponding patient route.
  final VoidCallback onTap;

  /// Badge diameter derived from the grid (clamped by the grid, defaulted here).
  final double badgeSize;

  const AppIconTile({
    super.key,
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
    this.badgeSize = 64.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(NirvanaRadii.icon),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(NirvanaRadii.icon),
          splashColor: gradient.last.withValues(alpha: 0.10),
          highlightColor: Colors.transparent,
          // Vertical layout, content-sized: nothing here forces a tile height.
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 2.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // -----------------------------------------------------------
                // FIXED-SIZE BADGE — the only fixed dimension in the tile.
                // Wrapped in a Center so it stays optically centred if the
                // label wraps to two lines and widens the column.
                // -----------------------------------------------------------
                Center(
                  child: Container(
                    width: badgeSize,
                    height: badgeSize,
                    decoration: BoxDecoration(
                      gradient: ElderColors.clayGradient(gradient),
                      // Rounded-square, 18px radius — the "puffy clay" look,
                      // not a flat Material circle.
                      borderRadius: BorderRadius.circular(NirvanaRadii.button),
                      boxShadow: [
                        // Compact dual shadow: ambient bottom-right...
                        BoxShadow(
                          color: gradient.last.withValues(alpha: 0.34),
                          offset: const Offset(0, 5),
                          blurRadius: 12,
                        ),
                        // ...and a warm-white top-left highlight.
                        BoxShadow(
                          color: ElderColors.clayBackgroundHighlight.withValues(
                            alpha: 0.70,
                          ),
                          offset: const Offset(-3, -3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      size: badgeSize * 0.46,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10.0),

                // -----------------------------------------------------------
                // WRAPPING LABEL — allowed two lines, centred. 14sp meets the
                // "generous type" floor; we never shrink it to force one line.
                // -----------------------------------------------------------
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: ElderColors.clayInk,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
