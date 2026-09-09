// ==============================================================================
// NIRVANA - LevelPreviewSheet Widget
// Description: Elderly-accessible modal sheet previewing level objective and stars
// ==============================================================================

import 'package:flutter/material.dart';
import '../../models/game_level.dart';

class LevelPreviewSheet extends StatelessWidget {
  final GameLevel level;
  final GameLevelProgress? progress;
  final String langCode;
  final VoidCallback onStart;

  const LevelPreviewSheet({
    super.key,
    required this.level,
    this.progress,
    required this.langCode,
    required this.onStart,
  });

  static Future<void> show(
    BuildContext context, {
    required GameLevel level,
    GameLevelProgress? progress,
    required String langCode,
    required VoidCallback onStart,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LevelPreviewSheet(
        level: level,
        progress: progress,
        langCode: langCode,
        onStart: () {
          Navigator.of(ctx).pop();
          onStart();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = level.localizedTitle(langCode);
    final description = level.localizedDescription(langCode);
    final effectiveProgress =
        progress ?? GameLevelProgress.initial(level.levelNumber);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16.0,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 48.0,
                height: 5.0,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
            const SizedBox(height: 20.0),

            // Top Header Row
            Row(
              children: [
                // Level Badge
                Container(
                  width: 56.0,
                  height: 56.0,
                  decoration: BoxDecoration(
                    color: level.themeColor.withAlpha(30),
                    shape: BoxShape.circle,
                    border: Border.all(color: level.themeColor, width: 2.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${level.levelNumber}',
                    style: TextStyle(
                      fontSize: 26.0,
                      fontWeight: FontWeight.w900,
                      color: level.themeColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),

                // Title & Difficulty
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22.0,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10.0,
                              vertical: 3.0,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Text(
                              'LEVEL ${level.levelNumber}',
                              style: const TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475569),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          if (level.levelNumber == 4 || level.levelNumber == 8)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10.0,
                                vertical: 3.0,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.emoji_events_rounded,
                                    size: 14.0,
                                    color: Color(0xFFD97706),
                                  ),
                                  SizedBox(width: 4.0),
                                  Text(
                                    'Milestone',
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFD97706),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Close Button
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 28.0),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20.0),

            // Objective Box
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(
                    level.icon,
                    size: 32.0,
                    color: level.themeColor,
                  ),
                  const SizedBox(width: 14.0),
                  Expanded(
                    child: Text(
                      description,
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20.0),

            // Stars Rating Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final isEarned = index < effectiveProgress.starsEarned;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: Icon(
                    isEarned ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isEarned
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFCBD5E1),
                    size: 40.0,
                  ),
                );
              }),
            ),
            if (effectiveProgress.isCompleted)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  langCode == 'hi'
                      ? 'सर्वश्रेष्ठ स्कोर: ${effectiveProgress.bestScore}'
                      : 'Best Score: ${effectiveProgress.bestScore}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            const SizedBox(height: 24.0),

            // Start Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: level.themeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18.0),
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.0),
                ),
              ),
              onPressed: onStart,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    effectiveProgress.isCompleted
                        ? Icons.replay_rounded
                        : Icons.play_arrow_rounded,
                    size: 28.0,
                  ),
                  const SizedBox(width: 10.0),
                  Text(
                    effectiveProgress.isCompleted
                        ? (langCode == 'hi' ? 'फिर से खेलें' : 'Play Again')
                        : (langCode == 'hi' ? 'स्तर शुरू करें' : 'Start Level ➔'),
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
