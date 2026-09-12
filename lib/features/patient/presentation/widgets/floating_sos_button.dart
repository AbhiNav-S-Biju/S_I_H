// ==============================================================================
// NIRVANA — FloatingSosButton
// Description: Safety-critical "Need help" control anchored to the bottom-right
// of the viewport (via Stack + Positioned in the home screen), sitting ABOVE
// the scrollable content rather than inside it.
//
// Behaviour (spec §4):
//   * Rest state: a coral pill — icon + "Need help" label, >=56px tall. It is
//     never shrunk below accessible touch-target size, even at rest.
//   * Collapsed state: when the patient scrolls past a ~40px threshold the pill
//     animates down to a circle containing only the icon (AnimatedContainer,
//     ~350ms, Curves.easeInOut). It is NEVER hidden or jumped instantly — it
//     must remain visible and tappable at all times.
//   * Tapping it — collapsed or expanded — fires the SAME help action. The
//     animation only changes width; the hit-testable area shrinks from pill to
//     a >=56px circle, never below the 48dp minimum.
//   * When [MediaQuery.disableAnimations] is true (reduced motion) the width
//     animation is skipped and the target state is applied immediately.
//
// The bottom offset is owned by the caller and derived from
// MediaQuery.paddingOf(context).bottom (gesture-nav safe); this widget itself
// is purely the pill/circle control.
// ==============================================================================

import 'package:flutter/material.dart';

import '../../../../app/theme/elder_theme.dart';

class FloatingSosButton extends StatelessWidget {
  /// Fired in BOTH collapsed and expanded states — identical functionality.
  final VoidCallback onPressed;

  /// When true the control animates to the icon-only circle.
  final bool collapsed;

  /// Coral gradient for the control. Defaults to the coral accent.
  final List<Color> gradient;

  /// Label shown in the expanded state. Kept short (two words max).
  final String label;

  const FloatingSosButton({
    super.key,
    required this.onPressed,
    required this.collapsed,
    this.gradient = ElderColors.clayGradCoral,
    this.label = 'Need help',
  });

  /// Diameter/height of the control — a confident, easy target. Well above the
  /// 48dp minimum and above the 56dp floor the spec requires for SOS.
  static const double _size = 60.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Reduced-motion: jump straight to the target state, no width tween.
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 350);

    return Semantics(
      button: true,
      label: label,
      hint: 'Shares your location with your caregiver',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(NirvanaRadii.pill),
        child: InkWell(
          // Full pill radius in both states so the ripple stays rounded.
          borderRadius: BorderRadius.circular(NirvanaRadii.pill),
          onTap: onPressed,
          splashColor: Colors.white.withValues(alpha: 0.18),
          highlightColor: Colors.transparent,
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeInOut,
            // Height is FIXED at _size (a control, not a text box) — this is the
            // one place a fixed dimension is correct. Width animates between the
            // pill and the circle.
            width: collapsed ? _size : _expandedWidth(context),
            height: _size,
            decoration: BoxDecoration(
              gradient: ElderColors.clayGradient(gradient),
              borderRadius: BorderRadius.circular(NirvanaRadii.pill),
              boxShadow: [
                // Ambient — coral-tinted, bottom-right.
                BoxShadow(
                  color: gradient.last.withValues(alpha: 0.42),
                  offset: const Offset(0, 8),
                  blurRadius: 18,
                ),
                // Warm-white highlight — top-left.
                BoxShadow(
                  color: ElderColors.clayBackgroundHighlight.withValues(
                    alpha: 0.55,
                  ),
                  offset: const Offset(-3, -3),
                  blurRadius: 10,
                ),
              ],
            ),
            // Clip so the label never paints outside the animating pill.
            child: ClipRRect(
              borderRadius: BorderRadius.circular(NirvanaRadii.pill),
              child: _SosContent(
                collapsed: collapsed,
                label: label,
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 17.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Pill width: icon + gap + label + both paddings. Measured from the label
  /// length rather than hardcoded, so a longer/translated label still fits.
  double _expandedWidth(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    // Rough advance width: ~0.62em per character at this weight, plus padding.
    final approxTextWidth = label.length * 17.0 * 0.62 * textScale;
    final width = 16.0 + 24.0 + 8.0 + approxTextWidth + 20.0;
    // Never narrower than the circle; never so wide it risks the screen edge.
    return width.clamp(_size, 200.0);
  }
}

/// Lays out the icon-only or icon+label content, fading the label with the
/// container so the width change and the text change stay in sync.
class _SosContent extends StatelessWidget {
  final bool collapsed;
  final String label;
  final TextStyle? textStyle;

  const _SosContent({
    required this.collapsed,
    required this.label,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    // Icon first; label fades/collapses beside it. In the collapsed circle the
    // Row hugs the single icon, so the icon stays perfectly centred.
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Icon(
            Icons.emergency_share_rounded,
            size: 28.0,
            color: Colors.white,
          ),
        ),
        if (!collapsed)
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(right: 18.0),
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.fade,
                style: textStyle,
              ),
            ),
          ),
      ],
    );
  }
}
