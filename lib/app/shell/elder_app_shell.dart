// ==============================================================================
// NIRVANA - ElderAppShell
// Description: Uncluttered, accessible application scaffold with large touch
// navigation bar (max 3 primary items), high contrast active states, and
// clear semantic announcements.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../theme/elder_theme.dart';

class ElderAppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ElderAppShell({super.key, required this.navigationShell});

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentIndex = navigationShell.currentIndex;

    final homeLabel = l10n?.homeNavLabel ?? 'Home';
    final activitiesLabel = l10n?.activitiesNavLabel ?? 'Activities';
    final settingsLabel = l10n?.settingsNavLabel ?? 'Settings';

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: ElderColors.border, width: 2.0),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                index: 0,
                isSelected: currentIndex == 0,
                icon: Icons.home_rounded,
                label: homeLabel,
                onTap: () => _onTap(0),
              ),
              _buildNavItem(
                context: context,
                index: 1,
                isSelected: currentIndex == 1,
                icon: Icons.extension_rounded,
                label: activitiesLabel,
                onTap: () => _onTap(1),
              ),
              if (navigationShell.route.branches.length > 2)
                _buildNavItem(
                  context: context,
                  index: 2,
                  isSelected: currentIndex == 2,
                  icon: Icons.settings_rounded,
                  label: settingsLabel,
                  onTap: () => _onTap(2),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required bool isSelected,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final activeBg = theme.colorScheme.primaryContainer;
    final activeFg = theme.colorScheme.onPrimaryContainer;
    final inactiveFg = ElderColors.textSecondary;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: '$label tab',
        child: Material(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(16.0),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16.0),
            child: Container(
              constraints: const BoxConstraints(minHeight: 64.0),
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 4.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 32.0,
                    color: isSelected ? activeFg : inactiveFg,
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isSelected ? activeFg : inactiveFg,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
