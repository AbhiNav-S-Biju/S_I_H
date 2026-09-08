// ==============================================================================
// NIRVANA - Remember Objects Screen
// Description: Offline cognitive engagement game: Visual object recognition & recall
// ==============================================================================

import 'package:flutter/material.dart';
import '../../controllers/remember_objects_controller.dart';
import '../../models/game_enums.dart';
import '../../models/game_session.dart';
import '../widgets/elder_game_button.dart';
import '../widgets/elder_game_card.dart';
import '../widgets/game_completion_dialog.dart';
import '../widgets/game_header.dart';

class RememberObjectsScreen extends StatefulWidget {
  final GameDifficulty difficulty;
  final ValueChanged<GameSession>? onGameCompleted;
  final VoidCallback? onExit;

  const RememberObjectsScreen({
    super.key,
    this.difficulty = GameDifficulty.easy,
    this.onGameCompleted,
    this.onExit,
  });

  @override
  State<RememberObjectsScreen> createState() => _RememberObjectsScreenState();
}

class _RememberObjectsScreenState extends State<RememberObjectsScreen> {
  late final RememberObjectsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = RememberObjectsController(
      initialDifficulty: widget.difficulty,
    );
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

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Header Bar
          GameHeader(
            title: GameType.rememberObjects.displayName,
            difficulty: state.difficulty,
            onExit: _handleExit,
            onHint: !state.isMemorizationPhase
                ? () {
                    setState(() {
                      _controller.useHint();
                    });
                  }
                : null,
            isHintAvailable: !state.isMemorizationPhase,
          ),

          // Main Interactive Area
          Expanded(
            child: state.isMemorizationPhase
                ? _buildMemorizationView(state)
                : _buildRecallView(state),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Phase 1: Memorization View
  // ---------------------------------------------------------------------------
  Widget _buildMemorizationView(RememberObjectsState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Gentle Instruction Banner
          Container(
            padding: const EdgeInsets.all(18.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4), // Gentle mint
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.visibility_rounded,
                  color: Color(0xFF16A34A),
                  size: 32.0,
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: Text(
                    'Look at these ${state.targetItems.length} items carefully.\nTake all the time you need.',
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF14532D),
                    ),
                  ),
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
                title: item.name,
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
            label: 'I am Ready ➔',
            icon: Icons.check_circle_outline_rounded,
            onPressed: () {
              setState(() {
                _controller.proceedToRecall();
              });
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
  Widget _buildRecallView(RememberObjectsState state) {
    final selectedCount = state.selectedItemIds.length;
    final totalTargetCount = state.targetItems.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Supportive Feedback Banner
          Container(
            padding: const EdgeInsets.all(18.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.psychology_rounded,
                  color: Color(0xFF16A34A),
                  size: 32.0,
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: Text(
                    state.lastFeedback ??
                        'Which items did you see? Tap them below:',
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF14532D),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          // Selection Count Card
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18.0,
              vertical: 14.0,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Items Chosen:',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 6.0,
                  ),
                  decoration: BoxDecoration(
                    color: selectedCount >= totalTargetCount
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Text(
                    '$selectedCount of $totalTargetCount chosen',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w800,
                      color: selectedCount >= totalTargetCount
                          ? const Color(0xFF166534)
                          : const Color(0xFF0369A1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),

          // Selection Grid
          if (state.selectionOptions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'Getting ready…',
                  style: TextStyle(fontSize: 20.0, color: Color(0xFF64748B)),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
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
                  title: item.name,
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
          const SizedBox(height: 28.0),

          // Finish Button
          ElderGameButton(
            label: 'Complete Activity ➔',
            icon: Icons.done_all_rounded,
            onPressed: selectedCount > 0
                ? () {
                    final session = _controller.completeGame();
                    GameCompletionDialog.show(
                      context,
                      session: session,
                      onFinish: () {
                        Navigator.of(context).pop();
                        _handleCompletion(session);
                      },
                    );
                  }
                : null,
          ),
          const SizedBox(height: 24.0),
        ],
      ),
    );
  }
}
