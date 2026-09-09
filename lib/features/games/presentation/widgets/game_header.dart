// ==============================================================================
// NIRVANA - GameHeader Widget
// Description: Accessible top bar with difficulty badge, hint action, and gentle close
// ==============================================================================

import 'package:flutter/material.dart';
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
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Close / Exit button
            IconButton(
              tooltip: l10n?.exitActivityTooltip ?? 'Exit Activity',
              iconSize: 32.0,
              padding: const EdgeInsets.all(8.0),
              constraints: const BoxConstraints(
                minWidth: 54.0,
                minHeight: 54.0,
              ),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF1E293B),
              ),
              onPressed: () {
                _showExitConfirmDialog(context, l10n);
              },
            ),
            const SizedBox(width: 8.0),
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
                      fontSize: 22.0,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6.0,
                    runSpacing: 2.0,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 2.0,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Text(
                          difficulty.localizedLabel(l10n),
                          style: const TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0369A1),
                          ),
                        ),
                      ),
                      Text(
                        '• ${l10n?.activitiesNavLabel ?? 'Activity'}',
                        style: const TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Hint Button
            if (onHint != null)
              Semantics(
                button: true,
                label: 'Get a helpful hint',
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFFFFBEB),
                    foregroundColor: const Color(0xFFB45309),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 12.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      side: const BorderSide(
                        color: Color(0xFFFDE68A),
                        width: 1.5,
                      ),
                    ),
                    minimumSize: const Size(90.0, 50.0),
                  ),
                  onPressed: isHintAvailable ? onHint : null,
                  icon: const Icon(Icons.lightbulb_rounded, size: 22.0),
                  label: Text(
                    l10n?.hintButton ?? 'Hint',
                    style: const TextStyle(
                      fontSize: 17.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
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
          borderRadius: BorderRadius.circular(20.0),
        ),
        title: Text(
          l10n?.leaveActivityTitle ?? 'Leave Activity?',
          style: const TextStyle(fontSize: 22.0, fontWeight: FontWeight.w800),
        ),
        content: Text(
          l10n?.leaveActivityMessage ??
              'You can return anytime. Would you like to stop for now?',
          style: const TextStyle(fontSize: 18.0, color: Color(0xFF334155)),
        ),
        actionsPadding: const EdgeInsets.all(16.0),
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
              style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE2E8F0),
              foregroundColor: const Color(0xFF0F172A),
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 18.0,
                vertical: 12.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              onExit();
            },
            child: Text(
              l10n?.yesExit ?? 'Yes, Exit',
              style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
