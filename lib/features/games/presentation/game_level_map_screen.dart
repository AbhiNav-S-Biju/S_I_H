// ==============================================================================
// NIRVANA - Game Level Map Screen
// Description: Casual game winding map with 8 progressive levels, milestone badges,
// and calm dementia-friendly visual feedback.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/providers/accessibility_providers.dart';
import '../../../../core/network/audio_service.dart';
import '../../../../core/widgets/voice_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../models/game_enums.dart';
import '../models/game_level.dart';
import '../models/game_session.dart';
import '../services/game_progress_service.dart';
import 'grocery_memory/grocery_memory_screen.dart';
import 'jigsaw_puzzle/jigsaw_puzzle_screen.dart';
import 'remember_objects/remember_objects_screen.dart';
import 'who_is_this/who_is_this_screen.dart';
import 'widgets/elder_game_button.dart';
import 'widgets/game_level_map_path.dart';
import 'widgets/level_preview_sheet.dart';

class GameLevelMapScreen extends ConsumerStatefulWidget {
  final GameType gameType;

  const GameLevelMapScreen({
    super.key,
    required this.gameType,
  });

  @override
  ConsumerState<GameLevelMapScreen> createState() => _GameLevelMapScreenState();
}

class _GameLevelMapScreenState extends ConsumerState<GameLevelMapScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Daily auto-reset if completed on a previous day
    GameProgressService.instance.checkAndPerformDailyReset(widget.gameType);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakWelcomePrompt();
    });
  }

  void _confirmReset(BuildContext context, String langCode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        title: Row(
          children: [
            const Icon(Icons.refresh_rounded, color: Color(0xFF0F766E), size: 28.0),
            const SizedBox(width: 10.0),
            Expanded(
              child: Text(
                langCode == 'as'
                    ? 'নতুনকৈ খেলিবনে?'
                    : langCode == 'hi'
                        ? 'क्या नए सिरे से शुरू करना चाहते हैं?'
                        : 'Start Afresh?',
                style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Text(
          langCode == 'as'
              ? 'এই খেলৰ ৮ টা স্তৰ আকৌ ১ নং স্তৰৰ পৰা আৰম্ভ হ’ব যাতে আপুনি সকলো স্তৰ নতুনকৈ খেলিব পাৰে।'
              : langCode == 'hi'
                  ? 'सभी 8 स्तर पुनः स्तर 1 से शुरू होंगे ताकि आप फिर से इनका आनंद ले सकें।'
                  : 'This will reset the 8 levels back to Level 1 so you can enjoy the journey afresh.',
          style: const TextStyle(fontSize: 16.0, color: Color(0xFF334155), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              langCode == 'as' ? 'বাতিল' : langCode == 'hi' ? 'रद्द करें' : 'Cancel',
              style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              GameProgressService.instance.resetGameProgress(widget.gameType);
              if (mounted) setState(() {});
            },
            child: Text(
              langCode == 'as' ? 'নতুনকৈ আৰম্ভ কৰক' : langCode == 'hi' ? 'शुरू करें' : 'Reset & Start Afresh',
              style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _speakWelcomePrompt() {
    final voiceEnabled = ref.read(voiceEnabledProvider);
    if (!voiceEnabled) return;
    final locale = ref.read(localeProvider);
    final title = GameLevel.getJourneyTitle(widget.gameType, locale.languageCode);
    final subtitle = GameLevel.getJourneySubtitle(widget.gameType, locale.languageCode);
    ref.read(audioServiceProvider).speak(
          '$title. $subtitle',
          languageCode: locale.languageCode,
        );
  }

  void _onLevelTapped(GameLevel level, GameLevelProgress? progress) {
    final locale = ref.read(localeProvider);
    final isUnlocked = GameProgressService.instance.isLevelUnlocked(
      widget.gameType,
      level.levelNumber,
    );

    if (!isUnlocked) {
      final msg = _getLockedMessage(level.levelNumber, locale.languageCode);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 22.0),
              const SizedBox(width: 10.0),
              Expanded(
                child: Text(
                  msg,
                  style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF334155),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          duration: const Duration(seconds: 3),
        ),
      );
      final voiceEnabled = ref.read(voiceEnabledProvider);
      if (voiceEnabled) {
        ref.read(audioServiceProvider).speak(msg, languageCode: locale.languageCode);
      }
      return;
    }

    LevelPreviewSheet.show(
      context,
      level: level,
      progress: progress,
      langCode: locale.languageCode,
      onStart: () {
        _launchLevel(level);
      },
    );
  }

  String _getLockedMessage(int levelNumber, String langCode) {
    switch (langCode) {
      case 'as':
        return 'এই স্তৰটো খুলিবলৈ আগৰ স্তৰসমূহ সম্পূৰ্ণ কৰক।';
      case 'hi':
        return 'इस स्तर को खोलने के लिए पहले पिछले स्तर पूरे करें।';
      case 'bn':
        return 'এই ধাপটি আনলক করতে আগের ধাপগুলো শেষ করুন।';
      default:
        return 'Complete previous levels to unlock Level $levelNumber.';
    }
  }

  void _launchLevel(GameLevel level) async {
    Widget screen;
    switch (widget.gameType) {
      case GameType.jigsawPuzzle:
        screen = JigsawPuzzleScreen(
          level: level,
          onGameCompleted: (session) => _onGameFinished(level, session),
        );
        break;
      case GameType.rememberObjects:
        screen = RememberObjectsScreen(
          level: level,
          onGameCompleted: (session) => _onGameFinished(level, session),
        );
        break;
      case GameType.whoIsThis:
        screen = WhoIsThisScreen(
          level: level,
          onGameCompleted: (session) => _onGameFinished(level, session),
        );
        break;
      case GameType.groceryMemory:
        screen = GroceryMemoryScreen(
          level: level,
          onGameCompleted: (session) => _onGameFinished(level, session),
        );
        break;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );

    if (mounted) {
      ref.invalidate(gameLevelProgressProvider(widget.gameType));
      setState(() {});
    }
  }

  void _onGameFinished(GameLevel level, GameSession session) {
    // Refresh Riverpod provider so map updates immediately
    ref.invalidate(gameLevelProgressProvider(widget.gameType));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context);
    final langCode = locale.languageCode;

    final progressMap = ref.watch(gameLevelProgressProvider(widget.gameType));

    final levels = GameLevel.getLevelsForGame(widget.gameType);
    final totalStars = GameProgressService.instance.getTotalStarsEarned(widget.gameType);
    final maxStars = levels.length * 3;
    final highestUnlocked =
        GameProgressService.instance.getHighestUnlockedLevel(widget.gameType);
    final currentLevel = levels.firstWhere(
      (l) => l.levelNumber == highestUnlocked,
      orElse: () => levels.first,
    );

    final journeyTitle = GameLevel.getJourneyTitle(widget.gameType, langCode);
    final journeySubtitle = GameLevel.getJourneySubtitle(widget.gameType, langCode);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top Header Bar
            _buildTopHeader(
              context: context,
              title: journeyTitle,
              subtitle: journeySubtitle,
              totalStars: totalStars,
              maxStars: maxStars,
              langCode: langCode,
            ),

            // Winding Map Path View with Himalayan Scenic Road Map Background
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Uploaded Himalayan Road Map Background Image
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/puzzle/roadmap_background.jpg',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                  // 2. Gentle frosted overlay for dementia-friendly contrast & legibility
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.65),
                            Colors.white.withValues(alpha: 0.48),
                            Colors.white.withValues(alpha: 0.70),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 3. Scrollable Level Map Path
                  SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: GameLevelMapPath(
                      levels: levels,
                      progressMap: progressMap,
                      highestUnlockedLevel: highestUnlocked,
                      langCode: langCode,
                      onLevelTapped: (level) {
                        _onLevelTapped(level, progressMap[level.levelNumber]);
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Continue Bar
            _buildBottomActionBar(
              currentLevel: currentLevel,
              progressMap: progressMap,
              langCode: langCode,
              l10n: l10n,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader({
    required BuildContext context,
    required String title,
    required String subtitle,
    required int totalStars,
    required int maxStars,
    required String langCode,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button (min 48dp)
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 28.0),
            color: const Color(0xFF1E293B),
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 8.0),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8.0),

          // Stars Counter Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
              ),
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x20F59E0B),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 20.0),
                const SizedBox(width: 5.0),
                Text(
                  '$totalStars / $maxStars',
                  style: const TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 4.0),

          // Reset button for a fresh daily start
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 26.0),
            color: const Color(0xFF475569),
            tooltip: 'Start Afresh',
            onPressed: () => _confirmReset(context, langCode),
          ),

          const SizedBox(width: 2.0),

          // Speak Button
          SpeakButton(
            text: '$title. $subtitle. Total stars: $totalStars out of $maxStars.',
            size: 40.0,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar({
    required GameLevel currentLevel,
    required Map<int, GameLevelProgress> progressMap,
    required String langCode,
    required AppLocalizations? l10n,
  }) {
    final isCompleted = progressMap[currentLevel.levelNumber]?.isCompleted ?? false;
    final allCompleted = GameProgressService.instance.areAllLevelsCompleted(widget.gameType);

    final buttonLabel = allCompleted
        ? (langCode == 'as'
            ? 'আকৌ নতুনকৈ খেলক ↺'
            : langCode == 'hi'
                ? 'पुनः खेलें ↺'
                : langCode == 'bn'
                    ? 'আবার খেলুন ↺'
                    : 'Start Afresh ↺')
        : isCompleted
            ? (langCode == 'as'
                ? 'পৰবৰ্তী স্তৰ খেলক ➔'
                : langCode == 'hi'
                    ? 'अगला स्तर खेलें ➔'
                    : langCode == 'bn'
                        ? 'পরবর্তী ধাপ খেলুন ➔'
                        : 'Play Next Level ➔')
            : (langCode == 'as'
                ? 'স্তৰ ${currentLevel.levelNumber} আৰম্ভ কৰক ➔'
                : langCode == 'hi'
                    ? 'स्तर ${currentLevel.levelNumber} शुरू करें ➔'
                    : langCode == 'bn'
                        ? 'ধাপ ${currentLevel.levelNumber} শুরু করুন ➔'
                        : 'Start Level ${currentLevel.levelNumber} ➔');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 8,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Current level info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 2.0,
                        ),
                        decoration: BoxDecoration(
                          color: currentLevel.themeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Text(
                          'Level ${currentLevel.levelNumber}',
                          style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w800,
                            color: currentLevel.themeColor,
                          ),
                        ),
                      ),
                      if (currentLevel.levelNumber == 4 || currentLevel.levelNumber == 8) ...[
                        const SizedBox(width: 8.0),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded, size: 12.0, color: Color(0xFFD97706)),
                              SizedBox(width: 2.0),
                              Text(
                                'Milestone',
                                style: TextStyle(
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3.0),
                  Text(
                    currentLevel.localizedTitle(langCode),
                    style: const TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14.0),

            // Start button
            ElderGameButton(
              label: buttonLabel,
              backgroundColor: currentLevel.themeColor,
              minHeight: 52.0,
              onPressed: () {
                if (allCompleted) {
                  _confirmReset(context, langCode);
                } else {
                  _onLevelTapped(currentLevel, progressMap[currentLevel.levelNumber]);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
