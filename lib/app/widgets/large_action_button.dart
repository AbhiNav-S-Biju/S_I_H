// ==============================================================================
// NIRVANA - LargeActionButton
// Description: Accessible, high-contrast, tactile action button with a minimum
// touch target of 64dp and min 22sp text for seniors and motor-impaired users.
// ==============================================================================

import 'package:flutter/material.dart';
import '../theme/elder_theme.dart';

enum LargeActionButtonVariant { primary, secondary, gentleWarning }

class LargeActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final LargeActionButtonVariant variant;
  final String? semanticLabel;
  final double minHeight;

  const LargeActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.variant = LargeActionButtonVariant.primary,
    this.semanticLabel,
    this.minHeight = ElderTheme.buttonHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.labelLarge ??
        const TextStyle(fontSize: 22.0, fontWeight: FontWeight.w800);

    Color bg;
    Color fg;
    BorderSide border;

    switch (variant) {
      case LargeActionButtonVariant.primary:
        bg = theme.colorScheme.primary;
        fg = theme.colorScheme.onPrimary;
        border = BorderSide.none;
        break;
      case LargeActionButtonVariant.secondary:
        bg = theme.colorScheme.surface;
        fg = theme.colorScheme.onSurface;
        border = const BorderSide(color: ElderColors.border, width: 2.5);
        break;
      case LargeActionButtonVariant.gentleWarning:
        bg = ElderColors.supportiveBg;
        fg = ElderColors.supportiveText;
        border = const BorderSide(color: ElderColors.supportiveBorder, width: 2.0);
        break;
    }

    final isEnabled = onPressed != null && !isLoading;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: semanticLabel ?? label,
      child: Material(
        color: isEnabled ? bg : ElderColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ElderTheme.buttonBorderRadius),
          side: border,
        ),
        elevation: 0.0,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(ElderTheme.buttonBorderRadius),
          child: Container(
            constraints: BoxConstraints(
              minHeight: minHeight,
              minWidth: ElderTheme.minTouchTargetSize,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            alignment: Alignment.center,
            child: isLoading
                ? SizedBox(
                    width: 28.0,
                    height: 28.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.5,
                      valueColor: AlwaysStoppedAnimation<Color>(fg),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 28.0, color: isEnabled ? fg : ElderColors.textMuted),
                        const SizedBox(width: 12.0),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: textStyle.copyWith(
                            color: isEnabled ? fg : ElderColors.textMuted,
                          ),
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
