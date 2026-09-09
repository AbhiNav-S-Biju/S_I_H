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

    final unsupportedCodes = {'mni', 'kha', 'lus'};

    final languages = [
      {'code': 'en', 'title': 'English', 'native': 'English'},
      {'code': 'hi', 'title': 'Hindi', 'native': 'हिन्दी'},
      {'code': 'as', 'title': 'Assamese', 'native': 'অসমীয়া'},
      {'code': 'bn', 'title': 'Bengali', 'native': 'বাংলা'},
      {'code': 'mni', 'title': 'Manipuri / Meitei', 'native': 'মৈতৈলোন্'},
      {'code': 'kha', 'title': 'Khasi', 'native': 'Ka Ktien Khasi'},
      {'code': 'lus', 'title': 'Mizo', 'native': 'Mizo ṭawng'},
      {'code': 'ne', 'title': 'Nepali', 'native': 'नेपाली'},
    ];

    void showComingSoonNotice(BuildContext context, Map<String, String> item) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${item['title']} is coming soon! Not available yet.',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFD97706),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );

      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF3E0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: Color(0xFFE65100),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Coming Soon',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item['native']} (${item['title']})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Voice and full language support for this language is currently in development and will be available in an upcoming update.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

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
                    final isUnsupported = unsupportedCodes.contains(code);
                    final isSelected = !isUnsupported && activeLocale.languageCode == code;

                    return ElderCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 18.0,
                      ),
                      backgroundColor: isUnsupported
                          ? const Color(0xFFF8FAFC)
                          : isSelected
                              ? ElderColors.primaryContainer
                              : Colors.white,
                      borderColor: isUnsupported
                          ? const Color(0xFFCBD5E1)
                          : isSelected
                              ? theme.colorScheme.primary
                              : ElderColors.border,
                      borderWidth: isSelected ? 3.0 : 2.0,
                      onTap: () {
                        if (isUnsupported) {
                          showComingSoonNotice(context, item);
                          return;
                        }
                        ref.read(localeProvider.notifier).setLanguageCode(code);
                      },
                      semanticLabel: '${item['native']} - ${item['title']}${isUnsupported ? ' (Coming Soon)' : ''}',
                      child: Row(
                        children: [
                          Icon(
                            isUnsupported
                                ? Icons.schedule_rounded
                                : isSelected
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_off_rounded,
                            size: 32.0,
                            color: isUnsupported
                                ? const Color(0xFF94A3B8)
                                : isSelected
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
                                    color: isUnsupported
                                        ? const Color(0xFF64748B)
                                        : isSelected
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
                                    color: isUnsupported
                                        ? const Color(0xFF94A3B8)
                                        : isSelected
                                            ? ElderColors.onPrimaryContainer
                                            : ElderColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isUnsupported)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFF59E0B),
                                  width: 1.2,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 14,
                                    color: Color(0xFFB45309),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Coming Soon',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFB45309),
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
