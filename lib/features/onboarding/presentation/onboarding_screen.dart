// ==============================================================================
// NIRVANA - OnboardingScreen
// Description: Gentle, dignified multi-step introduction for seniors with
// large typography, high touch areas, and optional motion comfort settings.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';

import '../../../app/providers/accessibility_providers.dart';
import '../../../app/theme/elder_theme.dart';
import '../../../app/widgets/widgets.dart';
import '../providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    final reducedMotion = ref.read(reducedMotionProvider);
    if (_currentStep < 2) {
      if (reducedMotion) {
        _pageController.jumpToPage(_currentStep + 1);
      } else {
        _pageController.animateToPage(
          _currentStep + 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      _finish();
    }
  }

  void _prevPage() {
    final reducedMotion = ref.read(reducedMotionProvider);
    if (_currentStep > 0) {
      if (reducedMotion) {
        _pageController.jumpToPage(_currentStep - 1);
      } else {
        _pageController.animateToPage(
          _currentStep - 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _finish() {
    ref.read(onboardingCompletedProvider.notifier).completeOnboarding();
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final stepTitles = [
      l10n?.onboardingStep1Title ?? 'A Gentle Companion',
      l10n?.onboardingStep2Title ?? 'Designed for Easy Reading',
      l10n?.onboardingStep3Title ?? 'Ready Whenever You Are',
    ];

    final stepBodies = [
      l10n?.onboardingStep1Body ??
          'Nirvana is here to help keep your mind active with simple, pleasant daily moments.',
      l10n?.onboardingStep2Body ??
          'Everything is sized generously with clear buttons and no confusing menus.',
      l10n?.onboardingStep3Body ??
          'Take things at your own pace. There are no timers or penalties here.',
    ];

    final stepIcons = [
      Icons.spa_rounded,
      Icons.visibility_rounded,
      Icons.sentiment_very_satisfied_rounded,
    ];

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
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 6.0,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  '${_currentStep + 1} / 3',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics:
                    const NeverScrollableScrollPhysics(), // Controlled via buttons
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                itemCount: 3,
                itemBuilder: (context, index) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16.0),
                        Container(
                          width: 100.0,
                          height: 100.0,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.primary,
                              width: 2.5,
                            ),
                          ),
                          child: Icon(
                            stepIcons[index],
                            size: 54.0,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 28.0),
                        Text(
                          stepTitles[index],
                          textAlign: TextAlign.center,
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: ElderColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 18.0),
                        Text(
                          stepBodies[index],
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: ElderColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24.0),
                        if (index == 1) ...[
                          // Quick accessibility toggles right on onboarding
                          ElderCard(
                            padding: const EdgeInsets.all(16.0),
                            child: Consumer(
                              builder: (context, ref, _) {
                                final isHighContrast = ref.watch(
                                  highContrastProvider,
                                );
                                return SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    l10n?.highContrastTitle ??
                                        'High Contrast Mode',
                                    style: const TextStyle(
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  value: isHighContrast,
                                  onChanged: (val) {
                                    ref
                                        .read(highContrastProvider.notifier)
                                        .setHighContrast(val);
                                  },
                                );
                              },
                            ),
                          ),
                        ] else if (index == 2) ...[
                          SupportiveMessage(
                            message:
                                l10n?.dailySupportiveMessage ??
                                'Take your time. There is no rush, and you are doing wonderful.',
                            icon: Icons.favorite_rounded,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            // Bottom Action Area (Maximum 2 buttons: Back & Next/Finish)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: ElderColors.border, width: 1.5),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LargeActionButton(
                    label: _currentStep == 2
                        ? (l10n?.onboardingFinishButton ?? 'Enter Nirvana')
                        : (l10n?.continueButton ?? 'Continue'),
                    onPressed: _nextPage,
                    icon: _currentStep == 2
                        ? Icons.check_circle_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(height: 12.0),
                    LargeActionButton(
                      label: l10n?.backButton ?? 'Back',
                      variant: LargeActionButtonVariant.secondary,
                      onPressed: _prevPage,
                      icon: Icons.arrow_back_rounded,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
