// ==============================================================================
// NIRVANA - SupportiveMessage
// Description: Calming, comforting claymorphic message card designed to reassure
// elderly users, reduce anxiety, and foster a peaceful interaction.
// ==============================================================================

import 'package:flutter/material.dart';
import '../theme/elder_theme.dart';

class SupportiveMessage extends StatelessWidget {
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? backgroundColor;
  final Color? accentColor;

  const SupportiveMessage({
    super.key,
    required this.message,
    this.icon = Icons.spa_rounded,
    this.actionLabel,
    this.onAction,
    this.backgroundColor,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = backgroundColor ?? ElderColors.pastelSage;
    final fg = accentColor ?? ElderColors.forestDeep;

    return Semantics(
      container: true,
      label: 'Helpful message: $message',
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(ElderTheme.cardBorderRadius),
          boxShadow: NirvanaShadows.card(tint: fg),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28.0, color: fg),
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: 10.0),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: fg,
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        textStyle: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w800,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      onPressed: onAction,
                      child: Text(actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

