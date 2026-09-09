import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/providers/accessibility_providers.dart';
import '../../../../core/network/audio_service.dart';
import '../../../../core/widgets/voice_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../controllers/who_is_this_controller.dart';
import '../../models/family_member_item.dart';
import '../../models/game_enums.dart';
import '../../models/game_level.dart';
import '../../models/game_session.dart';
import '../widgets/elder_game_button.dart';
import '../widgets/game_completion_dialog.dart';
import '../widgets/game_header.dart';

class WhoIsThisScreen extends ConsumerStatefulWidget {
  final GameDifficulty difficulty;
  final ValueChanged<GameSession>? onGameCompleted;
  final VoidCallback? onExit;
  final GameLevel? level;

  const WhoIsThisScreen({
    super.key,
    this.difficulty = GameDifficulty.easy,
    this.onGameCompleted,
    this.onExit,
    this.level,
  });

  @override
  ConsumerState<WhoIsThisScreen> createState() => _WhoIsThisScreenState();
}

class _WhoIsThisScreenState extends ConsumerState<WhoIsThisScreen> {
  late final WhoIsThisController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WhoIsThisController(
      initialDifficulty: widget.level?.difficulty ?? widget.difficulty,
    );
    _speakCurrentQuestion();
  }

  void _speakCurrentQuestion() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final voiceEnabled = ref.read(voiceEnabledProvider);
      if (voiceEnabled) {
        final currentMember = _controller.state.currentQuestion;
        if (currentMember != null) {
          final locale = ref.read(localeProvider);
          final question =
              currentMember.localizedQuestionPrompt(locale.languageCode);
          final voiceNote =
              currentMember.localizedVoiceNoteTranscription(locale.languageCode);
          ref
              .read(audioServiceProvider)
              .speak(
                '$question. $voiceNote',
                languageCode: locale.languageCode,
              );
        }
      }
    });
  }

  void _handleExit() {
    if (widget.onExit != null) {
      widget.onExit!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _handleCompletion(GameSession session) {
    if (widget.onGameCompleted != null) {
      widget.onGameCompleted!(session);
    }
    Navigator.of(context).maybePop(session);
  }

  void _loadNextLevel(int nextLevelNumber) {
    final allLevels = GameLevel.getLevelsForGame(GameType.whoIsThis);
    final next = allLevels.firstWhere(
      (l) => l.levelNumber == nextLevelNumber,
      orElse: () => allLevels.last,
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => WhoIsThisScreen(
          level: next,
          onGameCompleted: widget.onGameCompleted,
          onExit: widget.onExit,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeLocale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context);
    final state = _controller.state;
    final langCode = activeLocale.languageCode;
    final currentMember = state.currentQuestion;

    if (currentMember == null) {
      return const Scaffold(
        body: Center(child: Text('No questions available.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Header Bar
          GameHeader(
            title: widget.level != null
                ? 'Level ${widget.level!.levelNumber}: ${widget.level!.localizedTitle(langCode)}'
                : GameType.whoIsThis.localizedTitle(l10n),
            difficulty: state.difficulty,
            onExit: _handleExit,
            onHint: () {
              setState(() {
                _controller.useHint();
              });
              final currentMember = _controller.state.currentQuestion;
              if (currentMember != null && ref.read(voiceEnabledProvider)) {
                final locale = ref.read(localeProvider);
                final hint =
                    currentMember.localizedHintDescription(locale.languageCode);
                ref
                    .read(audioServiceProvider)
                    .speak(hint, languageCode: locale.languageCode);
              }
            },
            isHintAvailable: true,
          ),

          // Main Interactive Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress Indicator (e.g. Card 1 of 3)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        langCode == 'hi'
                            ? 'कार्ड ${state.currentQuestionIndex + 1} / ${state.questions.length}'
                            : langCode == 'bn'
                                ? 'কার্ড ${state.currentQuestionIndex + 1} / ${state.questions.length}'
                                : langCode == 'as'
                                    ? 'কাৰ্ড ${state.currentQuestionIndex + 1} / ${state.questions.length}'
                                    : langCode == 'ne'
                                        ? 'कार्ड ${state.currentQuestionIndex + 1} / ${state.questions.length}'
                                        : 'Card ${state.currentQuestionIndex + 1} / ${state.questions.length}',
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          l10n?.familyAndFriends ?? 'Family & Friends',
                          style: const TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // Big Avatar Card
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(
                        color: const Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8.0,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Avatar illustration
                        Container(
                          width: 110.0,
                          height: 110.0,
                          decoration: BoxDecoration(
                            color: currentMember.avatarColor.withAlpha(35),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: currentMember.avatarColor,
                              width: 3.0,
                            ),
                          ),
                          child: Icon(
                            currentMember.avatarIcon,
                            size: 64.0,
                            color: currentMember.avatarColor,
                          ),
                        ),
                        const SizedBox(height: 14.0),
                        Text(
                          currentMember.localizedName(langCode),
                          style: const TextStyle(
                            fontSize: 26.0,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 12.0),

                        // Voice Prompt Banner with Speak Button
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 10.0,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.volume_up_rounded,
                                color: Color(0xFF0F766E),
                                size: 24.0,
                              ),
                              const SizedBox(width: 10.0),
                              Expanded(
                                child: Text(
                                  '"${currentMember.localizedVoiceNoteTranscription(langCode)}"',
                                  style: const TextStyle(
                                    fontSize: 16.0,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ),
                              SpeakButton(
                                text: currentMember
                                    .localizedVoiceNoteTranscription(langCode),
                                size: 36.0,
                              ),
                            ],
                          ),
                        ),

                        // Active Hint Text if triggered
                        if (state.activeHintText != null) ...[
                          const SizedBox(height: 12.0),
                          Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(
                                color: const Color(0xFFFDE68A),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.lightbulb_rounded,
                                  color: Color(0xFFD97706),
                                  size: 22.0,
                                ),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    currentMember
                                        .localizedHintDescription(langCode),
                                    style: const TextStyle(
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // Question Prompt
                  Text(
                    currentMember.localizedQuestionPrompt(langCode),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // Relationship Option Buttons
                  ...currentMember.alternativeRelationshipOptions.map((option) {
                    final isSelected = state.selectedRelationship == option;
                    final isEliminated = state.eliminatedDistractors.contains(
                      option,
                    );
                    final localizedOption = FamilyMemberItem.localizeRelationship(option, langCode);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Semantics(
                        button: true,
                        selected: isSelected,
                        label: '$localizedOption ${isEliminated ? 'Eliminated' : ''}',
                        child: InkWell(
                          onTap: isEliminated
                              ? null
                              : () {
                                  setState(() {
                                    _controller.selectRelationship(option);
                                  });
                                },
                          borderRadius: BorderRadius.circular(16.0),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 64.0),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                              vertical: 16.0,
                            ),
                            decoration: BoxDecoration(
                              color: isEliminated
                                  ? const Color(0xFFF1F5F9)
                                  : (isSelected
                                        ? const Color(0xFFF0FDF4)
                                        : Colors.white),
                              borderRadius: BorderRadius.circular(16.0),
                              border: Border.all(
                                color: isEliminated
                                    ? const Color(0xFFE2E8F0)
                                    : (isSelected
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFFCBD5E1)),
                                width: isSelected ? 3.0 : 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.check_circle_rounded
                                      : (isEliminated
                                            ? Icons.block_rounded
                                            : Icons
                                                  .radio_button_unchecked_rounded),
                                  color: isEliminated
                                      ? const Color(0xFF94A3B8)
                                      : (isSelected
                                            ? const Color(0xFF16A34A)
                                            : const Color(0xFF64748B)),
                                  size: 26.0,
                                ),
                                const SizedBox(width: 14.0),
                                Expanded(
                                  child: Text(
                                    localizedOption,
                                    style: TextStyle(
                                      fontSize: 19.0,
                                      fontWeight: FontWeight.w700,
                                      color: isEliminated
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF0F172A),
                                      decoration: isEliminated
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20.0),

                  // Navigation / Next Card Button
                  ElderGameButton(
                    label: state.isLastQuestion
                        ? (l10n?.completeActivityButton ?? 'Complete Activity ➔')
                        : (l10n?.continueButton ?? 'Next Person ➔'),
                    icon: state.isLastQuestion
                        ? Icons.check_rounded
                        : Icons.arrow_forward_rounded,
                    onPressed: state.selectedRelationship != null
                        ? () async {
                            if (state.isLastQuestion) {
                              final session = _controller.completeGame();
                              await GameCompletionDialog.show(
                                context,
                                session: session,
                                level: widget.level,
                                onNextLevel: widget.level != null && widget.level!.levelNumber < 8
                                    ? () => _loadNextLevel(widget.level!.levelNumber + 1)
                                    : null,
                                onFinish: () {
                                  if (mounted) {
                                    _handleCompletion(session);
                                  }
                                },
                              );
                            } else {
                              setState(() {
                                _controller.nextQuestion();
                              });
                              _speakCurrentQuestion();
                            }
                          }
                        : null,
                  ),
                  const SizedBox(height: 20.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
