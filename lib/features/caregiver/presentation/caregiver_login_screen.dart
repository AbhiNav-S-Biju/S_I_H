// ==============================================================================
// NIRVANA - Caregiver Login Screen
// Description: Secure authentication interface for caregivers and family members.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/features/caregiver/providers/caregiver_providers.dart';

class CaregiverLoginScreen extends ConsumerStatefulWidget {
  const CaregiverLoginScreen({super.key});

  @override
  ConsumerState<CaregiverLoginScreen> createState() =>
      _CaregiverLoginScreenState();
}

class _CaregiverLoginScreenState extends ConsumerState<CaregiverLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(
    text: 'caregiver@nirvana.care',
  );
  final _passwordController = TextEditingController(text: 'CaregiverPass123!');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(caregiverAuthProvider.notifier)
        .login(_emailController.text, _passwordController.text);

    final authState = ref.read(caregiverAuthProvider);
    if (authState.value != null && mounted) {
      context.go('/caregiver/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(caregiverAuthProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF9),
      appBar: AppBar(
        title: const Text('Caregiver & Family Portal'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: ElderColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Home',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icon and Header
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ElderColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          size: 48,
                          color: ElderColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Welcome to Nirvana Care',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: ElderColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Stay connected with your loved one\'s daily activities, games, and routine.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 32),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Please enter your email'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (val) => (val == null || val.isEmpty)
                          ? 'Please enter your password'
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // Login Button
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ElderColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Sign In to Dashboard',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Offline Info Note
                    Center(
                      child: Text(
                        '🔒 Offline-first verified • Patient-scoped data protection',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
