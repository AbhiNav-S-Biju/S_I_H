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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 56.0,
              height: 56.0,
              child: CircularProgressIndicator(
                strokeWidth: 4.5,
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 24.0),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: ElderColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
