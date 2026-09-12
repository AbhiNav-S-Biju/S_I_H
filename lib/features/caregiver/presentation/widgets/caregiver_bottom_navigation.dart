import 'package:flutter/material.dart';
import 'package:nirvana/app/theme/elder_theme.dart';

class CaregiverBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const CaregiverBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const _items = [
    (Icons.home_rounded, 'Home'),
    (Icons.notifications_active_rounded, 'Alerts'),
    (Icons.alarm_rounded, 'Reminders'),
  ];

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final showLabels = textScale <= 1.4 && MediaQuery.sizeOf(context).width >= 320;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: ElderColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: ElderColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: ElderColors.clayLavender.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
            const BoxShadow(
              color: Colors.white,
              blurRadius: 5,
              offset: Offset(-2, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var index = 0; index < _items.length; index++)
              Expanded(
                child: _NavigationItem(
                  icon: _items[index].$1,
                  label: _items[index].$2,
                  selected: selectedIndex == index,
                  showLabel: showLabels,
                  onTap: () => onSelected(index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool showLabel;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.selected,
    this.showLabel = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? ElderColors.clayLavender
        : ElderColors.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: selected ? ElderColors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 26, color: foreground),
                  if (showLabel) ...[
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.w900 : FontWeight.w700,
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
