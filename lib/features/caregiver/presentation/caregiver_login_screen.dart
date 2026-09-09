// ==============================================================================
// NIRVANA - Caregiver Login Screen
// Description: Secure authentication interface for caregivers and family members
// with claymorphic design tokens and smooth accessibility.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/app/widgets/widgets.dart';
import 'package:nirvana/app/widgets/clay_3d/clay_3d.dart';
import 'package:nirvana/features/caregiver/providers/caregiver_providers.dart';

class CaregiverLoginScreen extends ConsumerStatefulWidget {
  const CaregiverLoginScreen({super.key});

  @override
  ConsumerState<CaregiverLoginScreen> createState() =>
      _CaregiverLoginScreenState();
}

class _CaregiverLoginScreenState extends ConsumerState<CaregiverLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(val.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? val) {
    if (val == null || val.isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }

  String _friendlyLoginError(dynamic error) {
    final raw = error.toString().toLowerCase();

    if (error is AuthException) {
      if (error.code == 'invalid_credentials' ||
          raw.contains('invalid login credentials') ||
          raw.contains('invalid_grant')) {
        return 'Invalid email or password. If you do not have an account yet, tap "Create Account" below.';
      }
      if (error.code == 'email_not_confirmed' ||
          raw.contains('email not confirmed')) {
        return 'Email not confirmed. Please check your inbox and confirm your email.';
      }
      if (raw.contains('user not found')) {
        return 'No caregiver account found with this email. Please register below.';
      }
      if (error.message.isNotEmpty) {
        return error.message;
      }
    }

    if (raw.contains('invalid login credentials') ||
        raw.contains('invalid_credentials')) {
      return 'Invalid email or password. If you do not have an account yet, tap "Create Account" below.';
    }
    if (raw.contains('socketexception') ||
        raw.contains('network') ||
        raw.contains('failed to connect') ||
        raw.contains('clientexception')) {
      return 'Unable to connect to the server. Please check your internet connection.';
    }
    if (raw.contains('timed out') || raw.contains('timeout')) {
      return 'Connection timed out. Please check your connection and try again.';
    }
    return 'Sign in failed. Please verify your credentials or create a new account.';
  }

  Future<void> _handleLogin() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      await ref.read(caregiverAuthProvider.notifier).login(email, password);

      final authState = ref.read(caregiverAuthProvider);

      // Handle any error stored in the Riverpod auth state
      if (authState.hasError) {
        if (mounted) {
          setState(() {
            _errorMessage = _friendlyLoginError(authState.error);
          });
        }
        return;
      }

      final profile = authState.valueOrNull;
      if (profile != null && mounted) {
        context.go('/caregiver/dashboard');
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _friendlyLoginError(e);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _friendlyLoginError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(caregiverAuthProvider);
    final isLoading = authState.isLoading;

    if (authState.hasError && _errorMessage == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _errorMessage = _friendlyLoginError(authState.error);
          });
        }
      });
    }

    return Scaffold(
      backgroundColor: ElderColors.backgroundClay,
      body: ClayBackdrop3D(
        child: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  LargeIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back to Landing',
                    backgroundColor: Colors.white,
                    iconColor: ElderColors.textPrimary,
                    size: 56.0,
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                  ),
                  const SizedBox(width: 16.0),
                  const Expanded(
                    child: Text(
                      'Caregiver & Family Portal',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: ElderColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Form Body
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 12.0,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Friendly Clay Avatar Header
                          Center(
                            child: Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: ElderColors.forestBg,
                                shape: BoxShape.circle,
                                boxShadow: NirvanaShadows.float(
                                  tint: ElderColors.claySage,
                                ),
                              ),
                              child: const Icon(
                                Icons.favorite_rounded,
                                size: 44,
                                color: ElderColors.claySage,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Welcome to Nirvana Care',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: ElderColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Stay connected with your loved one\'s daily activities, games, and routine.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: ElderColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Email Field
                          Container(
                            decoration: BoxDecoration(
                              color: ElderColors.surface,
                              borderRadius: BorderRadius.circular(
                                NirvanaRadii.icon,
                              ),
                              boxShadow: NirvanaShadows.input,
                            ),
                            child: TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: ElderColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                hintText: 'Enter username or email',
                                labelStyle: const TextStyle(
                                  color: ElderColors.textSecondary,
                                ),
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  color: ElderColors.claySage,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 18,
                                ),
                              ),
                              validator: _validateEmail,
                              onChanged: (_) {
                                if (_errorMessage != null) {
                                  setState(() => _errorMessage = null);
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Password Field
                          Container(
                            decoration: BoxDecoration(
                              color: ElderColors.surface,
                              borderRadius: BorderRadius.circular(
                                NirvanaRadii.icon,
                              ),
                              boxShadow: NirvanaShadows.input,
                            ),
                            child: TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: ElderColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'Enter password',
                                labelStyle: const TextStyle(
                                  color: ElderColors.textSecondary,
                                ),
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  color: ElderColors.claySage,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: ElderColors.textMuted,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 18,
                                ),
                              ),
                              validator: _validatePassword,
                              onChanged: (_) {
                                if (_errorMessage != null) {
                                  setState(() => _errorMessage = null);
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Error Banner
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: ElderColors.gentleErrorBg,
                                borderRadius: BorderRadius.circular(
                                  NirvanaRadii.button,
                                ),
                                boxShadow: NirvanaShadows.card(
                                  tint: ElderColors.gentleErrorPrimary,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: ElderColors.gentleErrorText,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: ElderColors.gentleErrorText,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Login Button
                          LargeActionButton(
                            label: 'Sign In to Dashboard',
                            icon: Icons.login_rounded,
                            colorScheme: ElderButtonScheme.primary,
                            isLoading: isLoading,
                            onPressed: isLoading ? null : _handleLogin,
                          ),
                          const SizedBox(height: 20),

                          // Create Account link
                          Center(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text(
                                  'New caregiver? ',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: ElderColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      context.go('/caregiver/register'),
                                  child: const Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: ElderColors.clayLavender,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Privacy Note
                          const Center(
                            child: Text(
                              '🔒 Patient-scoped data protection • Offline verified',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: ElderColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
