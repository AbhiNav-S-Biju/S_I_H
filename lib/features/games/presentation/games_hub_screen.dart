// ==============================================================================
// NIRVANA - Games Hub Screen (3D Claymorphism)
// Description: Accessible activity launcher with 8-level game journeys,
// star progression, 3D volumetric token badges, dual-layer shadows, and calm wellness aesthetics.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/providers/accessibility_providers.dart';
import '../../../app/widgets/clay_3d/clay_3d.dart';
import '../../../l10n/app_localizations.dart';
import '../models/game_enums.dart';
import '../models/game_level.dart';
import '../models/game_session.dart';
import '../services/game_progress_service.dart';
import 'game_level_map_screen.dart';

class GamesHubScreen extends ConsumerStatefulWidget {
  final ValueChanged<GameSession>? onSessionCompleted;

  const GamesHubScreen({super.key, this.onSessionCompleted});

  @override
  ConsumerState<GamesHubScreen> createState() => _GamesHubScreenState();
}

class _GamesHubScreenState extends ConsumerState<GamesHubScreen> {
  void _openGameMap(GameType type) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameLevelMapScreen(gameType: type),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeLocale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context);
    final langCode = activeLocale.languageCode;

    return ClayScaffold3D(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Navigation Header
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/patient/home');
                  }
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Clay3DTheme.cardSurface,
                    shape: BoxShape.circle,
                    boxShadow: Clay3DTheme.cardShadow(blur: 8, offset: 3),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 24,
                      color: Clay3DTheme.textDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              ClaySlab3D(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                borderRadius: 18,
                child: Text(
                  l10n?.activitiesTitle ?? 'Daily Activities',
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Clay3DTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18.0),

          // Welcome & Safety 3D Banner
          ClayCard3D(
            padding: const EdgeInsets.all(20.0),
            borderRadius: 26.0,
            color: const Color(0xFFE6F3EE),
            customShadows: Clay3DTheme.deepShadow(blur: 18, offset: 8),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Clay3DTheme.tealLight,
                    shape: BoxShape.circle,
                    boxShadow: Clay3DTheme.cardShadow(blur: 8, offset: 3),
                  ),
                  child: const Center(
                    child: Icon(Icons.spa_rounded, color: Color(0xFF1B634B), size: 30.0),
                  ),
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.activitiesBannerTitle ?? 'Welcome to Today\'s Fun!',
                        style: GoogleFonts.nunito(
                          fontSize: 18.5,
                          fontWeight: FontWeight.w900,
                          color: Clay3DTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        langCode == 'as'
                            ? 'প্ৰতিটো খেলৰ ৮ টা স্তৰৰ সুন্দৰ যাত্ৰা আৰম্ভ কৰক। আপোনাৰ নিজৰ গতিত তৰা সংগ্ৰহ কৰক।'
                            : langCode == 'hi'
                                ? 'प्रत्येक खेल के 8 स्तरों की सुंदर यात्रा शुरू करें। अपनी गति से सितारे अर्जित करें।'
                                : langCode == 'bn'
                                    ? 'প্রতিটি খেলার ৮টি স্তরের সুন্দর ভ্রমণ উপভোগ করুন। নিজের ছন্দে তারা সংগ্রহ করুন।'
                                    : 'Embark on an 8-level journey for each activity. Earn stars at your own calm pace.',
                        style: GoogleFonts.nunito(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Clay3DTheme.textMuted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22.0),

          // Section Title Slab
          ClaySlab3D(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.map_rounded, color: Color(0xFF1B634B), size: 22.0),
                const SizedBox(width: 8.0),
                Text(
                  langCode == 'as'
                      ? 'খেলৰ স্তৰ আৰু যাত্ৰা মানচিত্ৰ'
                      : langCode == 'hi'
                          ? 'खेल के स्तर और यात्रा मानचित्र'
                          : langCode == 'bn'
                              ? 'খেলার স্তর ও পরিক্রমা মানচিত্র'
                              : 'Activity Level Journeys',
                  style: GoogleFonts.nunito(
                    fontSize: 17.0,
                    fontWeight: FontWeight.w900,
                    color: Clay3DTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          // 1. Familiar Jigsaw Card
          _build3DGameCard(
            gameType: GameType.jigsawPuzzle,
            title: GameType.jigsawPuzzle.localizedTitle(l10n),
            subtitle: GameType.jigsawPuzzle.localizedSubtitle(l10n),
            emoji: '🧩',
            tokenColor: Clay3DTheme.coralLight,
            langCode: langCode,
            onOpenMap: () => _openGameMap(GameType.jigsawPuzzle),
          ),
          const SizedBox(height: 18.0),

          // 2. Remember Objects Card
          _build3DGameCard(
            gameType: GameType.rememberObjects,
            title: GameType.rememberObjects.localizedTitle(l10n),
            subtitle: GameType.rememberObjects.localizedSubtitle(l10n),
            emoji: '🍎',
            tokenColor: Clay3DTheme.tealLight,
            langCode: langCode,
            onOpenMap: () => _openGameMap(GameType.rememberObjects),
          ),
          const SizedBox(height: 18.0),

          // 3. Who Is This? Card
          _build3DGameCard(
            gameType: GameType.whoIsThis,
            title: GameType.whoIsThis.localizedTitle(l10n),
            subtitle: GameType.whoIsThis.localizedSubtitle(l10n),
            emoji: '👵',
            tokenColor: Clay3DTheme.lavenderLight,
            langCode: langCode,
            onOpenMap: () => _openGameMap(GameType.whoIsThis),
          ),
          const SizedBox(height: 18.0),

          // 4. Grocery Memory Card
          _build3DGameCard(
            gameType: GameType.groceryMemory,
            title: GameType.groceryMemory.localizedTitle(l10n),
            subtitle: GameType.groceryMemory.localizedSubtitle(l10n),
            emoji: '🛒',
            tokenColor: const Color(0xFFFEE8A2),
            langCode: langCode,
            onOpenMap: () => _openGameMap(GameType.groceryMemory),
          ),
          const SizedBox(height: 32.0),
        ],
      ),
    );
  }

  Widget _build3DGameCard({
    required GameType gameType,
    required String title,
    required String subtitle,
    required String emoji,
    required Color tokenColor,
    required String langCode,
    required VoidCallback onOpenMap,
  }) {
    final progress = GameProgressService.instance.getProgressForGame(gameType);
    final totalStars = GameProgressService.instance.getTotalStarsEarned(gameType);
    final highestLevel = GameProgressService.instance.getHighestUnlockedLevel(gameType);
    final completedCount = progress.values.where((p) => p.isCompleted).length;
    final journeyTitle = GameLevel.getJourneyTitle(gameType, langCode);

    final String buttonLabel;
    if (completedCount == 0) {
      buttonLabel = langCode == 'as'
          ? 'যাত্ৰা আৰম্ভ কৰক ➔'
          : langCode == 'hi'
              ? 'यात्रा शुरू करें ➔'
              : langCode == 'bn'
                  ? 'যাত্রা শুরু করুন ➔'
                  : 'Start Level Journey ➔';
    } else if (completedCount >= 8) {
      buttonLabel = langCode == 'as'
          ? 'মানচিত্ৰ চাওক (সম্পূৰ্ণ) 🏆'
          : langCode == 'hi'
              ? 'मानचित्र देखें (पूर्ण) 🏆'
              : langCode == 'bn'
                  ? 'মানচিত্র দেখুন (সম্পূর্ণ) 🏆'
                  : 'View Map (Completed) 🏆';
    } else {
      buttonLabel = langCode == 'as'
          ? 'স্তৰ $highestLevel লৈ আগবাঢ়ক ➔'
          : langCode == 'hi'
              ? 'स्तर $highestLevel जारी रखें ➔'
              : langCode == 'bn'
                  ? 'ধাপ $highestLevel এ চলুন ➔'
                  : 'Continue Level $highestLevel ➔';
    }

    return ClayCard3D(
      padding: const EdgeInsets.all(22.0),
      borderRadius: 26.0,
      customShadows: Clay3DTheme.deepShadow(blur: 18, offset: 8),
      onTap: onOpenMap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60.0,
                height: 60.0,
                decoration: BoxDecoration(
                  color: tokenColor,
                  shape: BoxShape.circle,
                  boxShadow: Clay3DTheme.cardShadow(blur: 8, offset: 3),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 30.0)),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.nunito(
                        fontSize: 19.0,
                        fontWeight: FontWeight.w900,
                        color: Clay3DTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      journeyTitle,
                      style: GoogleFonts.nunito(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Clay3DTheme.lavenderDeep,
                      ),
                    ),
                    const SizedBox(height: 3.0),
                    Text(
                      subtitle,
                      style: GoogleFonts.nunito(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Clay3DTheme.textMuted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          // Level progress bar & stars status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF1EBE0),
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Row(
              children: [
                Icon(
                  completedCount >= 8
                      ? Icons.emoji_events_rounded
                      : Icons.alt_route_rounded,
                  size: 20.0,
                  color: completedCount >= 8
                      ? const Color(0xFF8C6212)
                      : const Color(0xFF1B634B),
                ),
                const SizedBox(width: 8.0),
                Text(
                  langCode == 'as'
                      ? 'স্তৰ $completedCount / ৮ সম্পূৰ্ণ'
                      : langCode == 'hi'
                          ? 'स्तर $completedCount / 8 पूरे'
                          : langCode == 'bn'
                              ? 'ধাপ $completedCount / ৮ সম্পূর্ণ'
                              : 'Level $completedCount of 8 Done',
                  style: GoogleFonts.nunito(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Clay3DTheme.textDark,
                  ),
                ),
                const Spacer(),
                ClayPill3D(
                  color: const Color(0xFFFDE8C0),
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 3.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFF8C6212),
                        size: 16.0,
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        '$totalStars / 24',
                        style: GoogleFonts.nunito(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF8C6212),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          ClayButton3D(
            label: buttonLabel,
            icon: Icons.map_outlined,
            color: Clay3DTheme.lavender,
            minHeight: 50,
            onPressed: onOpenMap,
          ),
        ],
      ),
    );
  }
}
