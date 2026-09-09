// ==============================================================================
// NIRVANA - LargeActionButton
// Description: Accessible, high-contrast, tactile claymorphic action button with
// minimum touch target of 64dp and min 22sp text for seniors.
// ==============================================================================

import 'package:flutter/material.dart';
import '../theme/elder_theme.dart';

enum LargeActionButtonVariant { primary, secondary, gentleWarning, sage, peach, buttercup }
typedef ElderButtonScheme = LargeActionButtonVariant;

class LargeActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final LargeActionButtonVariant variant;
  final String? semanticLabel;
  final double minHeight;
  final double? borderRadius;

  const LargeActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    LargeActionButtonVariant? variant,
    LargeActionButtonVariant? colorScheme,
    this.semanticLabel,
    this.minHeight = ElderTheme.buttonHeight,
    this.borderRadius,
  }) : variant = colorScheme ?? variant ?? LargeActionButtonVariant.primary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle =
        theme.textTheme.labelLarge ??
        const TextStyle(fontSize: 22.0, fontWeight: FontWeight.w800);

    Color bg;
    Color fg;
    BorderSide border;
    List<BoxShadow>? shadow;

    switch (variant) {
      case LargeActionButtonVariant.primary:
        bg = ElderColors.primary;
        fg = Colors.white;
        border = BorderSide.none;
        shadow = ElderColors.buttonShadow(color: ElderColors.primary);
        break;
      case LargeActionButtonVariant.secondary:
        bg = ElderColors.surface;
        fg = ElderColors.textPrimary;
        border = const BorderSide(color: ElderColors.borderLight, width: 2.0);
        shadow = ElderColors.clayShadow();
        break;
      case LargeActionButtonVariant.gentleWarning:
      case LargeActionButtonVariant.peach:
        bg = ElderColors.pastelPeach;
        fg = Colors.white;
        border = BorderSide.none;
        shadow = ElderColors.buttonShadow(color: ElderColors.pastelPeach);
        break;
      case LargeActionButtonVariant.sage:
        bg = ElderColors.pastelSage;
        fg = Colors.white;
        border = BorderSide.none;
        shadow = ElderColors.buttonShadow(color: ElderColors.pastelSage);
        break;
      case LargeActionButtonVariant.buttercup:
        bg = ElderColors.pastelButtercup;
        fg = Colors.white;
        border = BorderSide.none;
        shadow = ElderColors.buttonShadow(color: ElderColors.pastelButtercup);
        break;
    }

    final isEnabled = onPressed != null && !isLoading;
    final effectiveRadius = borderRadius ?? ElderTheme.buttonBorderRadius;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: semanticLabel ?? label,
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        decoration: BoxDecoration(
          color: isEnabled ? bg : ElderColors.surfaceElevated,
          borderRadius: BorderRadius.circular(effectiveRadius),
          border: isEnabled
              ? (border == BorderSide.none ? null : Border.fromBorderSide(border))
              : Border.all(color: ElderColors.border, width: 1.5),
          boxShadow: isEnabled ? shadow : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(effectiveRadius),
          child: InkWell(
            onTap: isEnabled ? onPressed : null,
            borderRadius: BorderRadius.circular(effectiveRadius),
            splashColor: fg.withValues(alpha: 0.15),
            highlightColor: fg.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 28.0,
                        height: 28.0,
                        child: CircularProgressIndicator(
                          strokeWidth: 3.0,
                          valueColor: AlwaysStoppedAnimation<Color>(fg),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, size: 28.0, color: fg),
                            const SizedBox(width: 14.0),
                          ],
                          Flexible(
                            child: Text(
                              label,
                              style: textStyle.copyWith(
                                color: fg,
                                fontWeight: FontWeight.w800,
                                fontSize: 20.0,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
