// ==============================================================================
// NIRVANA — 3D Claymorphic Section, Stat & Feature Cards
// Description: Small reusable clay building blocks shared across screens so
// spacing, radius, shadows and typography stay consistent everywhere.
// ==============================================================================

import 'package:flutter/material.dart';
import '../../theme/elder_theme.dart';
import '../../theme/nirvana_responsive.dart';
import 'clay_3d_theme.dart';

/// A padding-consistent clay section container with an optional header row.
/// The header row wraps/expands so long titles never overflow.
class ClaySection3D extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Color? accentColor;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  const ClaySection3D({
    super.key,
    this.title,
    this.subtitle,
    this.icon,
    this.accentColor,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.all(NirvanaSpacing.lg),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = accentColor ?? ElderColors.primary;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? ElderColors.surface,
        borderRadius: BorderRadius.circular(NirvanaRadii.card),
        boxShadow: Clay3DTheme.cardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Container(
                    width: 48.0,
                    height: 48.0,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(NirvanaRadii.icon),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 26.0, color: accent),
                  ),
                  const SizedBox(width: 14.0),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: ElderColors.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2.0),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: ElderColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 10.0),
                  trailing!,
                ],
              ],
            ),
          if (title != null) const SizedBox(height: NirvanaSpacing.md),
          child,
        ],
      ),
    );
  }
}

/// A large, tappable feature/navigation card with icon disc, wrapping title and
/// optional caption. Reflows gracefully and never clips text.
class ClayFeatureCard3D extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String? caption;
  final Widget? badge;
  final VoidCallback? onTap;
  final bool compact;

  const ClayFeatureCard3D({
    super.key,
    required this.icon,
    required this.accentColor,
    required this.title,
    this.caption,
    this.badge,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Padding(
      padding: EdgeInsets.all(compact ? 14.0 : 18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: compact ? 44.0 : 52.0,
                height: compact ? 44.0 : 52.0,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(NirvanaRadii.icon),
                  boxShadow: Clay3DTheme.cardShadow(blur: 10, offset: 4),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: compact ? 24.0 : 28.0,
                  color: accentColor,
                ),
              ),
              const Spacer(),
              if (badge != null) badge!,
            ],
          ),
          SizedBox(height: compact ? 12.0 : 16.0),
          Text(
            title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style:
                (compact
                        ? theme.textTheme.titleMedium
                        : theme.textTheme.titleLarge)
                    ?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: ElderColors.textPrimary,
                    ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 4.0),
            Text(
              caption!,
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
    );

    return Semantics(
      button: onTap != null,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(NirvanaRadii.card),
          child: Ink(
            decoration: BoxDecoration(
              color: ElderColors.surface,
              borderRadius: BorderRadius.circular(NirvanaRadii.card),
              boxShadow: Clay3DTheme.cardShadow(),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Compact metric/stat tile used on dashboards.
class ClayStatCard3D extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color accentColor;

  const ClayStatCard3D({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    this.accentColor = ElderColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(NirvanaSpacing.md),
      decoration: BoxDecoration(
        color: ElderColors.surface,
        borderRadius: BorderRadius.circular(NirvanaRadii.card),
        boxShadow: Clay3DTheme.cardShadow(blur: 14, offset: 6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 26.0, color: accentColor),
          const SizedBox(height: 10.0),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: ElderColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 2.0),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: ElderColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
