import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/providers/accessibility_providers.dart';
import '../../../../core/network/audio_service.dart';
import '../../../../core/widgets/voice_helper.dart';
import '../../controllers/grocery_memory_controller.dart';
import '../../models/game_enums.dart';
import '../../models/game_session.dart';
import '../widgets/elder_game_button.dart';
import '../widgets/elder_game_card.dart';
import '../widgets/game_completion_dialog.dart';
import '../widgets/game_header.dart';

class GroceryMemoryScreen extends ConsumerStatefulWidget {
  final GameDifficulty difficulty;
  final ValueChanged<GameSession>? onGameCompleted;
  final VoidCallback? onExit;

  const GroceryMemoryScreen({
    super.key,
    this.difficulty = GameDifficulty.easy,
    this.onGameCompleted,
    this.onExit,
  });

  @override
  ConsumerState<GroceryMemoryScreen> createState() =>
      _GroceryMemoryScreenState();
}

class _GroceryMemoryScreenState extends ConsumerState<GroceryMemoryScreen> {
  late final GroceryMemoryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GroceryMemoryController(initialDifficulty: widget.difficulty);
    _speakShoppingList();
  }

  void _speakShoppingList() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final voiceEnabled = ref.read(voiceEnabledProvider);
      if (voiceEnabled) {
        final items = _controller.state.shoppingList.map((e) => e.name).join(', ');
        final locale = ref.read(localeProvider);
        ref.read(audioServiceProvider).speak(
              'Here is your shopping list: $items. Review what to get.',
              languageCode: locale.languageCode,
            );
      }
    });
  }

  void _speakShelfPrompt() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final voiceEnabled = ref.read(voiceEnabledProvider);
      if (voiceEnabled) {
        final locale = ref.read(localeProvider);
        ref.read(audioServiceProvider).speak(
              'Tap items from your list to put them in your cart.',
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
    GameCompletionDialog.show(
      context,
      session: session,
      onFinish: () {
        Navigator.of(context).pop();
        if (widget.onGameCompleted != null) {
          widget.onGameCompleted!(session);
        }
        Navigator.of(context).maybePop(session);
      },
    );
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
            title: GameType.groceryMemory.displayName,
            difficulty: state.difficulty,
            onExit: _handleExit,
            onHint: !state.isListPhase
                ? () {
                    setState(() {
                      _controller.useHint();
                    });
                    final hint = _controller.state.lastFeedback;
                    if (hint != null && ref.read(voiceEnabledProvider)) {
                      final locale = ref.read(localeProvider);
                      ref.read(audioServiceProvider).speak(
                            hint,
                            languageCode: locale.languageCode,
                          );
                    }
                  }
                : null,
            isHintAvailable: !state.isListPhase,
          ),

          // Main Interactive Area
          Expanded(
            child: state.isListPhase
                ? _buildShoppingListView(state)
                : _buildShelfView(state),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Phase 1: Shopping List View
  // ---------------------------------------------------------------------------
  Widget _buildShoppingListView(GroceryMemoryState state) {
    final itemsText = state.shoppingList.map((e) => e.name).join(', ');
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Gentle Instruction Banner with SpeakButton
          Container(
            padding: const EdgeInsets.all(18.0),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB), // Warm amber
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shopping_basket_rounded,
                  color: Color(0xFFD97706),
                  size: 32.0,
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: Text(
                    'Here is your shopping list with ${state.shoppingList.length} items.\nReview what to get:',
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
                SpeakButton(
                  text: 'Here is your shopping list: $itemsText.',
                  size: 36.0,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24.0),

          // Grocery Items List Cards
          ...state.shoppingList.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18.0,
                  vertical: 14.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: const Color(0xFFCBD5E1),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54.0,
                      height: 54.0,
                      decoration: BoxDecoration(
                        color: item.tintColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(4.0),
                      child: Image.asset(
                        item.imagePath,
                        width: 46.0,
                        height: 46.0,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Text(
                            item.emoji,
                            style: const TextStyle(fontSize: 28.0),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.check_box_outline_blank_rounded,
                      color: Color(0xFF94A3B8),
                      size: 28.0,
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 28.0),

          // Let's Go to the Market Button
          ElderGameButton(
            label: 'Go to Market ➔',
            icon: Icons.storefront_rounded,
            onPressed: () {
              setState(() {
                _controller.proceedToShelf();
              });
              _speakShelfPrompt();
            },
          ),
          const SizedBox(height: 20.0),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Phase 2: Market Shelf View
  // ---------------------------------------------------------------------------
  Widget _buildShelfView(GroceryMemoryState state) {
    final collectedCount = state.basketItemIds.length;
    final totalListCount = state.shoppingList.length;
    final feedbackText = state.lastFeedback ??
        'Tap items from your list to put them in your cart:';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Feedback bar with SpeakButton
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

        // Supermarket Shelf Grid
        Expanded(
          child: state.shelfItems.isEmpty
              ? const Center(
                  child: Text(
                    'Getting ready…',
                    style: TextStyle(fontSize: 20.0, color: Color(0xFF64748B)),
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
                  itemCount: state.shelfItems.length,
                  itemBuilder: (context, index) {
                    final item = state.shelfItems[index];
                    final isInBasket = state.basketItemIds.contains(item.id);
                    final isHint = state.hintHighlightedItemId == item.id;

                    return ElderGameCard(
                      title: item.name,
                      imagePath: item.imagePath,
                      emoji: item.emoji,
                      fallbackIcon: item.fallbackIcon,
                      iconColor: item.tintColor,
                      isSelected: isInBasket,
                      isHighlightedAsHint: isHint,
                      onTap: () {
                        setState(() {
                          _controller.toggleBasketItem(item.id);
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
                // Basket Counter
                Expanded(
                  child: Text(
                    'In Cart: $collectedCount of $totalListCount',
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                // Finish / Checkout Button
                ElderGameButton(
                  label: 'Complete Shopping ➔',
                  icon: Icons.check_circle_rounded,
                  onPressed: collectedCount > 0
                      ? () {
                          final session = _controller.completeGame();
                          _handleCompletion(session);
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
