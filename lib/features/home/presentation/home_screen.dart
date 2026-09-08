// ==============================================================================
// NIRVANA - HomeScreen
// Description: Peaceful, uncluttered home screen for elderly users with 2-3
// primary actions, time-appropriate warm greeting, and supportive messaging.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';

import '../../../app/theme/elder_theme.dart';
import '../../../app/widgets/widgets.dart';
import '../../../core/widgets/voice_helper.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getTimeGreeting(BuildContext context, AppLocalizations? l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return l10n?.todayGreetingMorning ?? 'Good Morning';
    } else if (hour < 17) {
      return l10n?.todayGreetingAfternoon ?? 'Good Afternoon';
    } else {
      return l10n?.todayGreetingEvening ?? 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final greeting = _getTimeGreeting(context, l10n);
    final supportiveMsg = l10n?.dailySupportiveMessage ??
        'Take your time. There is no rush, and you are doing wonderful.';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n?.appName ?? 'NIRVANA',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            iconSize: 32.0,
            tooltip: l10n?.settingsNavLabel ?? 'Settings',
            icon: const Icon(
              Icons.settings_outlined,
              color: ElderColors.textPrimary,
            ),
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 8.0),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Warm Greeting & Supportive Reassurance
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      greeting,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: ElderColors.textPrimary,
                      ),
                    ),
                  ),
                  SpeakButton(
                    text: '$greeting. $supportiveMsg',
                    size: 40.0,
                  ),
                ],
              ),
              const SizedBox(height: 6.0),
              Text(
                l10n?.welcomeSubtitle ??
                    'A calm space designed for your comfort and memory.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: ElderColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16.0),
              SupportiveMessage(
                message:
                    l10n?.dailySupportiveMessage ??
                    'Take your time. There is no rush, and you are doing wonderful.',
                icon: Icons.spa_rounded,
              ),
              const SizedBox(height: 18.0),

              // 2. Primary Action 1: Daily Activities (Games)
              ElderCard(
                padding: const EdgeInsets.all(22.0),
                backgroundColor: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.35,
                ),
                borderColor: theme.colorScheme.primary,
                borderWidth: 2.5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.extension_rounded,
                            color: Colors.white,
                            size: 32.0,
                          ),
                        ),
                        const SizedBox(width: 14.0),
                        Expanded(
                          child: Text(
                            l10n?.dailyActivitiesCardTitle ??
                                "Today's Activities",
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: ElderColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      l10n?.dailyActivitiesCardSubtitle ??
                          'Gentle memory and recognition games made for you.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: ElderColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    LargeActionButton(
                      label: l10n?.startActivitiesButton ?? 'Start Activities',
                      icon: Icons.play_arrow_rounded,
                      onPressed: () => context.go('/games'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),

              // 3. Primary Action 2: Settings & Visual Comfort
              ElderCard(
                padding: const EdgeInsets.all(22.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: ElderColors.surfaceElevated,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: ElderColors.border,
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: ElderColors.textPrimary,
                            size: 32.0,
                          ),
                        ),
                        const SizedBox(width: 14.0),
                        Expanded(
                          child: Text(
                            l10n?.settingsTitle ?? 'App Settings & Comfort',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: ElderColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      l10n?.settingsSubtitle ??
                          'Adjust text size, contrast, or language anytime.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: ElderColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    LargeActionButton(
                      label: l10n?.settingsNavLabel ?? 'Open Settings',
                      variant: LargeActionButtonVariant.secondary,
                      icon: Icons.settings_rounded,
                      onPressed: () => context.push('/settings'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),

              // 4. Secondary Portal Entry: Caregiver Portal
              Center(
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: ElderColors.textSecondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 10.0,
                    ),
                  ),
                  icon: const Icon(Icons.family_restroom_rounded, size: 20.0),
                  label: const Text(
                    'Caregiver Portal',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => context.push('/caregiver/login'),
                ),
              ),
              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }
}
