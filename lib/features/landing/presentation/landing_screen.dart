// ==============================================================================
// NIRVANA - Landing Screen / Portal Selection
// Description: Accessible, claymorphic landing page allowing users to choose
// between Patient Portal and Caregiver Portal with calm wellness aesthetics.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/elder_theme.dart';
import '../../../app/widgets/widgets.dart';
import '../../../database/hive_database.dart';
import '../../../features/caregiver/caregiver.dart';
import '../../../l10n/app_localizations.dart';

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: ElderColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16.0),

              // Calming App Icon / Brand Emblem
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: ElderColors.primaryContainer,
                  shape: BoxShape.circle,
                  boxShadow: NirvanaShadows.float(tint: ElderColors.primary),
                ),
                child: const Center(
                  child: Icon(
                    Icons.spa_rounded,
                    size: 48,
                    color: ElderColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 20.0),

              // App Name & Tagline
              Text(
                'NIRVANA',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: ElderColors.primary,
                ),
              ),

              const SizedBox(height: 8.0),

              // Welcome Title
              Text(
                l10n?.landingWelcomeTitle ?? 'Welcome to NIRVANA',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: ElderColors.textPrimary,
                ),
              ),

              const SizedBox(height: 6.0),

              // Subtitle
              Text(
                l10n?.landingSubtitle ??
                    'Choose how you would like to continue today.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: ElderColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 32.0),

              // ──────────────────────────────────────────────────────────────
              // Patient Portal Card (Pastel Lavender Theme)
              // ──────────────────────────────────────────────────────────────
              _ClayPortalCard(
                tag: 'SENIOR FRIENDLY',
                tagColor: ElderColors.primary,
                tagBgColor: ElderColors.pastelLavender,
                cardBgColor: Colors.white,
                icon: Icons.favorite_rounded,
                iconColor: ElderColors.primary,
                iconBgColor: ElderColors.pastelLavender,
                title: l10n?.patientPortalTitle ?? 'Patient Portal',
                subtitle:
                    l10n?.patientPortalSubtitle ?? 'For patients & loved ones',
                description: l10n?.patientPortalDescription ??
                    'Access your daily activities, reminders, games and family moments.',
                buttonLabel:
                    l10n?.patientPortalButton ?? 'Enter Patient Portal',
                buttonVariant: LargeActionButtonVariant.primary,
                onPressed: () {
                  if (HiveDatabase.isDevicePaired) {
                    context.go('/patient/home');
                  } else {
                    context.go('/patient/welcome');
                  }
                },
              ),

              const SizedBox(height: 24.0),

              // ──────────────────────────────────────────────────────────────
              // Caregiver Portal Card (Pastel Sage Theme)
              // ──────────────────────────────────────────────────────────────
              _ClayPortalCard(
                tag: 'CAREGIVER HUB',
                tagColor: ElderColors.forestDeep,
                tagBgColor: ElderColors.pastelSage,
                cardBgColor: Colors.white,
                icon: Icons.admin_panel_settings_rounded,
                iconColor: ElderColors.forestDeep,
                iconBgColor: ElderColors.pastelSage,
                title: l10n?.caregiverPortalTitle ?? 'Caregiver Portal',
                subtitle:
                    l10n?.caregiverPortalSubtitle ?? 'For family & care providers',
                description: l10n?.caregiverPortalDescription ??
                    'Manage routines, monitor activity, adjust settings, and pair devices.',
                buttonLabel:
                    l10n?.caregiverPortalButton ?? 'Enter Caregiver Portal',
                buttonVariant: LargeActionButtonVariant.sage,
                onPressed: () {
                  final authState = ref.read(caregiverAuthProvider);
                  if (authState.value != null) {
                    context.go('/caregiver/dashboard');
                  } else {
                    context.go('/caregiver/login');
                  }
                },
              ),

              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }
}

// ==============================================================================
// Claymorphic Portal Selection Card
// ==============================================================================

class _ClayPortalCard extends StatelessWidget {
  final String tag;
  final Color tagColor;
  final Color tagBgColor;
  final Color cardBgColor;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final String description;
  final String buttonLabel;
  final LargeActionButtonVariant buttonVariant;
  final VoidCallback onPressed;

  const _ClayPortalCard({
    required this.tag,
    required this.tagColor,
    required this.tagBgColor,
    required this.cardBgColor,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.buttonLabel,
    required this.buttonVariant,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ElderCard(
      padding: EdgeInsets.zero,
      backgroundColor: cardBgColor,
      semanticLabel: '$title — $subtitle',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(ElderTheme.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge & Icon Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.0),
                      boxShadow: ElderColors.clayShadow(color: iconBgColor),
                    ),
                    child: Icon(icon, size: 30, color: iconColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10.0,
                            vertical: 3.0,
                          ),
                          decoration: BoxDecoration(
                            color: tagBgColor,
                            borderRadius: BorderRadius.circular(NirvanaRadii.pill),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: tagColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: ElderColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14.0),

              // Description
              Text(
                description,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: ElderColors.textSecondary,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20.0),

              // CTA Button
              SizedBox(
                width: double.infinity,
                child: LargeActionButton(
                  label: buttonLabel,
                  variant: buttonVariant,
                  icon: Icons.arrow_forward_rounded,
                  onPressed: onPressed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

