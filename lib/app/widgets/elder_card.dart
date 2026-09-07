// ==============================================================================
// NIRVANA - ElderCard
// Description: Prominent tactile card with generous padding, bold borders,
// and accessible touch surfaces for elderly users.
// ==============================================================================

import 'package:flutter/material.dart';
import '../theme/elder_theme.dart';

class ElderCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final String? semanticLabel;

  const ElderCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(22.0),
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 2.0,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHighContrast = theme.brightness == Brightness.light &&
        theme.primaryColor == ElderColors.highContrastPrimary;

    final effectiveBorderColor = borderColor ??
        (isHighContrast ? ElderColors.borderHighContrast : ElderColors.border);
    final effectiveBgColor = backgroundColor ?? theme.cardTheme.color ?? Colors.white;

    final cardContent = Container(
      constraints: const BoxConstraints(minHeight: ElderTheme.minTouchTargetSize),
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveBgColor,
        borderRadius: BorderRadius.circular(ElderTheme.cardBorderRadius),
        border: Border.all(
          color: effectiveBorderColor,
          width: isHighContrast ? 3.0 : borderWidth,
        ),
      ),
      child: child,
    );

    if (onTap == null) {
      return Semantics(
        container: true,
        label: semanticLabel,
        child: cardContent,
      );
    }

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(ElderTheme.cardBorderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ElderTheme.cardBorderRadius),
          child: cardContent,
        ),
      ),
    );
  }
}
