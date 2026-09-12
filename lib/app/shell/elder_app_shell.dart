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

    // Hide the text label under each icon when the font scale is very large or
    // the screen is very narrow, so the bar never overflows.
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final width = MediaQuery.sizeOf(context).width;
    final showLabels = textScale <= 1.4 && width >= 320;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: ElderColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(NirvanaRadii.sheet),
            topRight: Radius.circular(NirvanaRadii.sheet),
          ),
          boxShadow: NirvanaShadows.card(),
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
                showLabel: showLabels,
                onTap: () => _onTap(0),
              ),
              _buildNavItem(
                context: context,
                index: 1,
                isSelected: currentIndex == 1,
                icon: Icons.extension_rounded,
                label: activitiesLabel,
                showLabel: showLabels,
                onTap: () => _onTap(1),
              ),
              if (navigationShell.route.branches.length > 2)
                _buildNavItem(
                  context: context,
                  index: 2,
                  isSelected: currentIndex == 2,
                  icon: Icons.settings_rounded,
                  label: settingsLabel,
                  showLabel: showLabels,
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
    required bool showLabel,
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
          borderRadius: BorderRadius.circular(NirvanaRadii.button),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(NirvanaRadii.button),
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
                  if (showLabel) ...[
                    const SizedBox(height: 4.0),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isSelected ? activeFg : inactiveFg,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
