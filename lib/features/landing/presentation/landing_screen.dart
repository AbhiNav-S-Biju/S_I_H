// ==============================================================================
// NIRVANA - Landing Screen / Portal Selection (3D Claymorphism)
// Description: Tactile, soothing 3D claymorphic landing page allowing users to choose
// between Patient Portal and Caregiver Portal with volumetric lighting & floating elements.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/widgets/clay_3d/clay_3d.dart';
import '../../../database/hive_database.dart';
import '../../../features/caregiver/caregiver.dart';
import '../../../l10n/app_localizations.dart';

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return ClayScaffold3D(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12.0),

          // 3D Floating Spa Emblem
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: Clay3DTheme.lavenderLight.withValues(alpha: 0.70),
                    shape: BoxShape.circle,
                    boxShadow: Clay3DTheme.deepShadow(blur: 16, offset: 6),
                  ),
                ),
                const Icon(
                  Icons.spa_rounded,
                  size: 46,
                  color: Color(0xFF6B58A0),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16.0),

          // App Name Pill / Title
          ClaySlab3D(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            borderRadius: 20,
            child: Text(
              'NIRVANA',
              style: GoogleFonts.nunito(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 3.0,
                color: Clay3DTheme.lavenderDeep,
              ),
            ),
          ),

          const SizedBox(height: 12.0),

          // Welcome Title
          Text(
            l10n?.landingWelcomeTitle ?? 'Welcome to NIRVANA',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Clay3DTheme.textDark,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 6.0),

          // Subtitle
          Text(
            l10n?.landingSubtitle ??
                'Choose how you would like to continue today.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 15,
              color: Clay3DTheme.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 28.0),

          // ──────────────────────────────────────────────────────────────
          // 1. Patient Portal 3D Card
          // ──────────────────────────────────────────────────────────────
          _ClayPortalCard3D(
            tag: 'SENIOR FRIENDLY',
            tagBgColor: Clay3DTheme.lavender,
            icon: Icons.favorite_rounded,
            iconColor: const Color(0xFF635198),
            iconBgColor: Clay3DTheme.lavenderLight,
            title: l10n?.patientPortalTitle ?? 'Patient Portal',
            subtitle: l10n?.patientPortalSubtitle ?? 'For patients & loved ones',
            description: l10n?.patientPortalDescription ??
                'Access your daily activities, reminders, games and family moments.',
            buttonLabel: l10n?.patientPortalButton ?? 'Enter Patient Portal',
            buttonColor: Clay3DTheme.lavender,
            onPressed: () {
              if (HiveDatabase.isDevicePaired) {
                context.go('/patient/home');
              } else {
                context.go('/patient/welcome');
              }
            },
          ),

          const SizedBox(height: 22.0),

          // ──────────────────────────────────────────────────────────────
          // 2. Caregiver Portal 3D Card
          // ──────────────────────────────────────────────────────────────
          _ClayPortalCard3D(
            tag: 'CAREGIVER HUB',
            tagBgColor: Clay3DTheme.teal,
            icon: Icons.admin_panel_settings_rounded,
            iconColor: const Color(0xFF286D6D),
            iconBgColor: Clay3DTheme.tealLight,
            title: l10n?.caregiverPortalTitle ?? 'Caregiver Portal',
            subtitle: l10n?.caregiverPortalSubtitle ?? 'For family & care providers',
            description: l10n?.caregiverPortalDescription ??
                'Manage routines, monitor activity, adjust settings, and pair devices.',
            buttonLabel: l10n?.caregiverPortalButton ?? 'Enter Caregiver Portal',
            buttonColor: Clay3DTheme.teal,
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
    );
  }
}

// ==============================================================================
// 3D Claymorphic Portal Selection Card
// ==============================================================================
class _ClayPortalCard3D extends StatelessWidget {
  final String tag;
  final Color tagBgColor;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final String description;
  final String buttonLabel;
  final Color buttonColor;
  final VoidCallback onPressed;

  const _ClayPortalCard3D({
    required this.tag,
    required this.tagBgColor,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.buttonLabel,
    required this.buttonColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ClayCard3D(
      padding: const EdgeInsets.all(22.0),
      borderRadius: 26.0,
      customShadows: Clay3DTheme.deepShadow(blur: 18, offset: 8),
      onTap: onPressed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 3D Circular Icon Token
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                  boxShadow: Clay3DTheme.cardShadow(blur: 10, offset: 4),
                ),
                child: Center(
                  child: Icon(icon, size: 28, color: iconColor),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClayPill3D(
                      color: tagBgColor.withValues(alpha: 0.85),
                      child: Text(
                        tag,
                        style: GoogleFonts.nunito(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: Clay3DTheme.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: GoogleFonts.nunito(
                        fontSize: 20.0,
                        fontWeight: FontWeight.w900,
                        color: Clay3DTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12.0),

          Text(
            description,
            style: GoogleFonts.nunito(
              fontSize: 14.5,
              color: Clay3DTheme.textMuted,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 18.0),

          ClayButton3D(
            label: buttonLabel,
            icon: Icons.arrow_forward_rounded,
            color: buttonColor,
            minHeight: 52,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}
