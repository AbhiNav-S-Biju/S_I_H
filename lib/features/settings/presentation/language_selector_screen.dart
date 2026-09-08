// ==============================================================================
// NIRVANA - LanguageSelectorScreen
// Description: Accessible, high-contrast language picker with native script
// names and large touch surfaces for seniors.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';

import '../../../app/providers/accessibility_providers.dart';
import '../../../app/theme/elder_theme.dart';
import '../../../app/widgets/widgets.dart';

class LanguageSelectorScreen extends ConsumerWidget {
  const LanguageSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final activeLocale = ref.watch(localeProvider);

    final languages = [
      {'code': 'en', 'title': 'English', 'native': 'English'},
      {'code': 'es', 'title': 'Spanish', 'native': 'Español'},
      {'code': 'hi', 'title': 'Hindi', 'native': 'हिन्दी'},
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n?.selectLanguageTitle ?? 'Choose Your Language',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n?.selectLanguageSubtitle ??
                    'Tap the language you feel most comfortable using.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: ElderColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24.0),
              Expanded(
                child: ListView.separated(
                  itemCount: languages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14.0),
                  itemBuilder: (context, index) {
                    final item = languages[index];
                    final code = item['code']!;
                    final isSelected = activeLocale.languageCode == code;

                    return ElderCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 18.0,
                      ),
                      backgroundColor: isSelected
                          ? ElderColors.primaryContainer
                          : Colors.white,
                      borderColor: isSelected
                          ? theme.colorScheme.primary
                          : ElderColors.border,
                      borderWidth: isSelected ? 3.0 : 2.0,
                      onTap: () {
                        ref.read(localeProvider.notifier).setLanguageCode(code);
                      },
                      semanticLabel: '${item['native']} - ${item['title']}',
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            size: 32.0,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : ElderColors.textMuted,
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['native']!,
                                  style: TextStyle(
                                    fontSize: 24.0,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? ElderColors.onPrimaryContainer
                                        : ElderColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  item['title']!,
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? ElderColors.onPrimaryContainer
                                        : ElderColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle_rounded,
                              size: 32.0,
                              color: theme.colorScheme.primary,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16.0),
              LargeActionButton(
                label: l10n?.saveAndApply ?? 'Apply Selection',
                onPressed: () => context.pop(),
                icon: Icons.check_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
