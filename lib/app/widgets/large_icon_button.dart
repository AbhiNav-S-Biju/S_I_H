// ==============================================================================
// NIRVANA - LargeIconButton
// Description: Tactile square/rounded icon button with guaranteed >=64dp touch
// target, claymorphic dual shadows, and explicit semantic labeling.
// ==============================================================================

import 'package:flutter/material.dart';
import '../theme/elder_theme.dart';
import 'clay_3d/clay_3d_theme.dart';

class LargeIconButton extends StatelessWidget {
  final IconData icon;
  final String? semanticLabel;
  final String? tooltip;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final double? borderRadius;

  const LargeIconButton({
    super.key,
    required this.icon,
    this.semanticLabel,
    this.tooltip,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = ElderTheme.minTouchTargetSize,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onPressed != null;

    final effectiveBg = backgroundColor ?? ElderColors.surface;
    final effectiveFg = iconColor ?? theme.colorScheme.primary;
    final effectiveRadius = borderRadius ?? ElderTheme.buttonBorderRadius;
    final effectiveLabel = semanticLabel ?? tooltip ?? 'Action button';

    Widget button = Semantics(
      button: true,
      enabled: isEnabled,
      label: effectiveLabel,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isEnabled ? effectiveBg : ElderColors.surfaceElevated,
          borderRadius: BorderRadius.circular(effectiveRadius),
          border: Border.all(color: ElderColors.borderLight, width: 1.5),
            boxShadow: isEnabled
              ? Clay3DTheme.cardShadow(blur: 12, offset: 5)
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(effectiveRadius),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(effectiveRadius),
            splashColor: effectiveFg.withValues(alpha: 0.15),
            highlightColor: effectiveFg.withValues(alpha: 0.08),
            child: Container(
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: size * 0.45,
                color: isEnabled ? effectiveFg : ElderColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}
