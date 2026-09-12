import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/features/patient/providers/patient_pairing_providers.dart';

import '../models/social_media_account.dart';
import '../providers/social_media_account_providers.dart';
import '../repositories/social_media_account_repository.dart';
import 'social_media_account_form.dart';

class SocialMediaAccountsSection extends ConsumerWidget {
  const SocialMediaAccountsSection({super.key});

  Future<void> _showEditor(
    BuildContext context,
    WidgetRef ref, {
    SocialMediaAccount? account,
  }) async {
    final patientId = ref.read(localPatientSessionProvider)?.patientId;
    if (patientId == null || patientId.isEmpty) return;
    final repository = ref.read(socialMediaAccountRepositoryProvider);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          account == null ? 'Add social media account' : 'Edit account',
        ),
        content: SingleChildScrollView(
          child: SocialMediaAccountForm(
            initialAccount: account,
            onCancel: () => Navigator.pop(dialogContext),
            onSave: (value) async {
              try {
                await repository.save(patientId, value);
                ref.invalidate(socialMediaAccountsProvider(patientId));
                ref.invalidate(currentPatientSocialMediaAccountsProvider);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        repository is CloudFirstSocialMediaAccountRepository &&
                                repository.usedLocalFallback
                            ? 'Saved securely on this device. Cloud sync is unavailable.'
                            : 'Account saved securely to Supabase.',
                      ),
                    ),
                  );
                }
              } catch (_) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Unable to save this account. Check the patient pairing and Supabase setup.',
                      ),
                    ),
                  );
                }
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    SocialMediaAccount account,
  ) async {
    final patientId = ref.read(localPatientSessionProvider)?.patientId;
    if (patientId == null || patientId.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: Text(
          'Remove the ${account.platform.label} account for '
          '${account.usernameOrEmail}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(socialMediaAccountRepositoryProvider)
          .delete(patientId, account.id);
      ref.invalidate(socialMediaAccountsProvider(patientId));
      ref.invalidate(currentPatientSocialMediaAccountsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted securely.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to delete this account.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(currentPatientSocialMediaAccountsProvider);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ElderTheme.cardBorderRadius),
        border: Border.all(color: ElderColors.borderLight, width: 1.5),
        boxShadow: ElderColors.clayShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Social media accounts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: ElderColors.textPrimary,
                  ),
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Add social media account',
                onPressed: () => _showEditor(context, ref),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Your account details are protected on this device.',
            style: TextStyle(color: ElderColors.textSecondary),
          ),
          const SizedBox(height: 14),
          accounts.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text(
              'We could not load your saved accounts. Please try again.',
              style: TextStyle(color: ElderColors.gentleErrorText),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const Text(
                  'No social media accounts saved yet.',
                  style: TextStyle(color: ElderColors.textSecondary),
                );
              }
              return Column(
                children: items
                    .map(
                      (account) => _SocialMediaAccountTile(
                        account: account,
                        onEdit: () =>
                            _showEditor(context, ref, account: account),
                        onDelete: () => _delete(context, ref, account),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SocialMediaAccountTile extends StatelessWidget {
  const _SocialMediaAccountTile({
    required this.account,
    required this.onEdit,
    required this.onDelete,
  });

  final SocialMediaAccount account;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Future<void> _copyPassword(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: account.password));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password copied to clipboard.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: ElderColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ElderColors.borderLight),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: ElderColors.primary.withValues(alpha: 0.12),
            foregroundColor: ElderColors.primary,
            child: Icon(account.platform.icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.platform.label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  account.usernameOrEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: const TextStyle(
                    color: ElderColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Password: ••••••••',
                  style: TextStyle(
                    color: ElderColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<_AccountAction>(
            tooltip: 'Account actions',
            onSelected: (action) {
              switch (action) {
                case _AccountAction.copyPassword:
                  _copyPassword(context);
                case _AccountAction.edit:
                  onEdit();
                case _AccountAction.delete:
                  onDelete();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _AccountAction.copyPassword,
                child: Text('Copy password'),
              ),
              PopupMenuItem(
                value: _AccountAction.edit,
                child: Text('Edit account'),
              ),
              PopupMenuItem(
                value: _AccountAction.delete,
                child: Text('Delete account'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _AccountAction { copyPassword, edit, delete }
