// ==============================================================================
// NIRVANA - ErrorState
// Description: Supportive, non-alarming error state designed to avoid anxiety
// or stress for elderly users, using warm terracotta/amber tones instead of
// aggressive red alerts.
// ==============================================================================

import 'package:flutter/material.dart';
import '../theme/elder_theme.dart';
import 'large_action_button.dart';

class ErrorState extends StatelessWidget {
  final String title;
  final String message;
  final String? retryLabel;
  final VoidCallback? onRetry;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  const ErrorState({
    super.key,
    this.title = "Let's Take a Gentle Pause",
    this.message = 'We ran into a small hiccup. Everything is safe and your progress is saved.',
    this.retryLabel = 'Try Again',
    this.onRetry,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28.0),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: ElderColors.gentleErrorBg,
            borderRadius: BorderRadius.circular(ElderTheme.cardBorderRadius),
            border: Border.all(
              color: ElderColors.gentleErrorBorder,
              width: 2.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76.0,
                height: 76.0,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_outline_rounded,
                  size: 42.0,
                  color: ElderColors.gentleErrorPrimary,
                ),
              ),
              const SizedBox(height: 20.0),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: ElderColors.gentleErrorText,
                ),
              ),
              const SizedBox(height: 12.0),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: ElderColors.gentleErrorText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 28.0),
              if (onRetry != null && retryLabel != null)
                LargeActionButton(
                  label: retryLabel!,
                  onPressed: onRetry,
                  icon: Icons.refresh_rounded,
                ),
              if (onSecondaryAction != null && secondaryActionLabel != null) ...[
                const SizedBox(height: 14.0),
                LargeActionButton(
                  label: secondaryActionLabel!,
                  onPressed: onSecondaryAction,
                  variant: LargeActionButtonVariant.secondary,
                  icon: Icons.home_rounded,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
