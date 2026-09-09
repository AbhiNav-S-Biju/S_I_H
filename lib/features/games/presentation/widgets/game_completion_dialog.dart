import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/providers/accessibility_providers.dart';
import '../../../../app/theme/elder_theme.dart';
import '../../../../core/network/audio_service.dart';
import '../../../../core/widgets/voice_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../models/game_level.dart';
import '../../models/game_session.dart';
import '../../services/game_progress_service.dart';
import 'elder_game_button.dart';

class GameCompletionDialog extends ConsumerStatefulWidget {
  final GameSession session;
  final VoidCallback? onFinish;
  final GameLevel? level;
  final VoidCallback? onNextLevel;

  const GameCompletionDialog({
    super.key,
    required this.session,
    required this.onFinish,
    this.level,
    this.onNextLevel,
  });

  static Future<bool?> show(
    BuildContext context, {
    required GameSession session,
    VoidCallback? onFinish,
    GameLevel? level,
    VoidCallback? onNextLevel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => GameCompletionDialog(
        session: session,
        onFinish: onFinish,
        level: level,
        onNextLevel: onNextLevel,
      ),
    );
  }

  @override
  ConsumerState<GameCompletionDialog> createState() =>
      _GameCompletionDialogState();
}

class _GameCompletionDialogState extends ConsumerState<GameCompletionDialog> {
  int _starsEarned = 1;

  @override
  void initState() {
    super.initState();
    _calculateAndSaveProgress();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final voiceEnabled = ref.read(voiceEnabledProvider);
      if (voiceEnabled) {
        final locale = ref.read(localeProvider);
        final feedbackMsg =
            widget.session.localizedSupportiveFeedback(locale.languageCode);
        final starMsg = _getStarEncouragement(locale.languageCode);
        ref.read(audioServiceProvider).speak(
              '$starMsg. $feedbackMsg',
              languageCode: locale.languageCode,
            );
      }
    });
  }

  void _calculateAndSaveProgress() {
    final acc = widget.session.completionRate;
    final hints = widget.session.hintsUsed;
    if (acc >= 0.85 && hints <= 1) {
      _starsEarned = 3;
    } else if (acc >= 0.5) {
      _starsEarned = 2;
    } else {
      _starsEarned = 1;
    }

    if (widget.level != null) {
      GameProgressService.instance.completeLevel(
        gameType: widget.level!.gameType,
        levelNumber: widget.level!.levelNumber,
        stars: _starsEarned,
        timeSeconds: widget.session.durationSeconds,
      );
    }
  }

  String _getStarEncouragement(String langCode) {
    if (_starsEarned == 3) {
      switch (langCode) {
        case 'as':
          return 'অসাধাৰণ! আপুনি ৩ টা তৰা লাভ কৰিলে!';
        case 'hi':
          return 'शानदार! आपको ३ सितारे मिले!';
        case 'bn':
          return 'অসাধারণ! আপনি ৩টি তারা পেলেন!';
        default:
          return 'Superb! You earned 3 stars!';
      }
    } else if (_starsEarned == 2) {
      switch (langCode) {
        case 'as':
          return 'বৰ ধুনীয়া! আপুনি ২ টা তৰা লাভ কৰিলে!';
        case 'hi':
          return 'बहुत बढ़िया! आपको २ सितारे मिले!';
        case 'bn':
          return 'দারুণ হয়েছে! আপনি ২টি তারা পেলেন!';
        default:
          return 'Wonderful work! You earned 2 stars!';
      }
    } else {
      switch (langCode) {
        case 'as':
          return 'ভাল কাম! আপুনি ১ টা তৰা লাভ কৰিলে!';
        case 'hi':
          return 'शाबाश! आपने १ सितारा अर्जित किया!';
        case 'bn':
          return 'খুব ভালো! আপনি ১টি তারা পেলেন!';
        default:
          return 'Great progress! You earned 1 star!';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final activeLocale = ref.watch(localeProvider);
    final feedbackMsg =
        widget.session.localizedSupportiveFeedback(activeLocale.languageCode);
    final starEncouragement = _getStarEncouragement(activeLocale.languageCode);

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

    final level = widget.level;
    final hasNextLevel = level != null &&
        level.levelNumber < 8 &&
        widget.onNextLevel != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.0)),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
        decoration: BoxDecoration(
          color: ElderColors.surface,
          borderRadius: BorderRadius.circular(28.0),
          boxShadow: NirvanaShadows.card(),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Level Badge if in journey mode
            if (level != null) ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 6.0,
                  ),
                  decoration: BoxDecoration(
                    color: level.themeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(NirvanaRadii.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(level.icon, size: 18.0, color: level.themeColor),
                      const SizedBox(width: 6.0),
                      Text(
                        'Level ${level.levelNumber}: ${level.localizedTitle(activeLocale.languageCode)}',
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w800,
                          color: level.themeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14.0),
            ],

            // Golden Star Row
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 10.0,
                ),
                decoration: BoxDecoration(
                  color: ElderColors.pastelButtercupBg,
                  borderRadius: BorderRadius.circular(NirvanaRadii.pill),
                  boxShadow: NirvanaShadows.float(tint: ElderColors.amberDeep),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    final isFilled = index < _starsEarned;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: Icon(
                        isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 40.0,
                        color: isFilled
                            ? ElderColors.amberDeep
                            : ElderColors.textMuted.withValues(alpha: 0.4),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 14.0),

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
            const SizedBox(height: 6.0),
            Text(
              starEncouragement,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w700,
                color: ElderColors.amberDeep,
              ),
            ),
            const SizedBox(height: 12.0),

            // Warm supportive message card with speak button
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: ElderColors.pastelSageBg,
                borderRadius: BorderRadius.circular(ElderTheme.cardBorderRadius),
                boxShadow: NirvanaShadows.card(tint: ElderColors.forestDeep),
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
                    text: '$starEncouragement. $feedbackMsg',
                    size: 38.0,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18.0),

            // Clean Non-Clinical Metric Summary Clay Card
            Container(
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: ElderColors.surfaceElevated,
                borderRadius: BorderRadius.circular(ElderTheme.cardBorderRadius),
                boxShadow: NirvanaShadows.input,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric(
                    label: itemsFoundLabel,
                    value:
                        '${widget.session.correctAnswers} / ${widget.session.totalQuestions}',
                    icon: Icons.check_circle_outline_rounded,
                    color: ElderColors.forestDeep,
                  ),
                  Container(
                    height: 32.0,
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
            const SizedBox(height: 22.0),

            // Action Buttons (Next Level + Back to Map)
            if (hasNextLevel) ...[
              ElderGameButton(
                label: activeLocale.languageCode == 'as'
                    ? 'পৰবৰ্তী স্তৰ ➔'
                    : activeLocale.languageCode == 'hi'
                        ? 'अगला स्तर ➔'
                        : activeLocale.languageCode == 'bn'
                            ? 'পরবর্তী ধাপ ➔'
                            : 'Next Level ➔',
                icon: Icons.arrow_forward_rounded,
                backgroundColor: level.themeColor,
                onPressed: () {
                  Navigator.of(context).pop(true);
                  widget.onNextLevel?.call();
                },
              ),
              const SizedBox(height: 10.0),
              ElderGameButton(
                label: activeLocale.languageCode == 'as'
                    ? 'মানচিত্ৰলৈ উভতি যাওক'
                    : activeLocale.languageCode == 'hi'
                        ? 'मानचित्र पर वापस'
                        : activeLocale.languageCode == 'bn'
                            ? 'মানচিত্রে ফিরে যান'
                            : 'Back to Map',
                icon: Icons.map_outlined,
                isSecondary: true,
                onPressed: () {
                  Navigator.of(context).pop(false);
                  widget.onFinish?.call();
                },
              ),
            ] else ...[
              ElderGameButton(
                label: level != null
                    ? (activeLocale.languageCode == 'as'
                        ? 'মানচিত্ৰলৈ উভতি যাওক'
                        : activeLocale.languageCode == 'hi'
                            ? 'मानचित्र पर वापस'
                            : activeLocale.languageCode == 'bn'
                                ? 'মানচিত্রে ফিরে যান'
                                : 'Back to Map')
                    : (l10n?.finishButton ?? 'All Done'),
                icon: Icons.check_rounded,
                backgroundColor: level?.themeColor ?? ElderColors.forestDeep,
                onPressed: () {
                  Navigator.of(context).pop(true);
                  widget.onFinish?.call();
                },
              ),
            ],
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
                fontSize: 18.0,
                fontWeight: FontWeight.w800,
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
