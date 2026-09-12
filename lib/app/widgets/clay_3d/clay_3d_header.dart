// ==============================================================================
// NIRVANA — 3D Claymorphic Screen Header
// Description: Consistent top header used by every secondary screen: large
// back button, wrapping title and optional trailing action. Fully responsive —
// the title wraps, the row never overflows, and it respects SafeArea.
// ==============================================================================

import 'package:flutter/material.dart';
import '../../theme/elder_theme.dart';
import 'clay_3d_theme.dart';

class ClayHeader3D extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;
  final IconData? icon;

  const ClayHeader3D({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (onBack != null) ...[
            _HeaderIconButton(
              icon: Icons.arrow_back_rounded,
              semanticLabel: 'Go back',
              onTap: onBack!,
            ),
            const SizedBox(width: 14.0),
          ] else if (icon != null) ...[
            Container(
              width: 52.0,
              height: 52.0,
              decoration: BoxDecoration(
                color: ElderColors.primaryContainer,
                borderRadius: BorderRadius.circular(
                  ElderTheme.buttonBorderRadius,
                ),
                boxShadow: Clay3DTheme.cardShadow(blur: 10, offset: 4),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 28.0, color: ElderColors.primaryDark),
            ),
            const SizedBox(width: 14.0),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: ElderColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2.0),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: ElderColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10.0), trailing!],
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ElderTheme.buttonBorderRadius),
          child: Container(
            width: 56.0,
            height: 56.0,
            decoration: BoxDecoration(
              color: ElderColors.surface,
              borderRadius: BorderRadius.circular(
                ElderTheme.buttonBorderRadius,
              ),
              boxShadow: Clay3DTheme.cardShadow(blur: 12, offset: 5),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 30.0, color: ElderColors.textPrimary),
          ),
        ),
      ),
    );
  }
}
