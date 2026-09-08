// ==============================================================================
// NIRVANA - Grocery Memory Screen
// Description: Offline cognitive engagement game: Everyday shopping list recall
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleCompletion(GameSession session) async {
    await GameCompletionDialog.show(
      context,
      session: session,
    );
    if (!mounted) return;
    if (widget.onGameCompleted != null) {
      widget.onGameCompleted!(session);
    }
    if (widget.onExit != null) {
      widget.onExit!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(session);
    }
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Feedback / Instruction banner
          Container(
            padding: const EdgeInsets.all(18.0),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shopping_cart_rounded,
                  color: Color(0xFFD97706),
                  size: 32.0,
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: Text(
                    state.lastFeedback ??
                        'Tap items from your list to put them in your cart:',
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
          const SizedBox(height: 16.0),

          // Cart Status Card
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
                  'In Your Cart:',
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
                    color: collectedCount >= totalListCount
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Text(
                    '$collectedCount of $totalListCount items',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w800,
                      color: collectedCount >= totalListCount
                          ? const Color(0xFF166534)
                          : const Color(0xFF0369A1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),

          // Supermarket Shelf Grid
          if (state.shelfItems.isEmpty)
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
          const SizedBox(height: 28.0),

          // Done / Checkout Button
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
          const SizedBox(height: 24.0),
        ],
      ),
    );
  }
}
