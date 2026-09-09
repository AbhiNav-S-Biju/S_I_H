// ==============================================================================
// NIRVANA - ElderCard
// Description: Shadow-first claymorphic card. The card edge is defined by a
// soft warm shadow, not a border stroke. A border is only added when the
// caller explicitly passes borderColor, or in high-contrast mode.
// ==============================================================================

import 'package:flutter/material.dart';
import '../theme/elder_theme.dart';
import 'clay_3d/clay_3d_theme.dart';

class ElderCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final double? borderRadius;
  final List<BoxShadow>? customShadow;
  final String? semanticLabel;

  const ElderCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(22.0),
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.5,
    this.borderRadius,
    this.customShadow,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHighContrast =
        theme.brightness == Brightness.light &&
        theme.primaryColor == ElderColors.highContrastPrimary;

    final effectiveBgColor =
        backgroundColor ?? theme.cardTheme.color ?? ElderColors.surface;
    final effectiveRadius = borderRadius ?? ElderTheme.cardBorderRadius;

    // Shadow-first: border is only drawn when explicitly requested or HC mode.
    final hasBorder = borderColor != null || isHighContrast;
    final effectiveBorderColor = borderColor ??
        (isHighContrast ? ElderColors.borderHighContrast : ElderColors.borderLight);

    final decoration = BoxDecoration(
      color: effectiveBgColor,
      borderRadius: BorderRadius.circular(effectiveRadius),
      border: hasBorder
          ? Border.all(
              color: effectiveBorderColor,
              width: isHighContrast ? 2.0 : borderWidth,
            )
          : null,
      boxShadow: isHighContrast
          ? null
          : (customShadow ?? Clay3DTheme.cardShadow()),
    );

    final cardContent = Padding(
      padding: padding,
      child: child,
    );

    if (onTap == null) {
      return Semantics(
        container: true,
        label: semanticLabel,
        child: Container(
          decoration: decoration,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(effectiveRadius),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: ElderTheme.minTouchTargetSize,
              ),
              child: cardContent,
            ),
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Container(
        decoration: decoration,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(effectiveRadius),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(effectiveRadius),
            splashColor: ElderColors.primary.withValues(alpha: 0.1),
            highlightColor: ElderColors.primary.withValues(alpha: 0.05),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: ElderTheme.minTouchTargetSize,
              ),
              child: cardContent,
            ),
          ),
        ),
      ),
    );
  }
}
