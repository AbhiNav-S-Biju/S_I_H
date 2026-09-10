import 'package:flutter/material.dart';

import 'social_media_accounts_section.dart';

class SocialMediaAccountsScreen extends StatelessWidget {
  const SocialMediaAccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Social media accounts')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: const SocialMediaAccountsSection(),
        ),
      ),
    );
  }
}
