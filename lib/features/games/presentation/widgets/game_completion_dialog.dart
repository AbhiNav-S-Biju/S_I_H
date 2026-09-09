import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/providers/accessibility_providers.dart';
import '../../../../app/theme/elder_theme.dart';
import '../../../../core/network/audio_service.dart';
import '../../../../core/widgets/voice_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../models/game_session.dart';
import 'elder_game_button.dart';

class GameCompletionDialog extends ConsumerStatefulWidget {
  final GameSession session;
  final VoidCallback? onFinish;

  const GameCompletionDialog({
    super.key,
    required this.session,
    required this.onFinish,
  });

  static Future<bool?> show(
    BuildContext context, {
    required GameSession session,
    VoidCallback? onFinish,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) =>
          GameCompletionDialog(session: session, onFinish: onFinish),
    );
  }

  @override
  ConsumerState<GameCompletionDialog> createState() =>
      _GameCompletionDialogState();
}

class _GameCompletionDialogState extends ConsumerState<GameCompletionDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final voiceEnabled = ref.read(voiceEnabledProvider);
      if (voiceEnabled) {
        final locale = ref.read(localeProvider);
        ref
            .read(audioServiceProvider)
            .speak(
              widget.session.localizedSupportiveFeedback(locale.languageCode),
              languageCode: locale.languageCode,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final activeLocale = ref.watch(localeProvider);
    final feedbackMsg =
        widget.session.localizedSupportiveFeedback(activeLocale.languageCode);

    final String itemsFoundLabel;
    final String minutesActiveLabel;
    switch (activeLocale.languageCode) {
      case 'hi':
        itemsFoundLabel = 'वस्तुएं मिलीं';
        minutesActiveLabel = 'सक्रिय मिनट';
        break;
      case 'bn':
        itemsFoundLabel = 'পাওয়া বস্তু';
        minutesActiveLabel = 'সক্রিয় মিনিট';
        break;
      case 'as':
        itemsFoundLabel = 'বিচাৰি পোৱা বস্তু';
        minutesActiveLabel = 'সক্ৰিয় মিনিট';
        break;
      case 'ne':
        itemsFoundLabel = 'फेला परेका वस्तु';
        minutesActiveLabel = 'सक्रिय मिनेट';
        break;
      default:
        itemsFoundLabel = 'Items Found';
        minutesActiveLabel = 'Minutes Active';
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.0)),
      backgroundColor: Colors.white,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28.0),
          boxShadow: ElderColors.clayShadow(),
          border: Border.all(color: ElderColors.borderLight, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cheerful celebratory clay bubble
            Center(
              child: Container(
                width: 92.0,
                height: 92.0,
                decoration: BoxDecoration(
                  color: ElderColors.pastelSage,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3.0),
                  boxShadow: ElderColors.clayShadow(color: ElderColors.pastelSage),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 56.0,
                  color: ElderColors.forestDeep,
                ),
              ),
            ),
            const SizedBox(height: 20.0),

            // Friendly congratulatory title
            Text(
              l10n?.activityCompletedTitle ?? 'Activity Completed!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.w900,
                color: ElderColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14.0),

            // Warm supportive message card with speak button
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: ElderColors.pastelSage.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(ElderTheme.cardBorderRadius),
                border: Border.all(color: ElderColors.forestDeep.withValues(alpha: 0.2), width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      feedbackMsg,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                        color: ElderColors.forestDeep,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  SpeakButton(
                    text: feedbackMsg,
                    size: 38.0,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20.0),

            // Clean Non-Clinical Metric Summary Clay Card
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: ElderColors.background,
                borderRadius: BorderRadius.circular(ElderTheme.cardBorderRadius),
                border: Border.all(color: ElderColors.borderLight, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric(
                    label: itemsFoundLabel,
                    value:
                        '${widget.session.correctAnswers} / ${widget.session.totalQuestions}',
                    icon: Icons.star_rounded,
                    color: ElderColors.amberDeep,
                  ),
                  Container(
                    height: 36.0,
                    width: 1.5,
                    color: ElderColors.borderLight,
                  ),
                  _buildMetric(
                    label: minutesActiveLabel,
                    value:
                        '${(widget.session.durationSeconds / 60).ceil()} min',
                    icon: Icons.timer_outlined,
                    color: ElderColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            // Finish Button
            ElderGameButton(
              label: l10n?.finishButton ?? 'All Done',
              icon: Icons.check_circle_rounded,
              onPressed: () {
                Navigator.of(context).pop();
                widget.onFinish?.call();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22.0, color: color),
            const SizedBox(width: 6.0),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.w900,
                color: ElderColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4.0),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13.0,
            fontWeight: FontWeight.w700,
            color: ElderColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

