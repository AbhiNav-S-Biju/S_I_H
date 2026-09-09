// ==============================================================================
// NIRVANA - Game Level Map Path Widget
// Description: Winding S-curve level map connecting sequential journey milestones
// ==============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/game_level.dart';

class GameLevelMapPath extends StatelessWidget {
  final List<GameLevel> levels;
  final Map<int, GameLevelProgress> progressMap;
  final int highestUnlockedLevel;
  final String langCode;
  final ValueChanged<GameLevel> onLevelTapped;

  const GameLevelMapPath({
    super.key,
    required this.levels,
    required this.progressMap,
    required this.highestUnlockedLevel,
    required this.langCode,
    required this.onLevelTapped,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width.clamp(320.0, 500.0);
    const nodeSpacing = 140.0;
    final totalHeight = (levels.length * nodeSpacing) + 120.0;

    // Calculate node coordinates along an organic S-curve
    final nodePoints = <Offset>[];
    for (int i = 0; i < levels.length; i++) {
      // Alternates horizontally between left (0.28), center (0.5), right (0.72)
      final xRatio = 0.5 + 0.28 * math.sin(i * 1.35);
      final x = width * xRatio;
      final y = 60.0 + (i * nodeSpacing);
      nodePoints.add(Offset(x, y));
    }

    return Center(
      child: SizedBox(
        width: width,
        height: totalHeight,
        child: Stack(
          children: [
            // 1. Custom Painted Winding Connecting Path
            Positioned.fill(
              child: CustomPaint(
                painter: _WindingPathPainter(
                  points: nodePoints,
                  highestUnlockedIndex: highestUnlockedLevel - 1,
                ),
              ),
            ),

            // 2. Interactive Level Nodes placed over path
            for (int i = 0; i < levels.length; i++) ...[
              _buildPositionedNode(
                context: context,
                index: i,
                point: nodePoints[i],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPositionedNode({
    required BuildContext context,
    required int index,
    required Offset point,
  }) {
    final level = levels[index];
    final progress = progressMap[level.levelNumber] ??
        GameLevelProgress.initial(level.levelNumber);
    final isCompleted = progress.isCompleted;
    final isUnlocked = level.levelNumber <= highestUnlockedLevel;
    final isCurrent = level.levelNumber == highestUnlockedLevel && !isCompleted;
    final isMilestone = level.levelNumber == 4 || level.levelNumber == 8;

    const nodeSize = 72.0;

    return Positioned(
      left: point.dx - (nodeSize / 2),
      top: point.dy - (nodeSize / 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Current Level "PLAY" Badge
          if (isCurrent)
            Container(
              margin: const EdgeInsets.only(bottom: 6.0),
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 3.0),
              decoration: BoxDecoration(
                color: level.themeColor,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: level.themeColor.withAlpha(90),
                    blurRadius: 8.0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'PLAY',
                style: TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
            ),

          // Circular Interactive Node
          GestureDetector(
            onTap: isUnlocked ? () => onLevelTapped(level) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: isMilestone ? nodeSize + 6.0 : nodeSize,
              height: isMilestone ? nodeSize + 6.0 : nodeSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isCompleted
                    ? const LinearGradient(
                        colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : isCurrent
                        ? LinearGradient(
                            colors: [level.themeColor, level.themeColor.withAlpha(200)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : const LinearGradient(
                            colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                border: Border.all(
                  color: isCurrent
                      ? Colors.white
                      : isCompleted
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFF94A3B8),
                  width: isCurrent ? 3.5 : 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isCurrent
                        ? level.themeColor.withAlpha(100)
                        : isCompleted
                            ? const Color(0x3316A34A)
                            : Colors.black12,
                    blurRadius: isCurrent ? 14.0 : 8.0,
                    spreadRadius: isCurrent ? 2.0 : 0.0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: !isUnlocked
                  ? const Icon(
                      Icons.lock_rounded,
                      color: Color(0xFF64748B),
                      size: 26.0,
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '${level.levelNumber}',
                          style: const TextStyle(
                            fontSize: 26.0,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        if (isCompleted)
                          const Positioned(
                            top: 4.0,
                            right: 4.0,
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFFFEF08A),
                              size: 16.0,
                            ),
                          ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 6.0),

          // Stars Earned (for completed levels)
          if (isCompleted)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (starIdx) {
                final earned = starIdx < progress.starsEarned;
                return Icon(
                  earned ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 14.0,
                  color: earned ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                );
              }),
            ),

          // Level Title Pill Badge
          Container(
            margin: const EdgeInsets.only(top: 4.0),
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 3.0),
            constraints: const BoxConstraints(maxWidth: 130.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: isUnlocked ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
                width: 1.0,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4.0,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              level.localizedTitle(langCode),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                color: isUnlocked ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for drawing smooth winding bezier path between nodes
class _WindingPathPainter extends CustomPainter {
  final List<Offset> points;
  final int highestUnlockedIndex;

  _WindingPathPainter({
    required this.points,
    required this.highestUnlockedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final isSegmentUnlocked = i < highestUnlockedIndex;

      final paint = Paint()
        ..color = isSegmentUnlocked
            ? const Color(0xFF10B981) // Vibrant emerald path
            : const Color(0xFFCBD5E1) // Calm neutral path
        ..strokeWidth = isSegmentUnlocked ? 6.0 : 4.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Smooth S-curve control points
      final midY = (p1.dy + p2.dy) / 2;
      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..cubicTo(
          p1.dx,
          midY,
          p2.dx,
          midY,
          p2.dx,
          p2.dy,
        );

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WindingPathPainter oldDelegate) {
    return oldDelegate.highestUnlockedIndex != highestUnlockedIndex ||
        oldDelegate.points.length != points.length;
  }
}
