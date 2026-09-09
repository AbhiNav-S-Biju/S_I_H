import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/providers/accessibility_providers.dart';
import '../../../../core/network/audio_service.dart';
import '../../../../core/widgets/voice_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../controllers/grocery_memory_controller.dart';
import '../../models/game_enums.dart';
import '../../models/game_level.dart';
import '../../models/game_session.dart';
import '../widgets/elder_game_button.dart';
import '../widgets/elder_game_card.dart';
import '../widgets/game_completion_dialog.dart';
import '../widgets/game_header.dart';

class GroceryMemoryScreen extends ConsumerStatefulWidget {
  final GameDifficulty difficulty;
  final ValueChanged<GameSession>? onGameCompleted;
  final VoidCallback? onExit;
  final GameLevel? level;

  const GroceryMemoryScreen({
    super.key,
    this.difficulty = GameDifficulty.easy,
    this.onGameCompleted,
    this.onExit,
    this.level,
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
    _controller = GroceryMemoryController(
      initialDifficulty: widget.level?.difficulty ?? widget.difficulty,
    );
    _speakShoppingList();
  }

  void _speakShoppingList() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final voiceEnabled = ref.read(voiceEnabledProvider);
      if (voiceEnabled) {
        final locale = ref.read(localeProvider);
        final l10n = AppLocalizations.of(context);
        final items = _controller.state.shoppingList
            .map((e) => e.localizedName(locale.languageCode))
            .join(', ');
        final prompt = l10n?.shoppingListSubtitle ??
            'Review these items, then tap Start Shopping when ready.';
        ref.read(audioServiceProvider).speak(
              '$prompt $items',
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
        final l10n = AppLocalizations.of(context);
        final prompt = l10n?.findItemsOnShelf ??
            'Tap items from your list to put them in your cart.';
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

  void _handleCompletion(GameSession session) async {
    await GameCompletionDialog.show(
      context,
      session: session,
      level: widget.level,
      onNextLevel: widget.level != null && widget.level!.levelNumber < 8
          ? () => _loadNextLevel(widget.level!.levelNumber + 1)
          : null,
      onFinish: () {
        if (!mounted) return;
        if (widget.onGameCompleted != null) {
          widget.onGameCompleted!(session);
        }
        Navigator.of(context).maybePop(session);
      },
    );
  }

  void _loadNextLevel(int nextLevelNumber) {
    final allLevels = GameLevel.getLevelsForGame(GameType.groceryMemory);
    final next = allLevels.firstWhere(
      (l) => l.levelNumber == nextLevelNumber,
      orElse: () => allLevels.last,
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GroceryMemoryScreen(
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
                : GameType.groceryMemory.localizedTitle(l10n),
            difficulty: state.difficulty,
            onExit: _handleExit,
            onHint: !state.isListPhase
                ? () {
                    setState(() {
                      _controller.useHint();
                    });
                    if (ref.read(voiceEnabledProvider)) {
                      final locale = ref.read(localeProvider);
                      final hintTargetId =
                          _controller.state.hintHighlightedItemId;
                      final hintItem = hintTargetId != null
                          ? _controller.state.shoppingList
                              .where((e) => e.id == hintTargetId)
                              .firstOrNull
                          : null;
                      final String hintText;
                      if (hintItem != null) {
                        final name =
                            hintItem.localizedName(locale.languageCode);
                        switch (locale.languageCode) {
                          case 'hi':
                            hintText = 'संकेत: शेल्फ़ पर $name खोजें!';
                            break;
                          case 'bn':
                            hintText = 'ইঙ্গিত: তাক থেকে $name খুঁজুন!';
                            break;
                          case 'as':
                            hintText = 'ইংগিত: শ্বেলফত $name বিচাৰক!';
                            break;
                          case 'ne':
                            hintText = 'संकेत: दराजमा $name खोज्नुहोस्!';
                            break;
                          default:
                            hintText = 'Hint: Look for the $name on the shelf!';
                        }
                      } else {
                        switch (locale.languageCode) {
                          case 'hi':
                            hintText = 'आपकी टोकरी में सभी वस्तुएं हैं!';
                            break;
                          case 'bn':
                            hintText = 'আপনার ঝুড়িতে সমস্ত বস্তু রয়েছে!';
                            break;
                          case 'as':
                            hintText = 'আপোনাৰ ডলাত সকলো বস্তু আছে!';
                            break;
                          case 'ne':
                            hintText = 'तपाईंको टोकरीमा सबै वस्तुहरू छन्!';
                            break;
                          default:
                            hintText =
                                'Your basket contains all items from the list!';
                        }
                      }
                      ref.read(audioServiceProvider).speak(
                            hintText,
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
                ? _buildShoppingListView(state, l10n, langCode)
                : _buildShelfView(state, l10n, langCode),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Phase 1: Shopping List View
  // ---------------------------------------------------------------------------
  Widget _buildShoppingListView(
    GroceryMemoryState state,
    AppLocalizations? l10n,
    String langCode,
  ) {
    final itemsText = state.shoppingList
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
                    l10n?.shoppingListSubtitle ??
                        'Here is your shopping list with ${state.shoppingList.length} items.\nReview what to get:',
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
                SpeakButton(
                  text:
                      '${l10n?.shoppingListSubtitle ?? 'Here is your shopping list: '} $itemsText',
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
                        item.localizedName(langCode),
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
            label: l10n?.startShoppingButton ?? 'Go to Market ➔',
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
  Widget _buildShelfView(
    GroceryMemoryState state,
    AppLocalizations? l10n,
    String langCode,
  ) {
    final collectedCount = state.basketItemIds.length;
    final totalListCount = state.shoppingList.length;

    final String feedbackText;
    if (state.hintHighlightedItemId != null) {
      final hintItem = state.shoppingList
          .where((e) => e.id == state.hintHighlightedItemId)
          .firstOrNull;
      if (hintItem != null) {
        final name = hintItem.localizedName(langCode);
        switch (langCode) {
          case 'hi':
            feedbackText = 'संकेत: शेल्फ़ पर $name खोजें!';
            break;
          case 'bn':
            feedbackText = 'ইঙ্গিত: তাক থেকে $name খুঁজুন!';
            break;
          case 'as':
            feedbackText = 'ইংগিত: শ্বেলফত $name বিচাৰক!';
            break;
          case 'ne':
            feedbackText = 'संकेत: दराजमा $name खोज्नुहोस्!';
            break;
          default:
            feedbackText = 'Hint: Look for the $name on the shelf!';
        }
      } else {
        feedbackText = l10n?.findItemsOnShelf ??
            'Tap items from your list to put them in your cart:';
      }
    } else {
      feedbackText = l10n?.findItemsOnShelf ??
          'Tap items from your list to put them in your cart:';
    }

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
                  itemCount: state.shelfItems.length,
                  itemBuilder: (context, index) {
                    final item = state.shelfItems[index];
                    final isInBasket = state.basketItemIds.contains(item.id);
                    final isHint = state.hintHighlightedItemId == item.id;

                    return ElderGameCard(
                      title: item.localizedName(langCode),
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
                    langCode == 'hi'
                        ? 'टोकरी में: $collectedCount / $totalListCount'
                        : langCode == 'bn'
                            ? 'ঝুড়িতে: $collectedCount / $totalListCount'
                            : langCode == 'as'
                                ? 'ডলাত: $collectedCount / $totalListCount'
                                : langCode == 'ne'
                                    ? 'टोकरीमा: $collectedCount / $totalListCount'
                                    : 'In Cart: $collectedCount of $totalListCount',
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
                  label: l10n?.completeActivityButton ?? 'Complete Shopping ➔',
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
