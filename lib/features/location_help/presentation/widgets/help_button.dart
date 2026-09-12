// ==============================================================================
// NIRVANA - HelpButton (Patient Home)
// Description: Large, unmissable "I'M LOST / I NEED HELP" action.
//
// Senior-friendly rules applied here:
//   - Huge tap target (well above the 48dp minimum).
//   - Very high contrast, plain words, no jargon.
//   - The word HELP is spelled out, not implied by an icon alone.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:nirvana/app/theme/elder_theme.dart';

class HelpButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isSharing;

  const HelpButton({
    super.key,
    required this.onPressed,
    this.isSharing = false,
  });

  @override
  Widget build(BuildContext context) {
    const dangerSurface = Color(0xFFD32F2F);
    const sharingSurface = Color(0xFF2E7D32);

    final background = isSharing ? sharingSurface : dangerSurface;
    final label = isSharing ? 'SHARING MY LOCATION' : 'I\'M LOST / I NEED HELP';
    final subLabel = isSharing
        ? 'Your caregiver can see where you are'
        : 'Tap here and your caregiver will see where you are';

    return Semantics(
      button: true,
      label: label,
      hint: subLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(ElderTheme.cardBorderRadius),
          child: Ink(
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(ElderTheme.cardBorderRadius),
              boxShadow: [
                BoxShadow(
                  color: background.withValues(alpha: 0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 22.0,
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSharing
                          ? Icons.location_on_rounded
                          : Icons.emergency_share_rounded,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.15,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 34,
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
