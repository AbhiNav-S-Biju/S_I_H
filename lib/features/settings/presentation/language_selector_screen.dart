// ==============================================================================
// NIRVANA - LanguageSelectorScreen
// Description: Accessible, claymorphic language picker with native script
// names and large touch surfaces for seniors.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';

import '../../../app/providers/accessibility_providers.dart';
import '../../../app/theme/elder_theme.dart';
import '../../../app/widgets/widgets.dart';
import '../../../app/widgets/clay_3d/clay_3d.dart';

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
              const Icon(Icons.schedule_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${item['title']} is coming soon! Not available yet.',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFE08244),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          duration: const Duration(seconds: 3),
        ),
      );

      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: ElderColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ElderColors.clayPeach.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: Color(0xFFC2410C),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Coming Soon',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: ElderColors.textPrimary,
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
                  fontWeight: FontWeight.w800,
                  color: ElderColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Voice and full language support for this language is currently in development and will be available in an upcoming update.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: ElderColors.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            LargeActionButton(
              label: 'OK',
              icon: Icons.check_circle_outline_rounded,
              colorScheme: ElderButtonScheme.primary,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: ElderColors.backgroundClay,
      body: ClayBackdrop3D(
        child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                children: [
                  LargeIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back to Settings',
                    backgroundColor: Colors.white,
                    iconColor: ElderColors.textPrimary,
                    size: 56.0,
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/settings');
                      }
                    },
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Text(
                      l10n?.selectLanguageTitle ?? 'Choose Language',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: ElderColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 6.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n?.selectLanguageSubtitle ??
                      'Tap the language you feel most comfortable using.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: ElderColors.textSecondary,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12.0),

            // Languages List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                itemCount: languages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12.0),
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
                        ? ElderColors.backgroundAlt
                        : isSelected
                            ? ElderColors.clayLavender.withValues(alpha: 0.18)
                            : ElderColors.surface,
                    borderColor: isUnsupported
                        ? ElderColors.border
                        : isSelected
                            ? ElderColors.clayLavender
                            : ElderColors.border,
                    borderWidth: isSelected ? 3.0 : 1.5,
                    onTap: () {
                      if (isUnsupported) {
                        showComingSoonNotice(context, item);
                        return;
                      }
                      ref.read(localeProvider.notifier).setLanguageCode(code);
                    },
                    semanticLabel:
                        '${item['native']} - ${item['title']}${isUnsupported ? ' (Coming Soon)' : ''}',
                    child: Row(
                      children: [
                        Icon(
                          isUnsupported
                              ? Icons.schedule_rounded
                              : isSelected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                          size: 30.0,
                          color: isUnsupported
                              ? ElderColors.textMuted
                              : isSelected
                                  ? ElderColors.clayLavender
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
                                  fontSize: 22.0,
                                  fontWeight: FontWeight.w800,
                                  color: isUnsupported
                                      ? ElderColors.textMuted
                                      : ElderColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2.0),
                              Text(
                                item['title']!,
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w500,
                                  color: isUnsupported
                                      ? ElderColors.textMuted
                                      : isSelected
                                          ? ElderColors.clayLavender
                                          : ElderColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isUnsupported)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10.0,
                              vertical: 4.0,
                            ),
                            decoration: BoxDecoration(
                              color: ElderColors.backgroundAlt,
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: const Text(
                              'Soon',
                              style: TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w700,
                                color: ElderColors.textMuted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
