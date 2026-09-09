// ==============================================================================
// NIRVANA - GameHeader Widget
// Description: Accessible claymorphic top bar with difficulty badge, hint action,
// and gentle close
// ==============================================================================

import 'package:flutter/material.dart';
import '../../../../app/theme/elder_theme.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../models/game_enums.dart';

class GameHeader extends StatelessWidget {
  final String title;
  final GameDifficulty difficulty;
  final VoidCallback onExit;
  final VoidCallback? onHint;
  final bool isHintAvailable;

  const GameHeader({
    super.key,
    required this.title,
    required this.difficulty,
    required this.onExit,
    this.onHint,
    this.isHintAvailable = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: ElderColors.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24.0)),
        boxShadow: NirvanaShadows.card(),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Close / Exit button
            LargeIconButton(
              icon: Icons.arrow_back_rounded,
              semanticLabel: l10n?.exitActivityTooltip ?? 'Exit Activity',
              size: 48,
              onPressed: () {
                _showExitConfirmDialog(context, l10n);
              },
            ),
            const SizedBox(width: 12.0),
            // Title & Difficulty Tag
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w900,
                      color: ElderColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    l10n?.activitiesNavLabel ?? 'Activity',
                    style: const TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                      color: ElderColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Hint Button
            if (onHint != null) ...[
              const SizedBox(width: 8.0),
              Semantics(
                button: true,
                label: 'Get a helpful hint',
                child: Container(
                  decoration: BoxDecoration(
                    color: isHintAvailable ? ElderColors.pastelButtercupBg : ElderColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: isHintAvailable ? ElderColors.amberDeep.withValues(alpha: 0.3) : ElderColors.borderLight,
                      width: 1.5,
                    ),
                    boxShadow: isHintAvailable ? NirvanaShadows.float(tint: ElderColors.amberDeep) : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16.0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16.0),
                      onTap: isHintAvailable ? onHint : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14.0,
                          vertical: 10.0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lightbulb_rounded,
                              size: 22.0,
                              color: isHintAvailable ? ElderColors.amberDeep : ElderColors.textMuted,
                            ),
                            const SizedBox(width: 6.0),
                            Text(
                              l10n?.hintButton ?? 'Hint',
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w800,
                                color: isHintAvailable ? ElderColors.amberDeep : ElderColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showExitConfirmDialog(BuildContext context, AppLocalizations? l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ElderTheme.cardBorderRadius),
        ),
        title: Text(
          l10n?.leaveActivityTitle ?? 'Leave Activity?',
          style: const TextStyle(fontSize: 22.0, fontWeight: FontWeight.w900, color: ElderColors.textPrimary),
        ),
        content: Text(
          l10n?.leaveActivityMessage ??
              'You can return anytime. Would you like to stop for now?',
          style: const TextStyle(fontSize: 17.0, color: ElderColors.textSecondary, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.all(20.0),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 18.0,
                vertical: 12.0,
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              l10n?.stayAndContinue ?? 'Stay & Continue',
              style: const TextStyle(fontSize: 17.0, fontWeight: FontWeight.w700, color: ElderColors.primary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ElderColors.pastelPeach,
              foregroundColor: ElderColors.coralDeep,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 18.0,
                vertical: 12.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.0),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              onExit();
            },
            child: Text(
              l10n?.yesExit ?? 'Yes, Exit',
              style: const TextStyle(fontSize: 17.0, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
