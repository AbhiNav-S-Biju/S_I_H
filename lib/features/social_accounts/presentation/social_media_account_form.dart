import 'package:flutter/material.dart';

import '../models/social_media_account.dart';

class SocialMediaAccountForm extends StatefulWidget {
  const SocialMediaAccountForm({
    required this.onSave,
    this.initialAccount,
    this.onCancel,
    super.key,
  });

  final SocialMediaAccount? initialAccount;
  final Future<void> Function(SocialMediaAccount account) onSave;
  final VoidCallback? onCancel;

  @override
  State<SocialMediaAccountForm> createState() => _SocialMediaAccountFormState();
}

class _SocialMediaAccountFormState extends State<SocialMediaAccountForm> {
  final _formKey = GlobalKey<FormState>();
  late SocialPlatform _platform;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  bool _obscurePassword = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final account = widget.initialAccount;
    _platform = account?.platform ?? SocialPlatform.instagram;
    _usernameController = TextEditingController(
      text: account?.usernameOrEmail ?? '',
    );
    _passwordController = TextEditingController(text: account?.password ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        SocialMediaAccount(
          id: widget.initialAccount?.id ?? '',
          platform: _platform,
          usernameOrEmail: _usernameController.text.trim(),
          password: _passwordController.text,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<SocialPlatform>(
            value: _platform,
            decoration: const InputDecoration(
              labelText: 'Platform',
              prefixIcon: Icon(Icons.public_rounded),
            ),
            items: SocialPlatform.values
                .map(
                  (platform) => DropdownMenuItem(
                    value: platform,
                    child: Text(platform.label),
                  ),
                )
                .toList(growable: false),
            onChanged: _isSaving
                ? null
                : (value) {
                    if (value != null) setState(() => _platform = value);
                  },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _usernameController,
            enabled: !_isSaving,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Username or email',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter a username or email.'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _passwordController,
            enabled: !_isSaving,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                onPressed: _isSaving
                    ? null
                    : () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
              ),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Enter a password.' : null,
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.onCancel != null)
                TextButton(
                  onPressed: _isSaving ? null : widget.onCancel,
                  child: const Text('Cancel'),
                ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _isSaving ? null : _submit,
                icon: _isSaving
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_isSaving ? 'Saving' : 'Save account'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
