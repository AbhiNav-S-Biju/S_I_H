// ==============================================================================
// NIRVANA — Patient dashboard header (date pill + greeting row)
// Description: The gold date pill and the greeting/name row with two clay icon
// buttons (favourite, logout).
//
// Overflow-prevention (spec §3):
//   * The greeting column is wrapped in an [Expanded] inside the Row, while the
//     icon buttons are fixed-size. A long patient name therefore wraps/ellipsises
//     inside its own column instead of shoving the icon buttons off-screen.
//   * Name uses `maxLines: 2` + ellipsis so translated or long names stay
//     readable without breaking the row.
//   * Icon buttons keep a >=48dp tap target via [ClayIconButton]'s sizing.
// ==============================================================================

import 'package:flutter/material.dart';

import '../../../../app/theme/elder_theme.dart';
import '../../../../app/widgets/clay_3d/clay_surface.dart';

/// Small rounded gold-tinted clay label showing today's date.
class DatePill extends StatelessWidget {
  final String label;

  const DatePill({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return ClaySurface(
      radius: NirvanaRadii.pill,
      // Gold *tint* on the clay surface, not a saturated fill — keeps the pill
      // quiet against the sand background.
      color: ElderColors.clayGradGold.first.withValues(alpha: 0.30),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
      shadowBlur: 10.0,
      shadowOffset: 3.0,
      semanticLabel: label,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          // 13sp floor — never shrink the date to make it fit.
          fontSize: 13.0,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
          color: ElderColors.clayInk,
        ),
      ),
    );
  }
}

/// Fixed-size clay icon button used for the header's favourite/logout actions.
///
/// Kept >=48dp so it always clears the minimum touch target, and it pairs the
/// icon with a semantics label (colour/icon is never the only signal).
class ClayIconButton extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;

  const ClayIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: ClaySurface(
        radius: NirvanaRadii.icon,
        // 52dp square — comfortably above the 48dp minimum.
        padding: EdgeInsets.zero,
        shadowBlur: 10.0,
        shadowOffset: 3.0,
        onTap: onTap,
        semanticLabel: semanticLabel,
        child: SizedBox(
          width: 52.0,
          height: 52.0,
          child: Center(
            child: Icon(icon, size: 24.0, color: ElderColors.clayInk),
          ),
        ),
      ),
    );
  }
}

/// Header row: date pill + greeting/name on the left, two clay icon buttons on
/// the right. The text side expands; the buttons stay put.
class PatientHeader extends StatelessWidget {
  final String dateLabel;
  final String greeting;
  final String patientName;
  final VoidCallback onFavorite;
  final VoidCallback onLogout;

  const PatientHeader({
    super.key,
    required this.dateLabel,
    required this.greeting,
    required this.patientName,
    required this.onFavorite,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        DatePill(label: dateLabel),
        const SizedBox(height: 12.0),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // -------------------------------------------------------------
            // EXPANDED greeting block — long names ellipsise inside this
            // column rather than pushing the icon buttons off-screen.
            // -------------------------------------------------------------
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    greeting,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w600,
                      color: ElderColors.clayInkSoft,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    patientName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: ElderColors.clayInk,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12.0),

            // -------------------------------------------------------------
            // FIXED-SIZE ACTIONS — 52dp each with an 8px gap.
            // -------------------------------------------------------------
            ClayIconButton(
              icon: Icons.favorite_rounded,
              semanticLabel: 'Favourites',
              onTap: onFavorite,
            ),
            const SizedBox(width: 8.0),
            ClayIconButton(
              icon: Icons.logout_rounded,
              semanticLabel: 'Log out',
              onTap: onLogout,
            ),
          ],
        ),
      ],
    );
  }
}
