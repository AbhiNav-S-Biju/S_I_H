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
import '../../../database/hive_database.dart';
import '../../../app/theme/nirvana_responsive.dart';
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
  Widget build(BuildContext context, WidgetRef ref) => _ClayHomeContent(
    greeting: _getTimeGreeting(context, AppLocalizations.of(context)),
    supportiveMessage:
        AppLocalizations.of(context)?.dailySupportiveMessage ??
        'Take your time. There is no rush, and you are doing wonderful.',
  );

  // Kept as a rollback reference while the new claymorphic home is verified.
  // ignore: unused_element
  Widget _buildLegacy(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final greeting = _getTimeGreeting(context, l10n);
    final supportiveMsg =
        l10n?.dailySupportiveMessage ??
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
                  SpeakButton(text: '$greeting. $supportiveMsg', size: 40.0),
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

              // 2. Primary Action: Ask NIRVANA Voice Assistant
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
                            Icons.mic_rounded,
                            color: Colors.white,
                            size: 32.0,
                          ),
                        ),
                        const SizedBox(width: 14.0),
                        Expanded(
                          child: Text(
                            'Ask NIRVANA',
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
                      'Talk with your voice anytime. Ask questions, hear stories, or just chat.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: ElderColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    LargeActionButton(
                      label: 'Talk with NIRVANA',
                      icon: Icons.record_voice_over_rounded,
                      onPressed: () => context.push('/ask-nirvana'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),

              // 3. Primary Action 2: Daily Activities (Games)
              ElderCard(
                padding: const EdgeInsets.all(22.0),
                backgroundColor: ElderColors.surface,
                borderColor: ElderColors.border,
                borderWidth: 2.0,
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

class _ClayHomeContent extends StatelessWidget {
  const _ClayHomeContent({
    required this.greeting,
    required this.supportiveMessage,
  });

  final String greeting;
  final String supportiveMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: _clayCanvasColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 500 ? 16.0 : 28.0;
            final columns = constraints.maxWidth < 340 ? 1 : 2;
            final tileWidth = NirvanaLayout.gridChildWidth(
              maxWidth: constraints.maxWidth - (horizontalPadding * 2),
              columns: columns,
              spacing: 16.0,
            );

            return Stack(
              children: [
                const _ClayBackground(),
                SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    16,
                    horizontalPadding,
                    36,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ClayGreeting(
                        greeting: greeting,
                        supportiveMessage: supportiveMessage,
                      ),
                      const SizedBox(height: 20),
                      _ClayMoment(onTap: () => context.push('/ask-nirvana')),
                      const SizedBox(height: 22),
                      _ClaySectionTitle(
                        title:
                            l10n?.whatWouldYouLikeToDo ??
                            'What would you like to do?',
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _ClayActionTile(
                            width: tileWidth,
                            icon: Icons.extension_rounded,
                            color: ElderColors.clayLavender,
                            tagColor: ElderColors.primaryLight,
                            tag: l10n?.dailyTag ?? 'DAILY',
                            label:
                                l10n?.dailyActivitiesCardTitle ??
                                'Memory Games',
                            onTap: () => context.go('/games'),
                          ),
                          _ClayActionTile(
                            width: tileWidth,
                            icon: Icons.schedule_rounded,
                            color: ElderColors.claySky,
                            tagColor: ElderColors.pastelSky,
                            tag: l10n?.routinesTag ?? 'ROUTINES',
                            label: l10n?.myRemindersLabel ?? 'My Reminders',
                            onTap: () => context.push('/patient/reminders'),
                          ),
                          _ClayActionTile(
                            width: tileWidth,
                            icon: Icons.person_rounded,
                            color: ElderColors.clayPeach,
                            tagColor: ElderColors.pastelPeach,
                            tag: l10n?.memoriesTag ?? 'MEMORIES',
                            label: l10n?.familyPhotosTitle ?? 'Family Photos',
                            onTap: () => context.push('/patient/family-photos'),
                          ),
                          _ClayActionTile(
                            width: tileWidth,
                            icon: Icons.settings_rounded,
                            color: ElderColors.clayButtercup,
                            tagColor: ElderColors.pastelButtercup,
                            tag: l10n?.preferencesTag ?? 'PREFERENCES',
                            label: l10n?.settingsNavLabel ?? 'Settings',
                            onTap: () => context.push('/settings'),
                          ),
                          _ClayActionTile(
                            width: tileWidth,
                            icon: Icons.chat_bubble_rounded,
                            color: ElderColors.clayLavender,
                            tagColor: ElderColors.primaryLight,
                            tag: l10n?.talkTag ?? 'TALK',
                            label: l10n?.askNirvanaTitle ?? 'Ask NIRVANA',
                            onTap: () => context.push('/ask-nirvana'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: TextButton.icon(
                          onPressed: () => context.push('/caregiver/login'),
                          icon: const Icon(Icons.family_restroom_rounded),
                          label: Text(
                            l10n?.caregiverPortalTitle ?? 'Caregiver Portal',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

const _clayCanvasColor = Color(0xFFF3EFE6);

List<BoxShadow> _claySurfaceShadows({Color tint = Colors.black}) => [
  BoxShadow(
    color: tint.withValues(alpha: 0.105),
    offset: const Offset(8, 8),
    blurRadius: 18,
    spreadRadius: 1,
  ),
  BoxShadow(
    color: Colors.white.withValues(alpha: 0.9),
    offset: const Offset(-8, -8),
    blurRadius: 18,
    spreadRadius: 1,
  ),
];

List<BoxShadow> _clayInsetShadows(Color color) => [
  BoxShadow(
    color: Color.lerp(color, Colors.black, 0.34)!.withValues(alpha: 0.26),
    offset: const Offset(2, 3),
    blurRadius: 4,
    spreadRadius: -1,
  ),
  BoxShadow(
    color: Colors.white.withValues(alpha: 0.55),
    offset: const Offset(-2, -2),
    blurRadius: 4,
    spreadRadius: -1,
  ),
];

class _ClayBackground extends StatelessWidget {
  const _ClayBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            right: -34,
            bottom: -42,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [ElderColors.primaryLight, ElderColors.primary],
                ),
                shape: BoxShape.circle,
                boxShadow: _claySurfaceShadows(tint: ElderColors.primary),
              ),
            ),
          ),
          Positioned(
            right: -28,
            bottom: -52,
            child: Container(
              width: 148,
              height: 74,
              decoration: BoxDecoration(
                color: ElderColors.primaryDark.withValues(alpha: 0.28),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(90),
                  topRight: Radius.circular(90),
                ),
              ),
            ),
          ),
          Positioned(
            right: 34,
            bottom: 42,
            child: Transform.rotate(
              angle: -0.2,
              child: Container(
                width: 72,
                height: 12,
                decoration: BoxDecoration(
                  color: ElderColors.clayButtercup,
                  borderRadius: BorderRadius.circular(NirvanaRadii.pill),
                ),
              ),
            ),
          ),
          const Positioned(left: -18, top: 220, child: _ClayCloud()),
          const Positioned(
            right: -12,
            top: 292,
            child: _ClayBubble(size: 32, color: ElderColors.claySage),
          ),
          const Positioned(
            right: 22,
            top: 338,
            child: _ClayBubble(size: 24, color: ElderColors.clayPeach),
          ),
          const Positioned(
            left: 202,
            bottom: 88,
            child: _ClayBubble(size: 17, color: ElderColors.clayPeach),
          ),
          const Positioned(
            left: 230,
            bottom: 56,
            child: _ClayBubble(size: 12, color: ElderColors.claySky),
          ),
          const Positioned(
            right: 62,
            bottom: 76,
            child: _ClayBubble(size: 16, color: ElderColors.clayButtercup),
          ),
        ],
      ),
    );
  }
}

class _ClayCloud extends StatelessWidget {
  const _ClayCloud();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 58,
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          Positioned(left: 0, bottom: 0, child: _CloudPuff(size: 38)),
          Positioned(left: 22, bottom: 8, child: _CloudPuff(size: 50)),
          Positioned(left: 53, bottom: 2, child: _CloudPuff(size: 36)),
        ],
      ),
    );
  }
}

class _CloudPuff extends StatelessWidget {
  const _CloudPuff({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.35, -0.4),
          colors: [Colors.white, ElderColors.primaryLight],
          stops: [0.05, 1],
        ),
        boxShadow: [
          ..._claySurfaceShadows(tint: ElderColors.primary),
          const BoxShadow(
            color: Colors.white,
            blurRadius: 5,
            offset: Offset(-3, -3),
          ),
        ],
      ),
    );
  }
}

class _ClayBubble extends StatelessWidget {
  const _ClayBubble({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: [
            Color.lerp(color, Colors.white, 0.42)!,
            color,
            Color.lerp(color, Colors.black, 0.2)!,
          ],
          stops: const [0, 0.55, 1],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          ..._claySurfaceShadows(tint: color),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.7),
            blurRadius: 3,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
    );
  }
}

class _ClayGreeting extends StatelessWidget {
  const _ClayGreeting({
    required this.greeting,
    required this.supportiveMessage,
  });

  final String greeting;
  final String supportiveMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final patientName =
        (HiveDatabase.currentPatientSession?.preferredName.isNotEmpty ?? false)
        ? HiveDatabase.currentPatientSession!.preferredName
        : (l10n?.friendlyFallbackName ?? 'Friend');
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: _clayCanvasColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: _claySurfaceShadows(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    color: ElderColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  patientName,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: ElderColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ElderColors.surface, ElderColors.primaryContainer],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              ..._claySurfaceShadows(tint: ElderColors.primary),
              const BoxShadow(
                color: Colors.white,
                blurRadius: 5,
                offset: Offset(-3, -3),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.favorite_rounded,
                color: ElderColors.primaryDark.withValues(alpha: 0.25),
                size: 30,
                shadows: const [
                  Shadow(
                    color: Colors.white,
                    blurRadius: 1,
                    offset: Offset(-1, -1),
                  ),
                ],
              ),
              const Positioned(
                left: 17,
                top: 15,
                child: Icon(
                  Icons.favorite_rounded,
                  color: ElderColors.primary,
                  size: 27,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        SpeakButton(text: '$greeting. $supportiveMessage', size: 30),
      ],
    );
  }
}

class _ClayMoment extends StatelessWidget {
  const _ClayMoment({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(NirvanaRadii.card),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
          decoration: BoxDecoration(
            color: ElderColors.primary,
            borderRadius: BorderRadius.circular(NirvanaRadii.card),
            boxShadow: _claySurfaceShadows(tint: ElderColors.primaryDark),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ClayTag(
                      text: l10n?.dailyMomentEyebrow ?? 'DAILY MOMENT',
                      color: ElderColors.primaryLight,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10n?.dailyMomentHeadline ??
                          'You are doing wonderfully today',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: ElderColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n?.dailyMomentSupportingText ??
                          'Take your time. Every small step is a good step, and you are not alone.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        height: 1.35,
                        color: ElderColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: ElderColors.primaryDark.withValues(alpha: 0.36),
                  shape: BoxShape.circle,
                  boxShadow: _claySurfaceShadows(tint: ElderColors.primaryDark),
                ),
                child: IconButton(
                  tooltip: l10n?.askNirvanaReadAloud ?? 'Listen',
                  onPressed: onTap,
                  icon: const Icon(
                    Icons.volume_up_rounded,
                    color: ElderColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClaySectionTitle extends StatelessWidget {
  const _ClaySectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _clayCanvasColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: _claySurfaceShadows(),
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: ElderColors.textPrimary,
        ),
      ),
    );
  }
}

class _ClayActionTile extends StatelessWidget {
  const _ClayActionTile({
    required this.width,
    required this.icon,
    required this.color,
    required this.tagColor,
    required this.tag,
    required this.label,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final Color color;
  final Color tagColor;
  final String tag;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(NirvanaRadii.card),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            decoration: BoxDecoration(
              color: _clayCanvasColor,
              borderRadius: BorderRadius.circular(NirvanaRadii.card),
              boxShadow: _claySurfaceShadows(),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 150),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ClayIconDisc(icon: icon, color: color),
                      Icon(Icons.chevron_right_rounded, color: color, size: 30),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ClayTag(text: tag, color: tagColor),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: ElderColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClayIconDisc extends StatelessWidget {
  const _ClayIconDisc({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-0.8, -0.9),
          end: const Alignment(0.8, 0.9),
          colors: [
            Color.lerp(color, Colors.white, 0.38)!,
            color,
            Color.lerp(color, Colors.black, 0.16)!,
          ],
          stops: const [0, 0.52, 1],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: Color.lerp(color, Colors.white, 0.42)!,
          width: 1.2,
        ),
        boxShadow: [
          ..._claySurfaceShadows(tint: color),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            blurRadius: 4,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color.lerp(color, Colors.black, 0.08),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.24),
            width: 1,
          ),
          boxShadow: _clayInsetShadows(color),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: Color.lerp(color, Colors.black, 0.35), size: 25),
            Positioned(
              left: 8,
              top: 7,
              child: Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.72),
                size: 23,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClayTag extends StatelessWidget {
  const _ClayTag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Color.lerp(color, Colors.black, 0.06),
        borderRadius: BorderRadius.circular(NirvanaRadii.pill),
        boxShadow: _clayInsetShadows(color),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
          color: ElderColors.textPrimary,
        ),
      ),
    );
  }
}
