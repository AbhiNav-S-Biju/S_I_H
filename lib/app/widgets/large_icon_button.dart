// ==============================================================================
// NIRVANA - LargeIconButton
// Description: Tactile square/rounded icon button with guaranteed >=64dp touch
// target and explicit semantic labeling for screen readers.
// ==============================================================================

import 'package:flutter/material.dart';
import '../theme/elder_theme.dart';

class LargeIconButton extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;

  const LargeIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = ElderTheme.minTouchTargetSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onPressed != null;

    final effectiveBg = backgroundColor ?? ElderColors.surface;
    final effectiveFg = iconColor ?? theme.colorScheme.primary;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: semanticLabel,
      child: Material(
        color: isEnabled ? effectiveBg : ElderColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ElderTheme.buttonBorderRadius),
          side: const BorderSide(color: ElderColors.border, width: 2.0),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(ElderTheme.buttonBorderRadius),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 32.0,
              color: isEnabled ? effectiveFg : ElderColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
