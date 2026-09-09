// ==============================================================================
// NIRVANA - Games Hub Screen
// Description: Accessible, claymorphic activity launcher for Elder Mode
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers/accessibility_providers.dart';
import '../../../app/theme/elder_theme.dart';
import '../../../app/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../models/game_enums.dart';
import '../models/game_session.dart';
import 'grocery_memory/grocery_memory_screen.dart';
import 'jigsaw_puzzle/jigsaw_puzzle_screen.dart';
import 'remember_objects/remember_objects_screen.dart';
import 'who_is_this/who_is_this_screen.dart';

class GamesHubScreen extends ConsumerStatefulWidget {
  final ValueChanged<GameSession>? onSessionCompleted;

  const GamesHubScreen({super.key, this.onSessionCompleted});

  @override
  ConsumerState<GamesHubScreen> createState() => _GamesHubScreenState();
}

class _GamesHubScreenState extends ConsumerState<GamesHubScreen> {
  GameDifficulty _selectedDifficulty = GameDifficulty.easy;

  void _launchGame(Widget screen) async {
    final session = await Navigator.of(
      context,
    ).push<GameSession>(MaterialPageRoute(builder: (_) => screen));

    if (session != null && widget.onSessionCompleted != null) {
      widget.onSessionCompleted!(session);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context);

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
          style: const TextStyle(
            fontSize: 22.0,
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
            SupportiveMessage(
              message: l10n?.activitiesBannerSubtitle ??
                  'Choose an enjoyable activity below. Take all the time you like at your own pace.',
              icon: Icons.spa_rounded,
              backgroundColor: ElderColors.pastelSage,
              accentColor: ElderColors.forestDeep,
            ),
            const SizedBox(height: 20.0),

            // Difficulty Selector (Clay pill bar)
            Text(
              l10n?.activityPace ?? 'Activity Pace:',
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w900,
                color: ElderColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12.0),
            Row(
              children: GameDifficulty.values.map((diff) {
                final isSelected = _selectedDifficulty == diff;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? ElderColors.primary : ElderColors.surface,
                        borderRadius: BorderRadius.circular(NirvanaRadii.pill),
                        boxShadow: isSelected
                            ? NirvanaShadows.button(color: ElderColors.primary)
                            : NirvanaShadows.card(),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(NirvanaRadii.pill),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedDifficulty = diff;
                            });
                          },
                          borderRadius: BorderRadius.circular(NirvanaRadii.pill),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14.0),
                            child: Text(
                              diff.localizedLabel(l10n),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? Colors.white : ElderColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24.0),

            // 1. Remember Objects Card (Pastel Sage)
            _buildGameCard(
              title: GameType.rememberObjects.localizedTitle(l10n),
              subtitle: GameType.rememberObjects.localizedSubtitle(l10n),
              emoji: '🍎',
              badgeColor: ElderColors.pastelSage,
              buttonVariant: LargeActionButtonVariant.sage,
              buttonLabel: l10n?.playActivityButton ?? 'Play Activity',
              onPlay: () => _launchGame(
                RememberObjectsScreen(
                  difficulty: _selectedDifficulty,
                  onGameCompleted: widget.onSessionCompleted,
                ),
              ),
            ),
            const SizedBox(height: 18.0),

            // 2. Who Is This? Card (Pastel Lavender)
            _buildGameCard(
              title: GameType.whoIsThis.localizedTitle(l10n),
              subtitle: GameType.whoIsThis.localizedSubtitle(l10n),
              emoji: '👵',
              badgeColor: ElderColors.pastelLavender,
              buttonVariant: LargeActionButtonVariant.primary,
              buttonLabel: l10n?.playActivityButton ?? 'Play Activity',
              onPlay: () => _launchGame(
                WhoIsThisScreen(
                  difficulty: _selectedDifficulty,
                  onGameCompleted: widget.onSessionCompleted,
                ),
              ),
            ),
            const SizedBox(height: 18.0),

            // 3. Grocery Memory Card (Pastel Buttercup)
            _buildGameCard(
              title: GameType.groceryMemory.localizedTitle(l10n),
              subtitle: GameType.groceryMemory.localizedSubtitle(l10n),
              emoji: '🛒',
              badgeColor: ElderColors.pastelButtercup,
              buttonVariant: LargeActionButtonVariant.buttercup,
              buttonLabel: l10n?.playActivityButton ?? 'Play Activity',
              onPlay: () => _launchGame(
                GroceryMemoryScreen(
                  difficulty: _selectedDifficulty,
                  onGameCompleted: widget.onSessionCompleted,
                ),
              ),
            ),
            const SizedBox(height: 18.0),

            // 4. Familiar Jigsaw Card (Pastel Peach)
            _buildGameCard(
              title: GameType.jigsawPuzzle.localizedTitle(l10n),
              subtitle: GameType.jigsawPuzzle.localizedSubtitle(l10n),
              emoji: '🧩',
              badgeColor: ElderColors.pastelPeach,
              buttonVariant: LargeActionButtonVariant.peach,
              buttonLabel: l10n?.playActivityButton ?? 'Play Activity',
              onPlay: () => _launchGame(
                JigsawPuzzleScreen(
                  difficulty: _selectedDifficulty,
                  onGameCompleted: widget.onSessionCompleted,
                ),
              ),
            ),
            const SizedBox(height: 28.0),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard({
    required String title,
    required String subtitle,
    required String emoji,
    required Color badgeColor,
    required LargeActionButtonVariant buttonVariant,
    required String buttonLabel,
    required VoidCallback onPlay,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: ElderColors.surface,
        borderRadius: BorderRadius.circular(ElderTheme.cardBorderRadius),
        boxShadow: NirvanaShadows.card(),
      ),
      padding: const EdgeInsets.all(22.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
                      style: const TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.w900,
                        color: ElderColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 15.0,
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
          const SizedBox(height: 20.0),
          LargeActionButton(
            label: buttonLabel,
            variant: buttonVariant,
            icon: Icons.play_arrow_rounded,
            onPressed: onPlay,
          ),
        ],
      ),
    );
  }
}

