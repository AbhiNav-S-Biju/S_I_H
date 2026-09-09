// ==============================================================================
// NIRVANA - SettingsScreen
// Description: Senior-accessible settings screen with claymorphic cards, large
// touch toggles, text scale selection, and language preferences.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';

import '../../../app/providers/accessibility_providers.dart';
import '../../../app/theme/elder_theme.dart';
import '../../../app/widgets/widgets.dart';
import '../../../app/widgets/clay_3d/clay_3d.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final reducedMotion = ref.watch(reducedMotionProvider);
    final highContrast = ref.watch(highContrastProvider);
    final voiceEnabled = ref.watch(voiceEnabledProvider);
    final textScale = ref.watch(textScaleProvider);
    final currentLocale = ref.watch(localeProvider);

    String getLanguageName(String code) {
      switch (code) {
        case 'hi':
          return l10n?.hindi ?? 'हिन्दी (Hindi)';
        case 'as':
          return l10n?.assamese ?? 'অসমীয়া (Assamese)';
        case 'bn':
          return l10n?.bengali ?? 'বাংলা (Bengali)';
        case 'mni':
          return l10n?.manipuri ?? 'মৈতৈলোন্ (Manipuri / Meitei)';
        case 'kha':
          return l10n?.khasi ?? 'Ka Ktien Khasi (Khasi)';
        case 'lus':
          return l10n?.mizo ?? 'Mizo ṭawng (Mizo)';
        case 'ne':
          return l10n?.nepali ?? 'नेपाली (Nepali)';
        case 'en':
        default:
          return l10n?.english ?? 'English';
      }
    }

    return Scaffold(
      backgroundColor: ElderColors.backgroundClay,
      body: ClayBackdrop3D(
        child: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                children: [
                  LargeIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back to Home',
                    backgroundColor: ElderColors.surface,
                    iconColor: ElderColors.textPrimary,
                    size: 56.0,
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/patient/home');
                      }
                    },
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Text(
                      l10n?.settingsNavLabel ?? 'Settings',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: ElderColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Accessibility & Visual Comfort Section
                    SectionHeader(
                      title: l10n?.accessibilitySectionTitle ?? 'Visual & Motion Comfort',
                      icon: Icons.accessibility_new_rounded,
                    ),

                    // Reduced Motion Card
                    ElderCard(
                      padding: const EdgeInsets.all(20.0),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: reducedMotion,
                        activeColor: ElderColors.claySage,
                        activeTrackColor: ElderColors.claySage.withValues(alpha: 0.4),
                        title: Text(
                          l10n?.reducedMotionTitle ?? 'Reduced Motion',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: ElderColors.textPrimary,
                            fontSize: 19.0,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            l10n?.reducedMotionSubtitle ??
                                'Turns off moving effects and animations for a steadier screen.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: ElderColors.textSecondary,
                              fontSize: 15.0,
                            ),
                          ),
                        ),
                        onChanged: (val) {
                          ref.read(reducedMotionProvider.notifier).setReducedMotion(val);
                        },
                      ),
                    ),
                    const SizedBox(height: 14.0),

                    // High Contrast Card
                    ElderCard(
                      padding: const EdgeInsets.all(20.0),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: highContrast,
                        activeColor: ElderColors.clayLavender,
                        activeTrackColor: ElderColors.clayLavender.withValues(alpha: 0.4),
                        title: Text(
                          l10n?.highContrastTitle ?? 'High Contrast Mode',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: ElderColors.textPrimary,
                            fontSize: 19.0,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            l10n?.highContrastSubtitle ??
                                'Bolder text and stronger outlines for easier reading.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: ElderColors.textSecondary,
                              fontSize: 15.0,
                            ),
                          ),
                        ),
                        onChanged: (val) {
                          ref.read(highContrastProvider.notifier).setHighContrast(val);
                        },
                      ),
                    ),
                    const SizedBox(height: 14.0),

                    // Voice Guidance Card
                    ElderCard(
                      padding: const EdgeInsets.all(20.0),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: voiceEnabled,
                        activeColor: ElderColors.clayButtercup,
                        activeTrackColor: ElderColors.clayButtercup.withValues(alpha: 0.4),
                        title: Text(
                          'Voice Assistance & Prompts',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: ElderColors.textPrimary,
                            fontSize: 19.0,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            'Speaks instructions aloud and enables voice input for games and reminders.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: ElderColors.textSecondary,
                              fontSize: 15.0,
                            ),
                          ),
                        ),
                        onChanged: (val) {
                          ref.read(voiceEnabledProvider.notifier).setVoiceEnabled(val);
                        },
                      ),
                    ),
                    const SizedBox(height: 14.0),

                    // Text Scale Segmented Options
                    ElderCard(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.textSizeTitle ?? 'Text Size',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: ElderColors.textPrimary,
                              fontSize: 19.0,
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          Text(
                            l10n?.textSizeSubtitle ??
                                'Make words and numbers larger and clearer.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: ElderColors.textSecondary,
                              fontSize: 15.0,
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
                          const SizedBox(height: 10.0),
                          _buildScaleOption(
                            title: l10n?.textSizeExtraLarge ?? 'Extra Large',
                            isSelected: textScale == TextScaleOption.extraLarge,
                            onTap: () => ref
                                .read(textScaleProvider.notifier)
                                .setScale(TextScaleOption.extraLarge),
                          ),
                          const SizedBox(height: 10.0),
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

                    const SizedBox(height: 24.0),

                    // 2. Language Selector Section
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
                            padding: const EdgeInsets.all(14.0),
                            decoration: BoxDecoration(
                              color: ElderColors.clayLavender.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              boxShadow: NirvanaShadows.float(tint: ElderColors.clayLavender),
                            ),
                            child: const Icon(
                              Icons.translate_rounded,
                              size: 28.0,
                              color: ElderColors.clayLavender,
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
                                    color: ElderColors.clayLavender,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 20.0,
                            color: ElderColors.textMuted,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24.0),

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
                    const SizedBox(height: 32.0),
                  ],
                ),
              ),
            ),
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
      borderRadius: BorderRadius.circular(16.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minHeight: 56.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: isSelected ? ElderColors.clayLavender.withValues(alpha: 0.12) : ElderColors.surface,
          borderRadius: BorderRadius.circular(NirvanaRadii.button),
          border: Border.all(
            color: isSelected ? ElderColors.clayLavender : ElderColors.borderLight,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? NirvanaShadows.float(tint: ElderColors.clayLavender)
              : NirvanaShadows.card(),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected ? ElderColors.clayLavender : ElderColors.textMuted,
              size: 26.0,
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? ElderColors.textPrimary : ElderColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
