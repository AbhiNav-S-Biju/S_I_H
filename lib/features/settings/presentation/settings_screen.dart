// ==============================================================================
// NIRVANA - SettingsScreen
// Description: Senior-accessible settings screen with large switches, high
// contrast toggles, reduced motion controls, and language preferences.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';

import '../../../app/providers/accessibility_providers.dart';
import '../../../app/theme/elder_theme.dart';
import '../../../app/widgets/widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final reducedMotion = ref.watch(reducedMotionProvider);
    final highContrast = ref.watch(highContrastProvider);
    final textScale = ref.watch(textScaleProvider);
    final currentLocale = ref.watch(localeProvider);

    String getLanguageName(String code) {
      switch (code) {
        case 'es':
          return l10n?.spanish ?? 'Español';
        case 'hi':
          return l10n?.hindi ?? 'हिन्दी (Hindi)';
        case 'en':
        default:
          return l10n?.english ?? 'English';
      }
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n?.settingsNavLabel ?? 'Settings',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Accessibility & Visual Comfort Section
              SectionHeader(
                title:
                    l10n?.accessibilitySectionTitle ??
                    'Visual & Motion Comfort',
                icon: Icons.accessibility_new_rounded,
              ),

              // Reduced Motion Card
              ElderCard(
                padding: const EdgeInsets.all(18.0),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: reducedMotion,
                  activeColor: theme.colorScheme.primary,
                  title: Text(
                    l10n?.reducedMotionTitle ?? 'Reduced Motion',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: ElderColors.textPrimary,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      l10n?.reducedMotionSubtitle ??
                          'Turns off moving effects and animations for a steadier screen.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: ElderColors.textSecondary,
                      ),
                    ),
                  ),
                  onChanged: (val) {
                    ref
                        .read(reducedMotionProvider.notifier)
                        .setReducedMotion(val);
                  },
                ),
              ),

              // High Contrast Card
              ElderCard(
                padding: const EdgeInsets.all(18.0),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: highContrast,
                  activeColor: theme.colorScheme.primary,
                  title: Text(
                    l10n?.highContrastTitle ?? 'High Contrast Mode',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: ElderColors.textPrimary,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      l10n?.highContrastSubtitle ??
                          'Bolder text and stronger outlines for easier reading.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: ElderColors.textSecondary,
                      ),
                    ),
                  ),
                  onChanged: (val) {
                    ref
                        .read(highContrastProvider.notifier)
                        .setHighContrast(val);
                  },
                ),
              ),

              // Text Scale Segmented Options
              ElderCard(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.textSizeTitle ?? 'Text Size',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: ElderColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      l10n?.textSizeSubtitle ??
                          'Make words and numbers larger and clearer.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: ElderColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    _buildScaleOption(
                      title: l10n?.textSizeStandard ?? 'Large (Standard)',
                      isSelected: textScale == TextScaleOption.standard,
                      onTap: () => ref
                          .read(textScaleProvider.notifier)
                          .setScale(TextScaleOption.standard),
                    ),
                    const SizedBox(height: 8.0),
                    _buildScaleOption(
                      title: l10n?.textSizeExtraLarge ?? 'Extra Large',
                      isSelected: textScale == TextScaleOption.extraLarge,
                      onTap: () => ref
                          .read(textScaleProvider.notifier)
                          .setScale(TextScaleOption.extraLarge),
                    ),
                    const SizedBox(height: 8.0),
                    _buildScaleOption(
                      title: l10n?.textSizeMaximum ?? 'Maximum Clarity',
                      isSelected: textScale == TextScaleOption.maximum,
                      onTap: () => ref
                          .read(textScaleProvider.notifier)
                          .setScale(TextScaleOption.maximum),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16.0),

              // 2. Language Selector Tile
              SectionHeader(
                title: l10n?.languageTitle ?? 'Language',
                icon: Icons.language_rounded,
              ),
              ElderCard(
                padding: const EdgeInsets.all(20.0),
                onTap: () => context.push('/settings/language'),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: const BoxDecoration(
                        color: ElderColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.translate_rounded,
                        size: 30.0,
                        color: ElderColors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.selectLanguageTitle ?? 'Choose Your Language',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: ElderColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            getLanguageName(currentLocale.languageCode),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 24.0,
                      color: ElderColors.textMuted,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16.0),

              // 3. About Section
              ElderCard(
                padding: const EdgeInsets.all(20.0),
                backgroundColor: ElderColors.surfaceElevated,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.aboutAppTitle ?? 'About Nirvana',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: ElderColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      l10n?.aboutAppVersion ??
                          'Version 1.0.0 • Compassionate Cognitive Care',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: ElderColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScaleOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56.0),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isSelected ? ElderColors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected ? ElderColors.primary : ElderColors.border,
            width: isSelected ? 2.5 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected ? ElderColors.primary : ElderColors.textMuted,
              size: 28.0,
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? ElderColors.onPrimaryContainer
                      : ElderColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
