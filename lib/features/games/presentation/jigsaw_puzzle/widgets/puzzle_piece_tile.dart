// ==============================================================================
// NIRVANA - PuzzlePieceTile Widget
// Description: Accessible, high-clarity puzzle piece segment with soft rounded borders
// ==============================================================================

import 'package:flutter/material.dart';

class PuzzlePieceTile extends StatelessWidget {
  final String imagePath;
  final int row;
  final int col;
  final int totalRows;
  final int totalCols;
  final double width;
  final double height;
  final bool isSelected;
  final bool isPlaced;
  final bool isGhost;
  final VoidCallback? onTap;

  const PuzzlePieceTile({
    super.key,
    required this.imagePath,
    required this.row,
    required this.col,
    required this.totalRows,
    required this.totalCols,
    required this.width,
    required this.height,
    this.isSelected = false,
    this.isPlaced = false,
    this.isGhost = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fullWidth = width * totalCols;
    final fullHeight = height * totalRows;

    // Mathematical alignment to position the sliced segment
    final alignX =
        totalCols > 1 ? -1.0 + (2.0 * col / (totalCols - 1)) : 0.0;
    final alignY =
        totalRows > 1 ? -1.0 + (2.0 * row / (totalRows - 1)) : 0.0;

    final borderColor = isSelected
        ? const Color(0xFF0D9488) // Vibrant warm teal
        : isPlaced
            ? const Color(0xFF10B981) // Gentle green
            : const Color(0xFFCBD5E1); // Soft slate

    final borderWidth = isSelected ? 3.5 : (isPlaced ? 2.0 : 2.0);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: isGhost
              ? null
              : [
                  BoxShadow(
                    color: isSelected
                        ? const Color(0x330D9488)
                        : Colors.black.withAlpha(25),
                    blurRadius: isSelected ? 12.0 : 6.0,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Opacity(
            opacity: isGhost ? 0.25 : 1.0,
            child: OverflowBox(
              minWidth: fullWidth,
              maxWidth: fullWidth,
              minHeight: fullHeight,
              maxHeight: fullHeight,
              alignment: Alignment(alignX, alignY),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                width: fullWidth,
                height: fullHeight,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFFE2E8F0),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_rounded,
                    color: Color(0xFF94A3B8),
                    size: 32.0,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
