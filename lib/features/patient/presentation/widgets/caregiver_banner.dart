// ==============================================================================
// NIRVANA — CaregiverBanner
// Description: Sage clay card with a gradient icon badge and one reassuring
// sentence about the caregiver.
//
// Overflow-prevention (spec §3):
//   * The message sits in an [Expanded] beside the fixed-size icon badge, so it
//     wraps onto as many lines as it needs (bounded by `maxLines: 3` with
//     ellipsis) rather than overflowing next to the badge.
//   * No fixed height — the banner grows taller at large font scales instead of
//     clipping the reassurance the patient needs to read.
//   * Copy stays warm and plain; this is not an alert surface (the SOS control
//     is the only place allowed to be urgent).
// ==============================================================================

import 'package:flutter/material.dart';

import '../../../../app/theme/elder_theme.dart';
import '../../../../app/widgets/clay_3d/clay_surface.dart';

class CaregiverBanner extends StatelessWidget {
  /// Plain, reassuring sentence, e.g. "Your caregiver can see you are okay."
  final String message;

  /// Optional caregiver name woven into the message by the caller.
  final IconData icon;

  /// Two-stop sage gradient used for the icon badge.
  final List<Color> gradient;

  const CaregiverBanner({
    super.key,
    required this.message,
    this.icon = Icons.favorite_rounded,
    this.gradient = ElderColors.clayGradSage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClaySurface(
      padding: const EdgeInsets.all(18.0),
      semanticLabel: message,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // -----------------------------------------------------------------
          // FIXED-SIZE BADGE — sage gradient so the card reads as the sage
          // "care" surface; the icon is single-colour white for contrast.
          // -----------------------------------------------------------------
          Container(
            width: 48.0,
            height: 48.0,
            decoration: BoxDecoration(
              gradient: ElderColors.clayGradient(gradient),
              borderRadius: BorderRadius.circular(NirvanaRadii.icon),
              boxShadow: [
                BoxShadow(
                  color: gradient.last.withValues(alpha: 0.30),
                  offset: const Offset(0, 4),
                  blurRadius: 10,
                ),
                BoxShadow(
                  color: ElderColors.clayBackgroundHighlight.withValues(
                    alpha: 0.70,
                  ),
                  offset: const Offset(-3, -3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(icon, size: 24.0, color: Colors.white),
          ),
          const SizedBox(width: 14.0),

          // -----------------------------------------------------------------
          // WRAPPING MESSAGE — Flexible so long/translated strings wrap and
          // grow the card height instead of being clipped.
          // -----------------------------------------------------------------
          Expanded(
            child: Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 15.0,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: ElderColors.clayInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
