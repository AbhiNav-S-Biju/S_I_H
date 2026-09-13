import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/elder_theme.dart';
import '../../../app/theme/nirvana_responsive.dart';
import '../../../app/widgets/clay_3d/clay_3d.dart';
import '../../../l10n/l10n_extension.dart';
import 'social_media_accounts_section.dart';

class SocialMediaAccountsScreen extends StatelessWidget {
  const SocialMediaAccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ElderColors.backgroundClay,
      body: ClayBackdrop3D(
        child: SafeArea(
          child: Column(
            children: [
              Builder(
                builder: (context) => ClayHeader3D(
                  title: context.l10n.socialAccountsScreenTitle,
                  subtitle: context.l10n.socialAccountsScreenSubtitle,
                  onBack: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/patient/home');
                    }
                  },
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    NirvanaSpacing.pageHorizontal(context),
                    8,
                    NirvanaSpacing.pageHorizontal(context),
                    32,
                  ),
                  child: const NirvanaContentWidth(
                    child: SocialMediaAccountsSection(),
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
