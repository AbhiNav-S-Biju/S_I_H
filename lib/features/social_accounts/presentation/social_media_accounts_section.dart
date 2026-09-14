import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/features/patient/providers/patient_pairing_providers.dart';
import 'package:nirvana/l10n/l10n_extension.dart';

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
    final l10n = context.l10n;
    final repository = ref.read(socialMediaAccountRepositoryProvider);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          account == null ? l10n.addSocialAccountTitle : l10n.editAccountTitle,
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
                            ? l10n.socialAccountSavedLocal
                            : l10n.socialAccountSavedCloud,
                      ),
                    ),
                  );
                }
              } catch (_) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(l10n.socialAccountSaveError),
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
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteAccountTitle),
        content: Text(
          l10n.deleteAccountMessage(
            account.platform.label,
            account.usernameOrEmail,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.deleteButton),
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
          SnackBar(content: Text(l10n.accountDeletedSnack)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.accountDeleteErrorSnack)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
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
              Expanded(
                child: Text(
                  l10n.socialAccountsTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: ElderColors.textPrimary,
                  ),
                ),
              ),
              IconButton.filledTonal(
                tooltip: l10n.addSocialAccountTooltip,
                onPressed: () => _showEditor(context, ref),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.socialAccountsSubtitle,
            style: const TextStyle(color: ElderColors.textSecondary),
          ),
          const SizedBox(height: 14),
          accounts.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Text(
              l10n.socialAccountsLoadError,
              style: const TextStyle(color: ElderColors.gentleErrorText),
            ),
            data: (items) {
              if (items.isEmpty) {
                return Text(
                  l10n.noSocialAccountsSaved,
                  style: const TextStyle(color: ElderColors.textSecondary),
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
      SnackBar(content: Text(context.l10n.passwordCopiedSnack)),
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
                Text(
                  context.l10n.passwordHiddenLabel,
                  style: const TextStyle(
                    color: ElderColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<_AccountAction>(
            tooltip: context.l10n.accountActionsTooltip,
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
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _AccountAction.copyPassword,
                child: Text(context.l10n.copyPasswordMenuItem),
              ),
              PopupMenuItem(
                value: _AccountAction.edit,
                child: Text(context.l10n.editAccountMenuItem),
              ),
              PopupMenuItem(
                value: _AccountAction.delete,
                child: Text(context.l10n.deleteAccountMenuItem),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _AccountAction { copyPassword, edit, delete }
