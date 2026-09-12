// ==============================================================================
// NIRVANA - Games Hub Screen
// Description: Accessible activity launcher with 8-level game journey maps,
// star progression, dementia-friendly reassurance, and soft claymorphism design.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers/accessibility_providers.dart';
import '../../../app/theme/elder_theme.dart';
import '../../../app/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../models/game_enums.dart';
import '../models/game_level.dart';
import '../models/game_session.dart';
import '../services/game_progress_service.dart';
import '../../../database/hive_database.dart';
import 'game_level_map_screen.dart';
import 'widgets/elder_game_button.dart';

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
        builder: (_) => GameLevelMapScreen(
          gameType: type,
          onSessionCompleted: widget.onSessionCompleted,
        ),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    final patientId = HiveDatabase.pairedPatientId;
    if (patientId != null) {
      GameProgressService.instance.initializeForPatient(patientId).then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeLocale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context);
    final langCode = activeLocale.languageCode;

    return Scaffold(
      backgroundColor: ElderColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: LargeIconButton(
            icon: Icons.arrow_back_rounded,
            semanticLabel: 'Back to Home',
            size: 48,
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/patient/home');
              }
            },
          ),
        ),
        title: Text(
          l10n?.activitiesTitle ?? 'Daily Activities',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: ElderColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome & Safety Banner
            Container(
              padding: const EdgeInsets.all(18.0),
              decoration: BoxDecoration(
                color: ElderColors.forestBg,
                borderRadius: BorderRadius.circular(NirvanaRadii.card),
                boxShadow: NirvanaShadows.card(tint: ElderColors.forestDeep),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.spa_rounded,
                    color: ElderColors.forestDeep,
                    size: 36.0,
                  ),
                  const SizedBox(width: 14.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.activitiesBannerTitle ??
                              'Welcome to Today\'s Fun!',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: ElderColors.forestDeep,
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
                          style: TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.w500,
                            color: ElderColors.forestDeep.withValues(
                              alpha: 0.85,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20.0),

            // Section Header
            Row(
              children: [
                const Icon(
                  Icons.map_rounded,
                  color: ElderColors.forestDeep,
                  size: 24.0,
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    langCode == 'as'
                        ? 'খেলৰ স্তৰ আৰু যাত্ৰা মানচিত্ৰ'
                        : langCode == 'hi'
                        ? 'खेल के स्तर और यात्रा मानचित्र'
                        : langCode == 'bn'
                        ? 'খেলার স্তর ও পরিক্রমা মানচিত্র'
                        : 'Activity Level Journeys',
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w800,
                      color: ElderColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14.0),

            // 1. Familiar Jigsaw Card (Pastel Peach)
            _buildGameCard(
              gameType: GameType.jigsawPuzzle,
              title: GameType.jigsawPuzzle.localizedTitle(l10n),
              subtitle: GameType.jigsawPuzzle.localizedSubtitle(l10n),
              emoji: '🧩',
              badgeColor: ElderColors.pastelPeach,
              textColor: ElderColors.coralDeep,
              langCode: langCode,
              onOpenMap: () => _openGameMap(GameType.jigsawPuzzle),
            ),
            const SizedBox(height: 18.0),

            // 2. Remember Objects Card (Pastel Sage)
            _buildGameCard(
              gameType: GameType.rememberObjects,
              title: GameType.rememberObjects.localizedTitle(l10n),
              subtitle: GameType.rememberObjects.localizedSubtitle(l10n),
              emoji: '🍎',
              badgeColor: ElderColors.pastelSage,
              textColor: ElderColors.forestDeep,
              langCode: langCode,
              onOpenMap: () => _openGameMap(GameType.rememberObjects),
            ),
            const SizedBox(height: 18.0),

            // 3. Who Is This? Card (Pastel Lavender)
            _buildGameCard(
              gameType: GameType.whoIsThis,
              title: GameType.whoIsThis.localizedTitle(l10n),
              subtitle: GameType.whoIsThis.localizedSubtitle(l10n),
              emoji: '👵',
              badgeColor: ElderColors.pastelLavender,
              textColor: ElderColors.lavenderDeep,
              langCode: langCode,
              onOpenMap: () => _openGameMap(GameType.whoIsThis),
            ),
            const SizedBox(height: 18.0),

            // 4. Grocery Memory Card (Pastel Buttercup)
            _buildGameCard(
              gameType: GameType.groceryMemory,
              title: GameType.groceryMemory.localizedTitle(l10n),
              subtitle: GameType.groceryMemory.localizedSubtitle(l10n),
              emoji: '🛒',
              badgeColor: ElderColors.pastelButtercup,
              textColor: ElderColors.amberDeep,
              langCode: langCode,
              onOpenMap: () => _openGameMap(GameType.groceryMemory),
            ),
            const SizedBox(height: 28.0),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard({
    required GameType gameType,
    required String title,
    required String subtitle,
    required String emoji,
    required Color badgeColor,
    required Color textColor,
    required String langCode,
    required VoidCallback onOpenMap,
  }) {
    final progress = GameProgressService.instance.getProgressForGame(gameType);
    final totalStars = GameProgressService.instance.getTotalStarsEarned(
      gameType,
    );
    final highestLevel = GameProgressService.instance.getHighestUnlockedLevel(
      gameType,
    );
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

    return Container(
      decoration: BoxDecoration(
        color: ElderColors.surface,
        borderRadius: BorderRadius.circular(NirvanaRadii.card),
        boxShadow: NirvanaShadows.card(),
      ),
      padding: const EdgeInsets.all(22.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64.0,
                height: 64.0,
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  boxShadow: NirvanaShadows.float(tint: badgeColor),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 32.0)),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: ElderColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3.0),
                    Text(
                      journeyTitle,
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                        color: ElderColors.textSecondary,
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
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 10.0,
            ),
            decoration: BoxDecoration(
              color: ElderColors.surfaceElevated,
              borderRadius: BorderRadius.circular(NirvanaRadii.button),
              border: Border.all(color: ElderColors.borderLight),
            ),
            child: Row(
              children: [
                // Completed indicator
                Icon(
                  completedCount >= 8
                      ? Icons.emoji_events_rounded
                      : Icons.alt_route_rounded,
                  size: 20.0,
                  color: completedCount >= 8
                      ? ElderColors.amberDeep
                      : ElderColors.forestDeep,
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    langCode == 'as'
                        ? 'স্তৰ $completedCount / ৮ সম্পূৰ্ণ'
                        : langCode == 'hi'
                        ? 'स्तर $completedCount / 8 पूरे'
                        : langCode == 'bn'
                        ? 'ধাপ $completedCount / ৮ সম্পূর্ণ'
                        : 'Level $completedCount of 8 Done',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w700,
                      color: ElderColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                // Stars pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: ElderColors.pastelButtercupBg,
                    borderRadius: BorderRadius.circular(NirvanaRadii.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: ElderColors.amberDeep,
                        size: 16.0,
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        '$totalStars / 24',
                        style: const TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w800,
                          color: ElderColors.amberDeep,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          // Open Level Map Button
          ElderGameButton(
            label: buttonLabel,
            icon: Icons.map_outlined,
            onPressed: onOpenMap,
          ),
        ],
      ),
    );
  }
}
