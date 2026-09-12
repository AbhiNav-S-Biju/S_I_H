// ==============================================================================
// NIRVANA — DailyMomentCard
// Description: Full-width purple-gradient clay card. Eyebrow label, affirmation
// headline, one supporting sentence, and a small icon badge.
//
// Overflow-prevention (spec §3):
//   * The text block sits in an [Expanded] inside its full-width Row, so the
//     icon badge never gets compressed and the text always wraps rather than
//     overflowing.
//   * The headline/supporting text use `maxLines` with ellipsis — truncation is
//     visually acceptable here because the full affirmation is also spoken
//     elsewhere; the card itself must never clip the badge.
//   * No fixed height is set: the card grows taller to accommodate larger
//     system font scales instead of clipping the sentence.
// ==============================================================================

import 'package:flutter/material.dart';

import '../../../../app/theme/elder_theme.dart';
import '../../../../app/widgets/clay_3d/clay_surface.dart';

class DailyMomentCard extends StatelessWidget {
  /// Short eyebrow label, e.g. "DAILY MOMENT".
  final String eyebrow;

  /// The affirmation headline, e.g. "You are doing wonderfully".
  final String headline;

  /// One supporting sentence beneath the headline.
  final String supportingText;

  /// Icon shown in the translucent badge on the right.
  final IconData icon;

  /// Gradient for the card fill. Defaults to the purple accent.
  final List<Color> gradient;

  const DailyMomentCard({
    super.key,
    required this.headline,
    required this.supportingText,
    this.eyebrow = 'DAILY MOMENT',
    this.icon = Icons.spa_rounded,
    this.gradient = ElderColors.clayGradPurple,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClaySurface(
      padding: const EdgeInsets.all(20.0),
      gradient: ElderColors.clayGradient(gradient),
      shadowOffset: 8.0,
      shadowBlur: 20.0,
      semanticLabel: '$eyebrow. $headline. $supportingText',
      child: Row(
        // Center keeps the badge vertically balanced against a wrapped headline.
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // -----------------------------------------------------------------
          // Flexible TEXT BLOCK — Expanded guarantees the badge keeps its size
          // and the text wraps within the remaining space on narrow phones.
          // -----------------------------------------------------------------
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _EyebrowChip(label: eyebrow),
                const SizedBox(height: 10.0),
                Text(
                  headline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  supportingText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.94),
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14.0),

          // -----------------------------------------------------------------
          // FIXED-SIZE ICON BADGE — only the badge has a fixed size; the cell
          // around it is driven by the Expanded text above.
          // -----------------------------------------------------------------
          _IconBadge(icon: icon),
        ],
      ),
    );
  }
}

class _EyebrowChip extends StatelessWidget {
  final String label;

  const _EyebrowChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(NirvanaRadii.pill),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          // 13sp is the smallest permitted label size for this audience —
          // never shrink further to make something fit.
          fontSize: 13.0,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;

  const _IconBadge({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56.0,
      height: 56.0,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.42),
          width: 1.5,
        ),
      ),
      child: Icon(icon, size: 30.0, color: Colors.white),
    );
  }
}
