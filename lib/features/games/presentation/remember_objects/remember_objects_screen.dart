// ==============================================================================
// NIRVANA - Remember Objects Screen
// Description: Offline cognitive engagement game: Visual object recognition & recall
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/providers/accessibility_providers.dart';
import '../../../../core/intelligence/difficulty_recommender.dart';
import '../../../../core/network/audio_service.dart';
import '../../../../core/widgets/voice_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../caregiver/providers/caregiver_providers.dart';
import '../../controllers/remember_objects_controller.dart';
import '../../models/game_enums.dart';
import '../../models/game_level.dart';
import '../../models/game_session.dart';
import '../widgets/elder_game_button.dart';
import '../widgets/elder_game_card.dart';
import '../widgets/game_completion_dialog.dart';
import '../widgets/game_header.dart';

class RememberObjectsScreen extends ConsumerStatefulWidget {
  final GameDifficulty difficulty;
  final ValueChanged<GameSession>? onGameCompleted;
  final VoidCallback? onExit;
  final GameLevel? level;

  const RememberObjectsScreen({
    super.key,
    this.difficulty = GameDifficulty.easy,
    this.onGameCompleted,
    this.onExit,
    this.level,
  });

  @override
  ConsumerState<RememberObjectsScreen> createState() => _RememberObjectsScreenState();
}

class _RememberObjectsScreenState extends ConsumerState<RememberObjectsScreen> {
  late final RememberObjectsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = RememberObjectsController(
      initialDifficulty: widget.level?.difficulty ?? widget.difficulty,
    );
    _speakMemorizationItems();
  }

  void _speakMemorizationItems() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final voiceEnabled = ref.read(voiceEnabledProvider);
      if (voiceEnabled) {
        final locale = ref.read(localeProvider);
        final l10n = AppLocalizations.of(context);
        final items = _controller.state.targetItems
            .map((e) => e.localizedName(locale.languageCode))
            .join(', ');
        final prompt = l10n?.rememberObjectsLookCarefully ??
            'Look at these items carefully. Take all the time you need.';
        ref.read(audioServiceProvider).speak(
              '$prompt $items',
              languageCode: locale.languageCode,
            );
      }
    });
  }

  void _speakRecallPrompt() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final voiceEnabled = ref.read(voiceEnabledProvider);
      if (voiceEnabled) {
        final locale = ref.read(localeProvider);
        final l10n = AppLocalizations.of(context);
        final prompt = l10n?.whichItemsDidYouSee ??
            'Which items did you see? Tap them below.';
        ref.read(audioServiceProvider).speak(
              prompt,
              languageCode: locale.languageCode,
            );
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
    final allLevels = GameLevel.getLevelsForGame(GameType.rememberObjects);
    final next = allLevels.firstWhere(
      (l) => l.levelNumber == nextLevelNumber,
      orElse: () => allLevels.last,
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RememberObjectsScreen(
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Header Bar
          GameHeader(
            title: widget.level != null
                ? 'Level ${widget.level!.levelNumber}: ${widget.level!.localizedTitle(langCode)}'
                : GameType.rememberObjects.localizedTitle(l10n),
            difficulty: state.difficulty,
            onExit: _handleExit,
            onHint: !state.isMemorizationPhase
                ? () {
                    setState(() {
                      _controller.useHint();
                    });
                    if (ref.read(voiceEnabledProvider)) {
                      final locale = ref.read(localeProvider);
                      final hintTargetId =
                          _controller.state.hintHighlightedItemId;
                      final hintItem = hintTargetId != null
                          ? _controller.state.targetItems
                              .where((e) => e.id == hintTargetId)
                              .firstOrNull
                          : null;
                      final String hintText;
                      if (hintItem != null) {
                        final name =
                            hintItem.localizedName(locale.languageCode);
                        switch (locale.languageCode) {
                          case 'hi':
                            hintText = 'संकेत: $name को देखें!';
                            break;
                          case 'bn':
                            hintText = 'ইঙ্গিত: $name দেখুন!';
                            break;
                          case 'as':
                            hintText = 'ইংগিত: $name চাওক!';
                            break;
                          case 'ne':
                            hintText = 'संकेत: $name हेर्नुहोस्!';
                            break;
                          default:
                            hintText = 'Hint: Take a look at the $name!';
                        }
                      } else {
                        switch (locale.languageCode) {
                          case 'hi':
                            hintText = 'आपने सभी वस्तुएं खोज ली हैं!';
                            break;
                          case 'bn':
                            hintText = 'আপনি সমস্ত বস্তু খুঁজে পেয়েছেন!';
                            break;
                          case 'as':
                            hintText = 'আপুনি সকলো বস্তু বিচাৰি পাইছে!';
                            break;
                          case 'ne':
                            hintText = 'तपाईंले सबै वस्तुहरू फेला पार्नुभएको छ!';
                            break;
                          default:
                            hintText = 'You have found all the items!';
                        }
                      }
                      ref.read(audioServiceProvider).speak(
                            hintText,
                            languageCode: locale.languageCode,
                          );
                    }
                  }
                : null,
            isHintAvailable: !state.isMemorizationPhase,
          ),

          // Main Interactive Area
          Expanded(
            child: state.isMemorizationPhase
                ? _buildMemorizationView(state, l10n, langCode)
                : _buildRecallView(state, l10n, langCode),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Phase 1: Memorization View
  // ---------------------------------------------------------------------------
  Widget _buildMemorizationView(
    RememberObjectsState state,
    AppLocalizations? l10n,
    String langCode,
  ) {
    final itemsText = state.targetItems
        .map((e) => e.localizedName(langCode))
        .join(', ');
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Gentle Instruction Banner with SpeakButton
          Container(
            padding: const EdgeInsets.all(18.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4), // Warm mint
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.remove_red_eye_rounded,
                  color: Color(0xFF16A34A),
                  size: 32.0,
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: Text(
                    l10n?.rememberObjectsLookCarefully ??
                        'Look at these ${state.targetItems.length} items carefully.\nTake all the time you need.',
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF14532D),
                    ),
                  ),
                ),
                SpeakButton(
                  text:
                      '${l10n?.rememberObjectsLookCarefully ?? 'Look at these items carefully: '} $itemsText',
                  size: 36.0,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24.0),

          // Target Items Display Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.95,
            ),
            itemCount: state.targetItems.length,
            itemBuilder: (context, index) {
              final item = state.targetItems[index];
              return ElderGameCard(
                title: item.localizedName(langCode),
                imagePath: item.imagePath,
                emoji: item.emoji,
                fallbackIcon: item.fallbackIcon,
                iconColor: item.tintColor,
                isSelected: false,
              );
            },
          ),
          const SizedBox(height: 32.0),

          // "I am Ready" Button
          ElderGameButton(
            label: l10n?.iAmReadyButton ?? 'I am Ready ➔',
            icon: Icons.check_circle_outline_rounded,
            onPressed: () {
              setState(() {
                _controller.proceedToRecall();
              });
              _speakRecallPrompt();
            },
          ),
          const SizedBox(height: 20.0),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Phase 2: Recall View
  // ---------------------------------------------------------------------------
  Widget _buildRecallView(
    RememberObjectsState state,
    AppLocalizations? l10n,
    String langCode,
  ) {
    final selectedCount = state.selectedItemIds.length;
    final totalTargetCount = state.targetItems.length;

    final String feedbackText;
    if (state.hintHighlightedItemId != null) {
      final hintItem = state.targetItems
          .where((e) => e.id == state.hintHighlightedItemId)
          .firstOrNull;
      if (hintItem != null) {
        final name = hintItem.localizedName(langCode);
        switch (langCode) {
          case 'hi':
            feedbackText = 'संकेत: $name को देखें!';
            break;
          case 'bn':
            feedbackText = 'ইঙ্গিত: $name দেখুন!';
            break;
          case 'as':
            feedbackText = 'ইংগিত: $name চাওক!';
            break;
          case 'ne':
            feedbackText = 'संकेत: $name हेर्नुहोस्!';
            break;
          default:
            feedbackText = 'Hint: Take a look at the $name!';
        }
      } else {
        feedbackText = l10n?.whichItemsDidYouSee ??
            'Which items did you see? Tap them below:';
      }
    } else {
      feedbackText = l10n?.whichItemsDidYouSee ??
          'Which items did you see? Tap them below:';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Supportive Feedback Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          color: const Color(0xFFF1F5F9),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  feedbackText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17.0,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              SpeakButton(
                text: feedbackText,
                size: 34.0,
              ),
            ],
          ),
        ),

        // Selection Grid
        Expanded(
          child: state.selectionOptions.isEmpty
              ? Center(
                  child: Text(
                    l10n?.loadingMessage ?? 'Getting ready…',
                    style: const TextStyle(fontSize: 20.0, color: Color(0xFF64748B)),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 16.0,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: state.selectionOptions.length,
                  itemBuilder: (context, index) {
                    final item = state.selectionOptions[index];
                    final isSelected = state.selectedItemIds.contains(item.id);
                    final isHint = state.hintHighlightedItemId == item.id;

                    return ElderGameCard(
                      title: item.localizedName(langCode),
                      imagePath: item.imagePath,
                      emoji: item.emoji,
                      fallbackIcon: item.fallbackIcon,
                      iconColor: item.tintColor,
                      isSelected: isSelected,
                      isHighlightedAsHint: isHint,
                      onTap: () {
                        setState(() {
                          _controller.toggleItemSelection(item.id);
                        });
                      },
                    );
                  },
                ),
        ),

        // Bottom Action Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // Selected Counter
                Expanded(
                  child: Text(
                    langCode == 'hi'
                        ? 'चुने गए: $selectedCount / $totalTargetCount'
                        : langCode == 'bn'
                            ? 'নির্বাচিত: $selectedCount / $totalTargetCount'
                            : langCode == 'as'
                                ? 'নিৰ্বাচিত: $selectedCount / $totalTargetCount'
                                : langCode == 'ne'
                                    ? 'छानिएका: $selectedCount / $totalTargetCount'
                                    : 'Chosen: $selectedCount of $totalTargetCount',
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                ElderGameButton(
                  label: l10n?.completeActivityButton ?? 'Complete Activity ➔',
                  icon: Icons.done_all_rounded,
                  onPressed: selectedCount > 0
                      ? () async {
                          final session = _controller.completeGame();
                          final patientId = ref.read(selectedPatientProvider)?.id ?? kDefaultPatientId;
                          // Record this session for Smart Difficulty — fire-and-forget.
                          ref
                              .read(difficultyRecommenderProvider)
                              .recordSession(patientId, session)
                              .ignore();
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
                        }
                      : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
