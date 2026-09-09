// ==============================================================================
// NIRVANA - My Days Screen
// Description: Familiar daily-routine activity with three calm modes.
// ==============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/accessibility_providers.dart';
import '../../../../core/network/audio_service.dart';
import '../../../../core/widgets/voice_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../controllers/my_days_controller.dart';
import '../../models/daily_activity.dart';
import '../../models/game_enums.dart';
import '../../models/game_session.dart';
import '../widgets/elder_game_button.dart';
import '../widgets/elder_game_card.dart';
import '../widgets/game_header.dart';

class MyDaysScreen extends ConsumerStatefulWidget {
  final GameDifficulty difficulty;
  final ValueChanged<GameSession>? onGameCompleted;
  final VoidCallback? onExit;

  const MyDaysScreen({
    super.key,
    this.difficulty = GameDifficulty.easy,
    this.onGameCompleted,
    this.onExit,
  });

  @override
  ConsumerState<MyDaysScreen> createState() => _MyDaysScreenState();
}

class _MyDaysScreenState extends ConsumerState<MyDaysScreen> {
  late final MyDaysController _controller;
  Timer? _memorizeTimer;
  GameSession? _recordedSession;
  String? _lastSpokenKey;

  @override
  void initState() {
    super.initState();
    _controller = MyDaysController(initialDifficulty: widget.difficulty);
  }

  @override
  void dispose() {
    _memorizeTimer?.cancel();
    super.dispose();
  }

  void _handleExit() {
    _memorizeTimer?.cancel();
    if (widget.onExit != null) {
      widget.onExit!();
    } else {
      Navigator.of(context).maybePop(_recordedSession);
    }
  }

  void _speak(String text, {String key = ''}) {
    if (!mounted) return;
    if (key.isNotEmpty && key == _lastSpokenKey) return;
    _lastSpokenKey = key;
    final voiceEnabled = ref.read(voiceEnabledProvider);
    if (!voiceEnabled) return;
    final locale = ref.read(localeProvider);
    ref.read(audioServiceProvider).speak(
          text,
          languageCode: locale.languageCode,
        );
  }

  void _scheduleMemorizeAdvance() {
    _memorizeTimer?.cancel();
    final duration = _controller.state.difficulty.myDaysMemorizeDuration;
    if (duration == Duration.zero) return;
    _memorizeTimer = Timer(duration, () {
      if (!mounted) return;
      if (_controller.state.phase != MyDaysPhase.memorizing) return;
      setState(() {
        _controller.proceedToRecall();
      });
      _speakPromptForPlaying();
    });
  }

  void _speakPromptForPlaying() {
    final l10n = AppLocalizations.of(context);
    final round = _controller.state.currentRound;
    final mode = _controller.state.mode;
    if (mode == MyDaysMode.whatComesNext) {
      _speak(
        l10n?.myDaysWhatComesNextPrompt ?? 'Which activity comes next?',
        key: 'next-${round?.id}',
      );
    } else if (mode == MyDaysMode.putInOrder) {
      _speak(
        l10n?.myDaysPutInOrderPrompt ??
            'Put these activities in the correct order.',
        key: 'order-${round?.id}',
      );
    } else if (mode == MyDaysMode.rememberMyDay) {
      _speak(_rememberQuestion(l10n), key: 'remember-${round?.id}');
    }
  }

  String _rememberQuestion(AppLocalizations? l10n) {
    final lang = ref.read(localeProvider).languageCode;
    final mentioned = _controller.state.currentRound?.mentionedActivity;
    if (mentioned != null) {
      final name = mentioned.localizedTitle(lang);
      return l10n?.myDaysYouHadActivity(name) ??
          'You had $name. What else did you do?';
    }
    return l10n?.myDaysWhichWasPartOfDay ??
        'Which activity was part of your day?';
  }

  String _periodLabel(TimeOfDayPeriod period, AppLocalizations? l10n) {
    switch (period) {
      case TimeOfDayPeriod.morning:
        return l10n?.myDaysMorning ?? 'Morning';
      case TimeOfDayPeriod.afternoon:
        return l10n?.myDaysAfternoon ?? 'Afternoon';
      case TimeOfDayPeriod.evening:
        return l10n?.myDaysEvening ?? 'Evening';
      case TimeOfDayPeriod.night:
        return l10n?.myDaysNight ?? 'Night';
    }
  }

  String _feedbackText(AppLocalizations? l10n, String lang) {
    final round = _controller.state.currentRound;
    final kind = _controller.state.feedbackKind;
    switch (kind) {
      case MyDaysFeedbackKind.nextCorrect:
        final previous = round?.prefix.isNotEmpty == true
            ? round!.prefix.last.localizedTitle(lang)
            : '';
        final next = round?.correctAnswer?.localizedTitle(lang) ?? '';
        return l10n?.myDaysNextCorrect(previous, next) ??
            'Well done! After $previous, it is time for $next.';
      case MyDaysFeedbackKind.nextIncorrect:
        return l10n?.myDaysNextIncorrect ??
            "That's okay. Let's try again.";
      case MyDaysFeedbackKind.orderCorrect:
        return l10n?.myDaysOrderCorrect ??
            'Wonderful! That is a familiar order for the day.';
      case MyDaysFeedbackKind.orderIncorrect:
        return l10n?.myDaysOrderIncorrect ??
            'Not quite. Let us think about what usually comes next.';
      case MyDaysFeedbackKind.rememberCorrect:
        return l10n?.myDaysRememberCorrect ?? 'Nice memory! You are doing well.';
      case MyDaysFeedbackKind.rememberIncorrect:
        return l10n?.myDaysRememberIncorrect ??
            "That's okay. Let's look at the day together.";
      case MyDaysFeedbackKind.none:
        return '';
    }
  }

  void _maybeRecordSession() {
    if (_controller.state.phase != MyDaysPhase.results) return;
    if (_recordedSession != null) return;
    final session = _controller.completeGame();
    setState(() {
      _recordedSession = session;
    });
    widget.onGameCompleted?.call(session);
    final l10n = AppLocalizations.of(context);
    _speak(
      l10n?.myDaysCompleteTitle ?? 'My Day Complete!',
      key: 'complete-${session.id}',
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context);
    final state = _controller.state;
    final lang = ref.read(localeProvider).languageCode;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          GameHeader(
            title: GameType.myDays.localizedTitle(l10n),
            difficulty: state.difficulty,
            onExit: _handleExit,
            onHint: state.phase == MyDaysPhase.playing
                ? () {
                    setState(() {
                      _controller.useHint();
                    });
                    if (state.mode == MyDaysMode.whatComesNext ||
                        state.mode == MyDaysMode.rememberMyDay) {
                      _maybeSpeakFeedback();
                    }
                  }
                : null,
            isHintAvailable: state.phase == MyDaysPhase.playing,
          ),
          Expanded(child: _buildBody(state, l10n, lang)),
        ],
      ),
    );
  }

  void _maybeSpeakFeedback() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final lang = ref.read(localeProvider).languageCode;
      final text = _feedbackText(l10n, lang);
      if (text.isNotEmpty) {
        _speak(text, key: 'fb-${_controller.state.currentRoundIndex}-$text');
      }
    });
  }

  Widget _buildBody(MyDaysState state, AppLocalizations? l10n, String lang) {
    switch (state.phase) {
      case MyDaysPhase.modeSelect:
        return _buildModeSelect(l10n);
      case MyDaysPhase.memorizing:
        return _buildMemorize(state, l10n, lang);
      case MyDaysPhase.playing:
        return _buildPlaying(state, l10n, lang);
      case MyDaysPhase.feedback:
        return _buildFeedback(state, l10n, lang);
      case MyDaysPhase.results:
        WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRecordSession());
        return _buildResults(l10n);
    }
  }

  Widget _buildModeSelect(AppLocalizations? l10n) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speak(
        l10n?.myDaysChooseMode ?? 'Choose a gentle way to play.',
        key: 'mode-select',
      );
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _instructionBanner(
            icon: Icons.wb_twilight_rounded,
            text: l10n?.myDaysChooseMode ??
                'Choose a gentle way to play with a familiar day.',
            speakText: l10n?.myDaysChooseMode ??
                'Choose a gentle way to play with a familiar day.',
          ),
          const SizedBox(height: 20.0),
          _modeCard(
            emoji: '➡️',
            title: l10n?.myDaysModeNextTitle ?? 'What Comes Next?',
            subtitle: l10n?.myDaysModeNextSubtitle ??
                'Look at the morning, then choose what usually follows.',
            color: const Color(0xFFDCFCE7),
            textColor: const Color(0xFF166534),
            onPlay: () {
              setState(() {
                _controller.selectMode(MyDaysMode.whatComesNext);
                _lastSpokenKey = null;
              });
              _speakPromptForPlaying();
            },
          ),
          const SizedBox(height: 16.0),
          _modeCard(
            emoji: '📋',
            title: l10n?.myDaysModeOrderTitle ?? 'Put My Day in Order',
            subtitle: l10n?.myDaysModeOrderSubtitle ??
                'Tap the activities in the order of a familiar day.',
            color: const Color(0xFFE0F2FE),
            textColor: const Color(0xFF075985),
            onPlay: () {
              setState(() {
                _controller.selectMode(MyDaysMode.putInOrder);
                _lastSpokenKey = null;
              });
              _speakPromptForPlaying();
            },
          ),
          const SizedBox(height: 16.0),
          _modeCard(
            emoji: '🧠',
            title: l10n?.myDaysModeRememberTitle ?? 'Remember My Day',
            subtitle: l10n?.myDaysModeRememberSubtitle ??
                'Look at a few activities, then remember one of them.',
            color: const Color(0xFFFEF3C7),
            textColor: const Color(0xFF92400E),
            onPlay: () {
              setState(() {
                _controller.selectMode(MyDaysMode.rememberMyDay);
                _lastSpokenKey = null;
              });
              final l10nNow = AppLocalizations.of(context);
              _speak(
                l10nNow?.myDaysRememberThese ?? 'Remember these activities.',
                key: 'mem-start',
              );
              _scheduleMemorizeAdvance();
            },
          ),
        ],
      ),
    );
  }

  Widget _modeCard({
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
    required Color textColor,
    required VoidCallback onPlay,
  }) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.0),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 60.0,
                height: 60.0,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 32.0)),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          ElderGameButton(
            label: l10n?.playActivityButton ?? 'Play Activity ➔',
            icon: Icons.play_arrow_rounded,
            onPressed: onPlay,
          ),
        ],
      ),
    );
  }

  Widget _progressChip(MyDaysState state, AppLocalizations? l10n) {
    final total = state.totalRounds;
    final current = total == 0 ? 0 : (state.currentRoundIndex + 1).clamp(1, total);
    final period = state.currentRound?.period;
    final periodText =
        period == null ? '' : _periodLabel(period, l10n);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        total == 0
            ? (l10n?.loadingMessage ?? 'Getting ready…')
            : '${l10n?.myDaysRoundProgress(current, total) ?? 'Part $current of $total'}${periodText.isEmpty ? '' : '  •  $periodText'}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.w700,
          color: Color(0xFF334155),
        ),
      ),
    );
  }

  Widget _buildMemorize(MyDaysState state, AppLocalizations? l10n, String lang) {
    final round = state.currentRound;
    if (round == null) {
      return Center(child: Text(l10n?.loadingMessage ?? 'Getting ready…'));
    }
    final items = round.activities;
    final names = items.map((e) => e.localizedTitle(lang)).join(', ');
    final prompt = l10n?.myDaysRememberThese ?? 'Remember these activities.';
    final readyOnly = state.difficulty.myDaysMemorizeDuration == Duration.zero;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _progressChip(state, l10n),
          _instructionBanner(
            icon: Icons.remove_red_eye_rounded,
            text: prompt,
            speakText: '$prompt $names',
          ),
          const SizedBox(height: 20.0),
          _activityGrid(items, lang),
          const SizedBox(height: 28.0),
          ElderGameButton(
            label: l10n?.iAmReadyButton ?? 'I am Ready ➔',
            icon: Icons.check_circle_outline_rounded,
            onPressed: () {
              _memorizeTimer?.cancel();
              setState(() {
                _controller.proceedToRecall();
              });
              _speakPromptForPlaying();
            },
          ),
          if (!readyOnly) ...[
            const SizedBox(height: 12.0),
            Text(
              l10n?.myDaysTakeYourTime ?? 'Take your time. There is no rush.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaying(MyDaysState state, AppLocalizations? l10n, String lang) {
    final round = state.currentRound;
    if (round == null) {
      return Center(child: Text(l10n?.loadingMessage ?? 'Getting ready…'));
    }

    switch (state.mode) {
      case MyDaysMode.whatComesNext:
        return _buildNextPlay(state, round, l10n, lang);
      case MyDaysMode.putInOrder:
        return _buildOrderPlay(state, round, l10n, lang);
      case MyDaysMode.rememberMyDay:
        return _buildRememberPlay(state, round, l10n, lang);
      case null:
        return _buildModeSelect(l10n);
    }
  }

  Widget _buildNextPlay(
    MyDaysState state,
    MyDaysRound round,
    AppLocalizations? l10n,
    String lang,
  ) {
    final prompt = l10n?.myDaysWhatComesNextPrompt ?? 'Which activity comes next?';
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _progressChip(state, l10n),
                _instructionBanner(
                  icon: Icons.arrow_forward_rounded,
                  text: prompt,
                  speakText: prompt,
                ),
                const SizedBox(height: 18.0),
                _sequenceRow(round.prefix, lang),
                const SizedBox(height: 8.0),
                Center(
                  child: Text(
                    '?',
                    style: TextStyle(
                      fontSize: 40.0,
                      fontWeight: FontWeight.w900,
                      color: Colors.teal.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                _choiceList(round.choices, state.selectedChoiceIds, lang),
                if (state.feedbackKind == MyDaysFeedbackKind.nextIncorrect)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      l10n?.myDaysNextIncorrect ?? "That's okay. Let's try again.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderPlay(
    MyDaysState state,
    MyDaysRound round,
    AppLocalizations? l10n,
    String lang,
  ) {
    final prompt =
        l10n?.myDaysPutInOrderPrompt ?? 'Put these activities in the correct order.';
    final cards = state.shuffledOrderCards.isEmpty
        ? round.orderedActivities
        : state.shuffledOrderCards;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _progressChip(state, l10n),
                _instructionBanner(
                  icon: Icons.format_list_numbered_rounded,
                  text: prompt,
                  speakText: prompt,
                ),
                const SizedBox(height: 16.0),
                if (state.orderPicks.isNotEmpty) ...[
                  Text(
                    l10n?.myDaysYourOrder ?? 'Your order',
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      for (var i = 0; i < state.orderPicks.length; i++)
                        _orderChip(
                          i + 1,
                          round.orderedActivities
                              .firstWhere(
                                (a) => a.id == state.orderPicks[i],
                                orElse: () => round.orderedActivities.first,
                              )
                              .localizedTitle(lang),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                ],
                ...cards.map((activity) {
                  final picked = state.orderPicks.contains(activity.id);
                  final index = state.orderPicks.indexOf(activity.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: ElderGameCard(
                      title: picked
                          ? '${index + 1}. ${activity.localizedTitle(lang)}'
                          : activity.localizedTitle(lang),
                      emoji: activity.emoji,
                      fallbackIcon: activity.icon,
                      iconColor: activity.tintColor,
                      isSelected: picked,
                      minHeight: 88.0,
                      onTap: picked
                          ? null
                          : () {
                              setState(() {
                                _controller.tapOrderActivity(activity.id);
                              });
                            },
                    ),
                  );
                }),
                if (state.feedbackKind == MyDaysFeedbackKind.orderIncorrect)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      l10n?.myDaysOrderIncorrect ??
                          'Not quite. Let us think about what usually comes next.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        _bottomBar(
          child: Row(
            children: [
              Expanded(
                child: ElderGameButton(
                  isSecondary: true,
                  label: l10n?.myDaysUndo ?? 'Undo',
                  icon: Icons.undo_rounded,
                  onPressed: state.orderPicks.isEmpty
                      ? null
                      : () {
                          setState(() {
                            _controller.undoLastOrderPick();
                          });
                        },
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: ElderGameButton(
                  label: l10n?.myDaysCheckOrder ?? 'Check Order',
                  icon: Icons.done_all_rounded,
                  onPressed: state.orderPicks.length ==
                          round.orderedActivities.length
                      ? () {
                          setState(() {
                            _controller.checkOrder();
                          });
                          _maybeSpeakFeedback();
                        }
                      : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRememberPlay(
    MyDaysState state,
    MyDaysRound round,
    AppLocalizations? l10n,
    String lang,
  ) {
    final prompt = _rememberQuestion(l10n);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _progressChip(state, l10n),
          _instructionBanner(
            icon: Icons.psychology_alt_rounded,
            text: prompt,
            speakText: prompt,
          ),
          const SizedBox(height: 18.0),
          _choiceList(round.choices, state.selectedChoiceIds, lang),
          if (state.feedbackKind == MyDaysFeedbackKind.rememberIncorrect)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                l10n?.myDaysRememberIncorrect ??
                    "That's okay. Let's look at the day together.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeedback(MyDaysState state, AppLocalizations? l10n, String lang) {
    final round = state.currentRound;
    final text = _feedbackText(l10n, lang);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (text.isNotEmpty) {
        _speak(text, key: 'feedback-${state.currentRoundIndex}-$text');
      }
    });

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _progressChip(state, l10n),
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: state.lastAnswerCorrect
                        ? const Color(0xFFF0FDF4)
                        : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                      color: state.lastAnswerCorrect
                          ? const Color(0xFFBBF7D0)
                          : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        state.lastAnswerCorrect
                            ? Icons.favorite_rounded
                            : Icons.spa_rounded,
                        size: 36.0,
                        color: state.lastAnswerCorrect
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFB45309),
                      ),
                      const SizedBox(width: 14.0),
                      Expanded(
                        child: Text(
                          text,
                          style: const TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      SpeakButton(text: text, size: 36.0),
                    ],
                  ),
                ),
                const SizedBox(height: 20.0),
                if (round != null) ...[
                  Text(
                    l10n?.myDaysCorrectSequence ?? 'A familiar order',
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  ...List.generate(round.orderedActivities.length, (i) {
                    final activity = round.orderedActivities[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: ElderGameCard(
                        title: '${i + 1}. ${activity.localizedTitle(lang)}',
                        emoji: activity.emoji,
                        fallbackIcon: activity.icon,
                        iconColor: activity.tintColor,
                        isSelected: true,
                        minHeight: 80.0,
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
        _bottomBar(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElderGameButton(
                label: l10n?.continueButton ?? 'Continue',
                icon: Icons.arrow_forward_rounded,
                onPressed: () {
                  setState(() {
                    _controller.continueAfterFeedback();
                    _lastSpokenKey = null;
                  });
                  if (_controller.state.phase == MyDaysPhase.memorizing) {
                    _speak(
                      l10n?.myDaysRememberThese ?? 'Remember these activities.',
                      key: 'mem-${_controller.state.currentRoundIndex}',
                    );
                    _scheduleMemorizeAdvance();
                  } else if (_controller.state.phase == MyDaysPhase.playing) {
                    _speakPromptForPlaying();
                  } else {
                    _maybeRecordSession();
                  }
                },
              ),
              const SizedBox(height: 10.0),
              ElderGameButton(
                isSecondary: true,
                label: l10n?.myDaysReplayRound ?? 'Try this one again',
                icon: Icons.refresh_rounded,
                onPressed: () {
                  setState(() {
                    _controller.replayRound();
                    _lastSpokenKey = null;
                  });
                  if (_controller.state.phase == MyDaysPhase.memorizing) {
                    _scheduleMemorizeAdvance();
                  } else {
                    _speakPromptForPlaying();
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResults(AppLocalizations? l10n) {
    final session = _recordedSession;
    final correct = session?.correctAnswers ?? _controller.state.correctAnswers;
    final total = session?.totalQuestions ??
        (_controller.state.totalRounds == 0 ? 1 : _controller.state.totalRounds);
    final summary = l10n?.myDaysRememberedSummary(correct, total) ??
        'Wonderful! You remembered $correct out of $total activities.';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Icon(
              Icons.wb_sunny_rounded,
              size: 72.0,
              color: Color(0xFFD97706),
            ),
          ),
          const SizedBox(height: 16.0),
          Text(
            l10n?.myDaysCompleteTitle ?? 'My Day Complete!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28.0,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16.0),
          Container(
            padding: const EdgeInsets.all(18.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(18.0),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    summary,
                    style: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF14532D),
                    ),
                  ),
                ),
                SpeakButton(text: summary, size: 36.0),
              ],
            ),
          ),
          const SizedBox(height: 20.0),
          _resultStat(
            l10n?.myDaysActivitiesCompleted ?? 'Activities completed',
            '$total',
          ),
          _resultStat(
            l10n?.myDaysGentleMatches ?? 'Gentle matches',
            '$correct',
          ),
          const SizedBox(height: 28.0),
          ElderGameButton(
            label: l10n?.myDaysPlayAgain ?? 'Play Again',
            icon: Icons.replay_rounded,
            onPressed: () {
              _memorizeTimer?.cancel();
              setState(() {
                _recordedSession = null;
                _lastSpokenKey = null;
                _controller.startFresh(difficulty: widget.difficulty);
              });
            },
          ),
          const SizedBox(height: 12.0),
          ElderGameButton(
            isSecondary: true,
            label: l10n?.myDaysBackToGames ?? 'Back to Games',
            icon: Icons.home_rounded,
            onPressed: () {
              Navigator.of(context).maybePop(_recordedSession);
            },
          ),
        ],
      ),
    );
  }

  Widget _resultStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F766E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _instructionBanner({
    required IconData icon,
    required String text,
    required String speakText,
  }) {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF16A34A), size: 32.0),
          const SizedBox(width: 14.0),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w700,
                color: Color(0xFF14532D),
              ),
            ),
          ),
          SpeakButton(text: speakText, size: 36.0),
        ],
      ),
    );
  }

  Widget _sequenceRow(List<DailyActivity> items, String lang) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _miniActivity(items[i], lang),
          if (i != items.length - 1)
            const Padding(
              padding: EdgeInsets.only(top: 28.0),
              child: Icon(Icons.arrow_forward_rounded, color: Color(0xFF0F766E)),
            ),
        ],
      ],
    );
  }

  Widget _miniActivity(DailyActivity activity, String lang) {
    return Container(
      width: 120.0,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 2.0),
      ),
      child: Column(
        children: [
          Text(activity.emoji, style: const TextStyle(fontSize: 32.0)),
          const SizedBox(height: 6.0),
          Text(
            activity.localizedTitle(lang),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15.0,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityGrid(List<DailyActivity> items, String lang) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 640 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12.0,
            mainAxisSpacing: 12.0,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return ElderGameCard(
              title: item.localizedTitle(lang),
              emoji: item.emoji,
              fallbackIcon: item.icon,
              iconColor: item.tintColor,
            );
          },
        );
      },
    );
  }

  Widget _choiceList(
    List<DailyActivity> choices,
    Set<String> selected,
    String lang,
  ) {
    if (choices.isEmpty) {
      return Text(
        AppLocalizations.of(context)?.loadingMessage ?? 'Getting ready…',
        textAlign: TextAlign.center,
      );
    }
    return Column(
      children: choices.map((choice) {
        final isSelected = selected.contains(choice.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: ElderGameCard(
            title: choice.localizedTitle(lang),
            emoji: choice.emoji,
            fallbackIcon: choice.icon,
            iconColor: choice.tintColor,
            isSelected: isSelected,
            minHeight: 96.0,
            onTap: () {
              setState(() {
                _controller.selectChoice(choice.id);
              });
              if (_controller.state.phase == MyDaysPhase.feedback) {
                _maybeSpeakFeedback();
              }
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _orderChip(int number, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFFCCFBF1),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFF5EEAD4), width: 1.5),
      ),
      child: Text(
        '$number. $label',
        style: const TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w800,
          color: Color(0xFF115E59),
        ),
      ),
    );
  }

  Widget _bottomBar({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}
