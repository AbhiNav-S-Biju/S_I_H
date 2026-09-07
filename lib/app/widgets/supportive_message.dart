// ==============================================================================
// NIRVANA - SupportiveMessage
// Description: Calming, comforting message card designed to reassure elderly
// users, reduce anxiety, and foster a peaceful interaction.
// ==============================================================================

import 'package:flutter/material.dart';
import '../theme/elder_theme.dart';

class SupportiveMessage extends StatelessWidget {
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SupportiveMessage({
    super.key,
    required this.message,
    this.icon = Icons.favorite_rounded,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      label: 'Helpful message: $message',
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: ElderColors.supportiveBg,
          borderRadius: BorderRadius.circular(ElderTheme.cardBorderRadius),
          border: Border.all(
            color: ElderColors.supportiveBorder,
            width: 2.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 32.0,
              color: ElderColors.supportiveIcon,
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
                      color: ElderColors.supportiveText,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: 10.0),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: ElderColors.supportiveText,
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
