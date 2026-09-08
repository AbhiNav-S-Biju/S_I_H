// ==============================================================================
// NIRVANA - Games Hub Screen
// Description: Accessible activity launcher for Elder Mode
// ==============================================================================

import 'package:flutter/material.dart';
import '../models/game_enums.dart';
import '../models/game_session.dart';
import 'grocery_memory/grocery_memory_screen.dart';
import 'remember_objects/remember_objects_screen.dart';
import 'who_is_this/who_is_this_screen.dart';
import 'widgets/elder_game_button.dart';

class GamesHubScreen extends StatefulWidget {
  final ValueChanged<GameSession>? onSessionCompleted;

  const GamesHubScreen({super.key, this.onSessionCompleted});

  @override
  State<GamesHubScreen> createState() => _GamesHubScreenState();
}

class _GamesHubScreenState extends State<GamesHubScreen> {
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Daily Activities',
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome & Safety Banner
            Container(
              padding: const EdgeInsets.all(18.0),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.spa_rounded, color: Color(0xFF16A34A), size: 36.0),
                  SizedBox(width: 14.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome to Today\'s Fun!',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF14532D),
                          ),
                        ),
                        SizedBox(height: 4.0),
                        Text(
                          'Choose an enjoyable activity below. Take all the time you like.',
                          style: TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            // Difficulty Selector (Pill bar)
            const Text(
              'Activity Pace:',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 10.0),
            Row(
              children: GameDifficulty.values.map((diff) {
                final isSelected = _selectedDifficulty == diff;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedDifficulty = diff;
                        });
                      },
                      borderRadius: BorderRadius.circular(14.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF0F766E)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14.0),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF0F766E)
                                : const Color(0xFFCBD5E1),
                            width: 2.0,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          diff.label,
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28.0),

            // 1. Remember Objects Card
            _buildGameCard(
              title: GameType.rememberObjects.displayName,
              subtitle: GameType.rememberObjects.subtitle,
              emoji: '🍎',
              badgeColor: const Color(0xFFDCFCE7),
              textColor: const Color(0xFF166534),
              onPlay: () => _launchGame(
                RememberObjectsScreen(
                  difficulty: _selectedDifficulty,
                  onGameCompleted: widget.onSessionCompleted,
                ),
              ),
            ),
            const SizedBox(height: 18.0),

            // 2. Who Is This? Card
            _buildGameCard(
              title: GameType.whoIsThis.displayName,
              subtitle: GameType.whoIsThis.subtitle,
              emoji: '👵',
              badgeColor: const Color(0xFFE0F2FE),
              textColor: const Color(0xFF075985),
              onPlay: () => _launchGame(
                WhoIsThisScreen(
                  difficulty: _selectedDifficulty,
                  onGameCompleted: widget.onSessionCompleted,
                ),
              ),
            ),
            const SizedBox(height: 18.0),

            // 3. Grocery Memory Card
            _buildGameCard(
              title: GameType.groceryMemory.displayName,
              subtitle: GameType.groceryMemory.subtitle,
              emoji: '🛒',
              badgeColor: const Color(0xFFFEF3C7),
              textColor: const Color(0xFF92400E),
              onPlay: () => _launchGame(
                GroceryMemoryScreen(
                  difficulty: _selectedDifficulty,
                  onGameCompleted: widget.onSessionCompleted,
                ),
              ),
            ),
            const SizedBox(height: 24.0),
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
    required Color textColor,
    required VoidCallback onPlay,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.0),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 60.0,
                height: 60.0,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
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
                        fontSize: 22.0,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18.0),
          ElderGameButton(
            label: 'Play Activity ➔',
            icon: Icons.play_arrow_rounded,
            onPressed: onPlay,
          ),
        ],
      ),
    );
  }
}
