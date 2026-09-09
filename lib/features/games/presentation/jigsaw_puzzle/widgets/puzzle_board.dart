// ==============================================================================
// NIRVANA - PuzzleBoard Widget
// Description: Error-tolerant jigsaw board with ghost image guide and dual input
// ==============================================================================

import 'package:flutter/material.dart';
import '../../../controllers/jigsaw_puzzle_controller.dart';
import 'puzzle_piece_tile.dart';

class PuzzleBoard extends StatelessWidget {
  final JigsawPuzzleState state;
  final double boardWidth;
  final double boardHeight;
  final void Function(int pieceId, int row, int col) onPieceDropped;
  final void Function(int row, int col) onSlotTapped;

  const PuzzleBoard({
    super.key,
    required this.state,
    required this.boardWidth,
    required this.boardHeight,
    required this.onPieceDropped,
    required this.onSlotTapped,
  });

  @override
  Widget build(BuildContext context) {
    final slotWidth = boardWidth / state.cols;
    final slotHeight = boardHeight / state.rows;

    return Container(
      width: boardWidth,
      height: boardHeight,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Calm neutral background
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 2.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8.0,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.0),
        child: Stack(
          children: [
            // 1. Ghost Image Guide (Semi-transparent anchor for dementia comfort)
            Positioned.fill(
              child: Opacity(
                opacity: 0.18,
                child: Image.asset(
                  state.activeImage.assetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),

            // 2. Interactive Slot Grid (using Expanded to fit inner bounds exactly)
            Column(
              children: List.generate(state.rows, (r) {
                return Expanded(
                  child: Row(
                    children: List.generate(state.cols, (c) {
                      final slotIndex = r * state.cols + c;
                      final isFilled = state.isSlotFilled(r, c);
                      final piece = state.getPieceAtSlot(r, c);
                      final isHighlighted =
                          state.highlightedSlotIndex == slotIndex;

                      return Expanded(
                        child: DragTarget<int>(
                          onWillAcceptWithDetails: (details) => !isFilled,
                          onAcceptWithDetails: (details) {
                            onPieceDropped(details.data, r, c);
                          },
                          builder: (context, candidateData, rejectedData) {
                            final isDragHovering = candidateData.isNotEmpty;

                            return GestureDetector(
                              onTap: () {
                                if (!isFilled) {
                                  onSlotTapped(r, c);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: (isHighlighted || isDragHovering)
                                        ? const Color(0xFF0D9488) // Glowing teal
                                        : const Color(0xFFCBD5E1), // Clear border
                                    width: (isHighlighted || isDragHovering)
                                        ? 3.0
                                        : 1.5,
                                  ),
                                  color: isDragHovering
                                      ? const Color(0x330D9488)
                                      : isHighlighted
                                          ? const Color(0x2214B8A6)
                                          : Colors.transparent,
                                ),
                                alignment: Alignment.center,
                                child: isFilled && piece != null
                                    ? PuzzlePieceTile(
                                        imagePath: state.activeImage.assetPath,
                                        row: piece.row,
                                        col: piece.col,
                                        totalRows: state.rows,
                                        totalCols: state.cols,
                                        width: slotWidth - 4.0,
                                        height: slotHeight - 4.0,
                                        isPlaced: true,
                                      )
                                    : _buildEmptySlotPlaceholder(
                                        isHighlighted: isHighlighted,
                                      ),
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySlotPlaceholder({
    required bool isHighlighted,
  }) {
    if (isHighlighted) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12.0,
          vertical: 6.0,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0D9488), // Warm soothing teal
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: const [
            BoxShadow(
              color: Color(0x330D9488),
              blurRadius: 8.0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lightbulb_rounded,
              color: Colors.white,
              size: 16.0,
            ),
            SizedBox(width: 6.0),
            Text(
              'Place here',
              style: TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 28.0,
      height: 28.0,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withAlpha(120),
        border: Border.all(
          color: const Color(0xFFCBD5E1),
          width: 1.5,
        ),
      ),
      child: const Icon(
        Icons.add_rounded,
        color: Color(0xFF94A3B8),
        size: 18.0,
      ),
    );
  }
}
