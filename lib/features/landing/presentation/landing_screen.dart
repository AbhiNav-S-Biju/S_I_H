// ==============================================================================
// NIRVANA - Landing Screen / Portal Selection
// Description: Accessible landing page allowing users to choose between
// Patient Portal and Caregiver Portal. Checks local pairing state and
// caregiver auth session to route to the correct destination.
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
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24.0),

              // App Icon / Logo Area
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ElderColors.primary,
                      ElderColors.primary.withAlpha(180),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: ElderColors.primary.withAlpha(50),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.spa_rounded,
                  size: 44,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 24.0),

              // Welcome Title
              Text(
                l10n?.landingWelcomeTitle ?? 'Welcome to NIRVANA',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: ElderColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8.0),

              // Subtitle
              Text(
                l10n?.landingSubtitle ??
                    'Choose how you would like to continue.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: ElderColors.textSecondary,
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 40.0),

              // ──────────────────────────────────────────────────────────────
              // Patient Portal Card
              // ──────────────────────────────────────────────────────────────
              _PortalCard(
                icon: Icons.favorite_rounded,
                iconColor: const Color(0xFF7C3AED),
                iconBgColor: const Color(0xFFEDE9FE),
                title: l10n?.patientPortalTitle ?? 'Patient Portal',
                subtitle:
                    l10n?.patientPortalSubtitle ?? 'For patients and loved ones',
                description: l10n?.patientPortalDescription ??
                    'Access your daily activities, reminders and family connections.',
                buttonLabel:
                    l10n?.patientPortalButton ?? 'Enter Patient Portal',
                onPressed: () {
                  if (HiveDatabase.isDevicePaired) {
                    context.go('/patient/home');
                  } else {
                    context.go('/patient/welcome');
                  }
                },
              ),

              const SizedBox(height: 20.0),

              // ──────────────────────────────────────────────────────────────
              // Caregiver Portal Card
              // ──────────────────────────────────────────────────────────────
              _PortalCard(
                icon: Icons.admin_panel_settings_rounded,
                iconColor: const Color(0xFF0369A1),
                iconBgColor: const Color(0xFFE0F2FE),
                title: l10n?.caregiverPortalTitle ?? 'Caregiver Portal',
                subtitle:
                    l10n?.caregiverPortalSubtitle ?? 'For caregivers',
                description: l10n?.caregiverPortalDescription ??
                    'Manage patients, reminders, activities and caregiver information.',
                buttonLabel:
                    l10n?.caregiverPortalButton ?? 'Enter Caregiver Portal',
                onPressed: () {
                  final authState = ref.read(caregiverAuthProvider);
                  if (authState.value != null) {
                    context.go('/caregiver/dashboard');
                  } else {
                    context.go('/caregiver/login');
                  }
                },
              ),

              const SizedBox(height: 32.0),
            ],
          ),
        ),
      ),
    );
  }
}

// ==============================================================================
// Portal Card — large, accessible card with icon, description, and CTA button
// ==============================================================================

class _PortalCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final String description;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _PortalCard({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ElderCard(
      padding: EdgeInsets.zero,
      semanticLabel: '$title — $subtitle',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon + Title Row
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, size: 30, color: iconColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: ElderColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: ElderColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16.0),

              // Description
              Text(
                description,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: ElderColors.textSecondary,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 20.0),

              // CTA Button
              SizedBox(
                width: double.infinity,
                child: LargeActionButton(
                  label: buttonLabel,
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
