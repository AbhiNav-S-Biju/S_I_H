// ==============================================================================
// NIRVANA — Responsive Layout & Spacing System
// Description: Centralised breakpoints, adaptive spacing/typography helpers and
// a content-width clamp so every screen stays usable on small phones, large
// phones, tablets, landscape, and at any system font scale. No screen should
// hardcode screen dimensions — use these helpers instead.
// ==============================================================================

import 'package:flutter/material.dart';

/// Adaptive spacing scale. All numeric gaps in the UI should come from here so
/// padding/margins stay consistent and scale with the available width.
class NirvanaSpacing {
  NirvanaSpacing._();

  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;

  /// Standard horizontal page padding. Grows slightly on wide screens.
  static double pageHorizontal(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 600 ? 28.0 : 18.0;

  /// Standard vertical page padding.
  static const double pageVertical = 16.0;

  /// Uniform page padding EdgeInsets that adapts to width.
  static EdgeInsetsGeometry page(BuildContext context) => EdgeInsets.symmetric(
    horizontal: pageHorizontal(context),
    vertical: pageVertical,
  );
}

/// Breakpoints & device-class helpers.
class NirvanaBreakpoints {
  NirvanaBreakpoints._();

  static const double compact = 360.0; // very small phones
  static const double small = 400.0;
  static const double medium = 600.0; // large phones / small tablets
  static const double expanded = 900.0; // tablets / landscape

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compact;
  static bool isSmall(BuildContext context) =>
      MediaQuery.sizeOf(context).width < small;
  static bool isAtLeastMedium(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= medium;

  /// True when the device is in a wide/landscape configuration where
  /// multi-column layouts are comfortable.
  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= medium;
}

/// Layout helpers built on [LayoutBuilder] so the current constraints (not the
/// whole screen) drive the sizing decisions.
class NirvanaLayout {
  NirvanaLayout._();

  /// Number of columns that comfortably fit 2-tile / card grids.
  static int gridColumns(double maxWidth) {
    if (maxWidth >= 720) return 3;
    if (maxWidth >= 520) return 2;
    if (maxWidth >= 360) return 2;
    return 2;
  }

  /// Child width for a grid of [columns] inside [maxWidth] with [spacing].
  static double gridChildWidth({
    required double maxWidth,
    required int columns,
    double spacing = NirvanaSpacing.md,
  }) {
    if (columns <= 1) return maxWidth;
    final usable = maxWidth - spacing * (columns - 1);
    final w = usable / columns;
    return w.isFinite && w > 0 ? w : maxWidth;
  }

  /// Max width for a centred single-column card layout, so text lines never get
  /// uncomfortably long on tablets / landscape.
  static const double readableContentWidth = 560.0;
}

/// Wraps [child] in a centred column clamped to a readable max width. Use for
/// login/onboarding forms and single-column content so it never stretches to
/// absurd line lengths on tablets.
class NirvanaContentWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const NirvanaContentWidth({
    super.key,
    required this.child,
    this.maxWidth = NirvanaLayout.readableContentWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// A responsive action-group that lays buttons out side-by-side when there is
/// room and stacks them vertically when the width (or font scale) is too tight.
/// Buttons therefore shrink/reflow instead of overflowing.
class NirvanaButtonRow extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double stackBelow;

  const NirvanaButtonRow({
    super.key,
    required this.children,
    this.spacing = NirvanaSpacing.sm,
    this.stackBelow = 360.0,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    if (children.length == 1) return children.first;

    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final shouldStack =
            constraints.maxWidth < stackBelow || textScale > 1.35;
        if (shouldStack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: spacing),
                children[i],
              ],
            ],
          );
        }
        return Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(width: spacing),
              Expanded(child: children[i]),
            ],
          ],
        );
      },
    );
  }
}

/// Scales a base icon/label size up on larger screens but keeps it within a
/// usable band so touch targets remain comfortable on small phones.
double nirvanaAdaptiveScale(
  BuildContext context, {
  double min = 0.9,
  double max = 1.15,
}) {
  final w = MediaQuery.sizeOf(context).width;
  final t =
      ((w - NirvanaBreakpoints.compact) /
              (NirvanaBreakpoints.expanded - NirvanaBreakpoints.compact))
          .clamp(0.0, 1.0);
  return min + (max - min) * t;
}
