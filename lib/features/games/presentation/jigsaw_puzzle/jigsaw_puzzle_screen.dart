// ==============================================================================
// NIRVANA - Jigsaw Puzzle Screen
// Description: Dementia-friendly cognitive engagement jigsaw activity
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/providers/accessibility_providers.dart';
import '../../../../core/network/audio_service.dart';
import '../../../../core/widgets/voice_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../controllers/jigsaw_puzzle_controller.dart';
import '../../models/game_enums.dart';
import '../../models/game_session.dart';
import '../../models/puzzle_item.dart';
import '../widgets/elder_game_button.dart';
import '../widgets/game_completion_dialog.dart';
import '../widgets/game_header.dart';
import 'widgets/image_selector_sheet.dart';
import 'widgets/puzzle_board.dart';
import 'widgets/puzzle_piece_tile.dart';

class JigsawPuzzleScreen extends ConsumerStatefulWidget {
  final GameDifficulty difficulty;
  final PuzzleImage? initialImage;
  final ValueChanged<GameSession>? onGameCompleted;
  final VoidCallback? onExit;

  const JigsawPuzzleScreen({
    super.key,
    this.difficulty = GameDifficulty.easy,
    this.initialImage,
    this.onGameCompleted,
    this.onExit,
  });

  @override
  ConsumerState<JigsawPuzzleScreen> createState() => _JigsawPuzzleScreenState();
}

class _JigsawPuzzleScreenState extends ConsumerState<JigsawPuzzleScreen> {
  late final JigsawPuzzleController _controller;

  @override
  void initState() {
    super.initState();
    _controller = JigsawPuzzleController(
      initialDifficulty: widget.difficulty,
      initialImage: widget.initialImage,
    );
    _speakInitialPrompt();
  }

  void _speakInitialPrompt() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final voiceEnabled = ref.read(voiceEnabledProvider);
      if (voiceEnabled) {
        final locale = ref.read(localeProvider);
        final prompt = _controller.state.voicePrompt;
        if (prompt != null && prompt.isNotEmpty) {
          ref.read(audioServiceProvider).speak(
                prompt,
                languageCode: locale.languageCode,
              );
        }
      }
    });
  }

  void _speakText(String text) {
    final voiceEnabled = ref.read(voiceEnabledProvider);
    if (voiceEnabled) {
      final locale = ref.read(localeProvider);
      ref.read(audioServiceProvider).speak(
            text,
            languageCode: locale.languageCode,
          );
    }
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

  void _handleHint() {
    final locale = ref.read(localeProvider);
    final hint = _controller.useHint(langCode: locale.languageCode);
    setState(() {});
    _speakText(hint);
  }

  void _handleSlotDrop(int pieceId, int row, int col) async {
    final locale = ref.read(localeProvider);
    final success = _controller.placePieceInSlot(
      pieceId,
      row,
      col,
      langCode: locale.languageCode,
    );
    setState(() {});

    final feedback = _controller.state.lastFeedback;
    if (feedback != null) {
      _speakText(feedback);
    }

    if (success && _controller.state.isCompleted) {
      final session = _controller.completeGame();
      await GameCompletionDialog.show(context, session: session);
      if (mounted) {
        _handleCompletion(session);
      }
    }
  }

  void _handleSlotTap(int row, int col) async {
    final selectedId = _controller.state.selectedPieceId;
    if (selectedId != null) {
      _handleSlotDrop(selectedId, row, col);
    }
  }

  void _openPictureSelector() async {
    final locale = ref.read(localeProvider);
    final selected = await ImageSelectorSheet.show(
      context,
      activeImage: _controller.state.activeImage,
      langCode: locale.languageCode,
    );

    if (selected != null && mounted) {
      setState(() {
        _controller.changeImage(selected);
      });
      _speakInitialPrompt();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context);
    final state = _controller.state;
    final locale = ref.watch(localeProvider);
    final langCode = locale.languageCode;

    final screenWidth = MediaQuery.of(context).size.width;
    // Responsive board width with max limit
    final boardWidth = (screenWidth - 40.0).clamp(280.0, 420.0);
    final boardHeight = boardWidth * 0.75; // 4:3 aspect ratio

    final promptText = state.voicePrompt ??
        (langCode == 'hi'
            ? 'तस्वीर को पूरा करने के लिए टुकड़ों को सही जगह रखें'
            : 'Match the pieces to complete this familiar picture');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 1. Header Bar
          GameHeader(
            title: GameType.jigsawPuzzle.localizedTitle(l10n),
            difficulty: state.difficulty,
            onExit: _handleExit,
            onHint: _handleHint,
            isHintAvailable: !_controller.state.isCompleted,
          ),

          // 2. Main Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Voice Guidance & Landmark Banner
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4), // Soothing mint
                      borderRadius: BorderRadius.circular(18.0),
                      border: Border.all(
                        color: const Color(0xFFBBF7D0),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          color: Color(0xFF16A34A),
                          size: 32.0,
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.activeImage.localizedTitle(langCode),
                                style: const TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF14532D),
                                ),
                              ),
                              const SizedBox(height: 2.0),
                              Text(
                                promptText,
                                style: const TextStyle(
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SpeakButton(text: promptText, size: 36.0),
                        const SizedBox(width: 8.0),
                        IconButton(
                          tooltip: 'Change Picture',
                          icon: const Icon(
                            Icons.photo_library_rounded,
                            color: Color(0xFF16A34A),
                            size: 26.0,
                          ),
                          onPressed: _openPictureSelector,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18.0),

                  // Adaptive Pace Suggestion Banner (if triggered)
                  if (state.adaptiveDifficultySuggestion != null)
                    _buildAdaptivePaceBanner(
                      suggestion: state.adaptiveDifficultySuggestion!,
                      langCode: langCode,
                    ),

                  // 3. Puzzle Board Area
                  Center(
                    child: PuzzleBoard(
                      state: state,
                      boardWidth: boardWidth,
                      boardHeight: boardHeight,
                      onPieceDropped: _handleSlotDrop,
                      onSlotTapped: _handleSlotTap,
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // 4. Dementia-Friendly Tray Area
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        langCode == 'hi'
                          ? 'टुकड़े (${state.trayPieces.length} बचे हैं):'
                          : 'Pieces to place (${state.trayPieces.length} remaining):',
                        style: const TextStyle(
                          fontSize: 17.0,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                      Text(
                        langCode == 'hi'
                          ? 'खींचें या टैप करें'
                          : 'Drag or Tap to place',
                        style: const TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),

                  // Tray Pieces
                  _buildTrayPieces(
                    state: state,
                    boardWidth: boardWidth,
                    boardHeight: boardHeight,
                    langCode: langCode,
                  ),
                  const SizedBox(height: 24.0),

                  // Bottom Action Row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(
                            langCode == 'hi' ? 'तस्वीर बदलें' : 'Other Picture',
                            style: const TextStyle(
                              fontSize: 15.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F766E),
                            side: const BorderSide(
                              color: Color(0xFF0F766E),
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                          ),
                          onPressed: _openPictureSelector,
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: ElderGameButton(
                          label: l10n?.hintButton ?? 'Hint',
                          icon: Icons.lightbulb_rounded,
                          onPressed: state.trayPieces.isNotEmpty
                              ? _handleHint
                              : null,
                        ),
                      ),
                    ],
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

  /// Builds the pieces in the tray with Drag & Drop and Tap-to-Place
  Widget _buildTrayPieces({
    required JigsawPuzzleState state,
    required double boardWidth,
    required double boardHeight,
    required String langCode,
  }) {
    if (state.trayPieces.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(16.0),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF16A34A),
              size: 28.0,
            ),
            const SizedBox(width: 10.0),
            Text(
              langCode == 'hi'
                  ? 'सभी टुकड़े रख दिए गए हैं!'
                  : 'All pieces placed! Wonderful!',
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w700,
                color: Color(0xFF15803D),
              ),
            ),
          ],
        ),
      );
    }

    // Size of tray tiles
    final tileWidth = (boardWidth / state.cols).clamp(90.0, 160.0);
    final tileHeight = (boardHeight / state.rows).clamp(80.0, 140.0);

    return Wrap(
      spacing: 16.0,
      runSpacing: 16.0,
      alignment: WrapAlignment.center,
      children: state.trayPieces.map((piece) {
        final isSelected = state.selectedPieceId == piece.id;

        final pieceWidget = PuzzlePieceTile(
          imagePath: state.activeImage.assetPath,
          row: piece.row,
          col: piece.col,
          totalRows: state.rows,
          totalCols: state.cols,
          width: tileWidth,
          height: tileHeight,
          isSelected: isSelected,
          onTap: () {
            setState(() {
              _controller.selectPieceInTray(piece.id, langCode: langCode);
            });
            if (_controller.state.voicePrompt != null) {
              _speakText(_controller.state.voicePrompt!);
            }
          },
        );

        return Draggable<int>(
          data: piece.id,
          feedback: Material(
            color: Colors.transparent,
            child: Opacity(
              opacity: 0.9,
              child: PuzzlePieceTile(
                imagePath: state.activeImage.assetPath,
                row: piece.row,
                col: piece.col,
                totalRows: state.rows,
                totalCols: state.cols,
                width: tileWidth,
                height: tileHeight,
                isSelected: true,
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.35,
            child: pieceWidget,
          ),
          child: pieceWidget,
        );
      }).toList(),
    );
  }

  /// Builds progressive difficulty or calmer pace recommendation banner
  Widget _buildAdaptivePaceBanner({
    required GameDifficulty suggestion,
    required String langCode,
  }) {
    final isCalmer = suggestion == GameDifficulty.easy;
    final bannerTitle = isCalmer
        ? (langCode == 'hi'
            ? 'क्या आप आसान गति आज़माना चाहते हैं?'
            : 'Would you like a calmer pace?')
        : (langCode == 'hi'
            ? 'शानदार प्रगति! अगली चुनौती आज़माएँ?'
            : 'Wonderful focus! Try more pieces next?');

    final actionLabel = isCalmer
        ? (langCode == 'hi' ? 'शांत गति (2 टुकड़े)' : 'Try 2 Pieces')
        : (suggestion == GameDifficulty.medium
            ? (langCode == 'hi' ? '4 टुकड़े आज़माएँ' : 'Try 4 Pieces')
            : (langCode == 'hi' ? '6 टुकड़े आज़माएँ' : 'Try 6 Pieces'));

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7), // Gentle amber
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.spa_rounded,
            color: Color(0xFFD97706),
            size: 28.0,
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              bannerTitle,
              style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w700,
                color: Color(0xFF92400E),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            onPressed: () {
              setState(() {
                _controller.changeDifficulty(suggestion);
              });
              _speakInitialPrompt();
            },
            child: Text(
              actionLabel,
              style: const TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
