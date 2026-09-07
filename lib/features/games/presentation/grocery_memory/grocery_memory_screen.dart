// ==============================================================================
// NIRVANA - Grocery Memory Screen
// Description: Offline cognitive engagement game: Everyday shopping list recall
// ==============================================================================

import 'package:flutter/material.dart';
import '../../controllers/grocery_memory_controller.dart';
import '../../models/game_enums.dart';
import '../../models/game_session.dart';
import '../widgets/elder_game_button.dart';
import '../widgets/elder_game_card.dart';
import '../widgets/game_completion_dialog.dart';
import '../widgets/game_header.dart';

class GroceryMemoryScreen extends StatefulWidget {
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
  State<GroceryMemoryScreen> createState() => _GroceryMemoryScreenState();
}

class _GroceryMemoryScreenState extends State<GroceryMemoryScreen> {
  late final GroceryMemoryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GroceryMemoryController(initialDifficulty: widget.difficulty);
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
            title: GameType.groceryMemory.displayName,
            difficulty: state.difficulty,
            onExit: _handleExit,
            onHint: !state.isListPhase
                ? () {
                    setState(() {
                      _controller.useHint();
                    });
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Gentle Instruction Banner
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
                      width: 50.0,
                      height: 50.0,
                      decoration: BoxDecoration(
                        color: item.tintColor.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        item.emoji,
                        style: const TextStyle(fontSize: 28.0),
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

    // IndexedStack always gives this widget tight constraints (finite width
    // and finite height). The Column + Expanded(GridView) pattern works
    // correctly when the parent provides tight bounds.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Feedback bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
          color: const Color(0xFFF1F5F9),
          child: Text(
            state.lastFeedback ??
                'Tap items from your list to put them in your cart:',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17.0,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
        ),

        // Supermarket Shelf Grid — receives finite height from Column+Expanded
        // because IndexedStack provides tight constraints to this whole widget.
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
                    childAspectRatio: 1.05,
                  ),
                  itemCount: state.shelfItems.length,
                  itemBuilder: (context, index) {
                    final item = state.shelfItems[index];
                    final isInBasket = state.basketItemIds.contains(item.id);
                    final isHint = state.hintHighlightedItemId == item.id;

                    return ElderGameCard(
                      title: item.name,
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
                // In Cart Counter
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shopping_cart_rounded,
                        color: Color(0xFF0F766E),
                        size: 28.0,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        'Cart: $collectedCount / $totalListCount',
                        style: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12.0),
                // Finish / Checkout Button — not wrapped in Expanded so it uses
                // its own intrinsic width (minWidth: 140 from ConstrainedBox)
                ElderGameButton(
                  label: 'Done',
                  icon: Icons.check_circle_rounded,
                  onPressed: collectedCount > 0
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}
