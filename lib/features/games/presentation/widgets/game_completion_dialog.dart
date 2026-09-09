import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/providers/accessibility_providers.dart';
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
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cheerful celebratory badge
            Center(
              child: Container(
                width: 84.0,
                height: 84.0,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7), // Soft mint green
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 56.0,
                  color: Color(0xFF16A34A),
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
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12.0),

            // Warm supportive message card with speak button
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 8.0,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      feedbackMsg,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        fontSize: 17.0,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                  SpeakButton(
                    text: feedbackMsg,
                    size: 38.0,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            // Clean Non-Clinical Metric Summary Card
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric(
                    label: itemsFoundLabel,
                    value:
                        '${widget.session.correctAnswers} / ${widget.session.totalQuestions}',
                    icon: Icons.star_rounded,
                    color: const Color(0xFFD97706),
                  ),
                  Container(
                    height: 36.0,
                    width: 1.5,
                    color: const Color(0xFFCBD5E1),
                  ),
                  _buildMetric(
                    label: minutesActiveLabel,
                    value:
                        '${(widget.session.durationSeconds / 60).ceil()} min',
                    icon: Icons.timer_outlined,
                    color: const Color(0xFF0F766E),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28.0),

            // Finish Button
            ElderGameButton(
              label: l10n?.finishButton ?? 'All Done',
              icon: Icons.arrow_forward_rounded,
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
            Icon(icon, size: 20.0, color: color),
            const SizedBox(width: 6.0),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4.0),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
