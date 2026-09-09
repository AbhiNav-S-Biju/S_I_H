// ==============================================================================
// NIRVANA - LoadingState
// Description: Calming, dignified loading placeholder with supportive text
// and smooth circular indicator.
// ==============================================================================

import 'package:flutter/material.dart';
import '../theme/elder_theme.dart';

class LoadingState extends StatelessWidget {
  final String message;

  const LoadingState({
    super.key,
    this.message = 'Getting everything ready for you...',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 28.0),
          decoration: BoxDecoration(
            color: ElderColors.surface,
            borderRadius: BorderRadius.circular(ElderTheme.cardBorderRadius),
            boxShadow: ElderColors.clayShadow(),
            border: Border.all(color: ElderColors.borderLight, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: ElderColors.pastelLavender.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  width: 48.0,
                  height: 48.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 4.5,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      ElderColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ElderColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

