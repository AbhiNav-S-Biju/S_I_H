// ==============================================================================
// NIRVANA - EmptyState
// Description: Peaceful, unhurried empty state widget with supportive cues
// and clear call-to-action for seniors.
// ==============================================================================

import 'package:flutter/material.dart';
import '../theme/elder_theme.dart';
import 'large_action_button.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.spa_rounded,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84.0,
              height: 84.0,
              decoration: const BoxDecoration(
                color: ElderColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48.0,
                color: ElderColors.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24.0),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: ElderColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12.0),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: ElderColors.textSecondary,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 28.0),
              LargeActionButton(
                label: actionLabel!,
                onPressed: onAction,
                icon: Icons.arrow_forward_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
