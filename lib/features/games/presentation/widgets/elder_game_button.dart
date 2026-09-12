// ==============================================================================
// NIRVANA - ElderGameButton Widget
// Description: Large, high-contrast, accessible claymorphic touch button (min 64dp)
// ==============================================================================

import 'package:flutter/material.dart';
import '../../../../app/theme/elder_theme.dart';

class ElderGameButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double minHeight;
  final bool isSecondary;

  const ElderGameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.minHeight = 64.0,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBg = isSecondary
        ? Colors.white
        : ElderColors.primary;
    final defaultFg = isSecondary ? ElderColors.textPrimary : Colors.white;

    final bg = backgroundColor ?? defaultBg;
    final fg = foregroundColor ?? defaultFg;
    final isEnabled = onPressed != null;

    return Semantics(
      button: true,
      label: label,
      enabled: isEnabled,
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        decoration: BoxDecoration(
          color: isEnabled ? bg : ElderColors.surfaceElevated,
          borderRadius: BorderRadius.circular(ElderTheme.buttonBorderRadius),
          border: isSecondary
              ? Border.all(color: ElderColors.borderLight, width: 2.0)
              : null,
          boxShadow: isEnabled
              ? (isSecondary ? ElderColors.clayShadow() : ElderColors.buttonShadow(color: bg))
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(ElderTheme.buttonBorderRadius),
          child: InkWell(
            onTap: isEnabled ? onPressed : null,
            borderRadius: BorderRadius.circular(ElderTheme.buttonBorderRadius),
            splashColor: fg.withValues(alpha: 0.15),
            highlightColor: fg.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 26.0,
                      color: isEnabled ? fg : ElderColors.textMuted,
                    ),
                    const SizedBox(width: 10.0),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 19.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: isEnabled ? fg : ElderColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

