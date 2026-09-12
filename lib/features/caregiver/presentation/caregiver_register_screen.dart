// ==============================================================================
// NIRVANA - Caregiver Registration Screen
// Description: New account creation for caregivers using Supabase Auth
// with claymorphism styling and elder-grade accessibility.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/app/widgets/widgets.dart';
import 'package:nirvana/app/widgets/clay_3d/clay_3d.dart';
import 'package:nirvana/features/caregiver/providers/caregiver_providers.dart';

class CaregiverRegisterScreen extends ConsumerStatefulWidget {
  const CaregiverRegisterScreen({super.key});

  @override
  ConsumerState<CaregiverRegisterScreen> createState() =>
      _CaregiverRegisterScreenState();
}

class _CaregiverRegisterScreenState
    extends ConsumerState<CaregiverRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ---------- Field Validators ----------

  String? _validateFullName(String? val) {
    if (val == null || val.trim().isEmpty) return 'Please enter your full name';
    if (val.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? _validateEmail(String? val) {
    if (val == null || val.trim().isEmpty) return 'Please enter your email';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(val.trim())) return 'Please enter a valid email';
    return null;
  }

  String? _validatePhone(String? val) {
    if (val == null || val.trim().isEmpty) return null;
    final phoneRegex = RegExp(r'^\+?[0-9\s\-()]{7,15}$');
    if (!phoneRegex.hasMatch(val.trim())) return 'Enter a valid phone number';
    return null;
  }

  String? _validatePassword(String? val) {
    if (val == null || val.isEmpty) return 'Please enter a password';
    if (val.length < 8) return 'Password must be at least 8 characters';
    if (!val.contains(RegExp(r'[A-Z]'))) {
      return 'Include at least one uppercase letter';
    }
    if (!val.contains(RegExp(r'[0-9]'))) {
      return 'Include at least one number';
    }
    return null;
  }

  String? _validateConfirmPassword(String? val) {
    if (val == null || val.isEmpty) return 'Please confirm your password';
    if (val != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  // ---------- Registration Handler ----------

  Future<void> _handleRegister() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(caregiverAuthProvider.notifier).register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );

      final authState = ref.read(caregiverAuthProvider);
      if (authState.value != null && mounted) {
        context.go('/caregiver/onboarding');
      }

      if (authState.hasError && mounted) {
        setState(() {
          _errorMessage = _friendlyError(authState.error.toString());
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = _friendlyError(e.toString()));
      }
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('already registered') ||
        raw.contains('already been registered') ||
        raw.contains('User already registered')) {
      return 'An account with this email already exists. Please sign in.';
    }
    if (raw.contains('invalid email') || raw.contains('Invalid email')) {
      return 'That email address does not appear to be valid.';
    }
    if (raw.contains('weak password') || raw.contains('Password should be')) {
      return 'Password is too weak. Use at least 8 characters with uppercase and numbers.';
    }
    if (raw.contains('network') || raw.contains('SocketException')) {
      return 'No internet connection. Please check your network.';
    }
    return 'Registration failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(caregiverAuthProvider);
    final isLoading = authState.isLoading;

    if (authState.hasError && _errorMessage == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _errorMessage = _friendlyError(authState.error.toString());
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                children: [
                  LargeIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back to Sign In',
                    backgroundColor: Colors.white,
                    iconColor: ElderColors.textPrimary,
                    size: 56.0,
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/caregiver/login');
                      }
                    },
                  ),
                  const SizedBox(width: 16.0),
                  const Expanded(
                    child: Text(
                      'Create Account',
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

            // Form Content
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header Icon
                          Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: ElderColors.clayLavender.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: ElderColors.clayLavender.withValues(alpha: 0.25),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person_add_rounded,
                                size: 40,
                                color: ElderColors.clayLavender,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Caregiver Registration',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: ElderColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Create your account to configure routines, monitor activity, and pair with patient devices.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: ElderColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Full Name
                          _buildClayInput(
                            controller: _fullNameController,
                            label: 'Your Full Name',
                            icon: Icons.person_outline_rounded,
                            validator: _validateFullName,
                          ),
                          const SizedBox(height: 14),

                          // Email
                          _buildClayInput(
                            controller: _emailController,
                            label: 'Email Address',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 14),

                          // Phone (Optional)
                          _buildClayInput(
                            controller: _phoneController,
                            label: 'Phone Number (Optional)',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: _validatePhone,
                          ),
                          const SizedBox(height: 14),

                          // Password
                          _buildClayInput(
                            controller: _passwordController,
                            label: 'Password (min 8 chars, 1 uppercase, 1 number)',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            validator: _validatePassword,
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
                          ),
                          const SizedBox(height: 14),

                          // Confirm Password
                          _buildClayInput(
                            controller: _confirmPasswordController,
                            label: 'Confirm Password',
                            icon: Icons.lock_reset_rounded,
                            obscureText: _obscureConfirmPassword,
                            validator: _validateConfirmPassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: ElderColors.textMuted,
                              ),
                              onPressed: () => setState(
                                () => _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                              ),
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
                                color: ElderColors.clayPeach.withValues(alpha: 0.2),
                                border: Border.all(color: ElderColors.clayPeach),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
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

                          // Submit Button
                          LargeActionButton(
                            label: 'Create Account',
                            icon: Icons.arrow_forward_rounded,
                            colorScheme: ElderButtonScheme.primary,
                            isLoading: isLoading,
                            onPressed: isLoading ? null : _handleRegister,
                          ),
                          const SizedBox(height: 18),

                          // Already have account
                          Center(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text(
                                  'Already have an account? ',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: ElderColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => context.go('/caregiver/login'),
                                  child: const Text(
                                    'Sign In',
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
                          const SizedBox(height: 24),
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

  Widget _buildClayInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: ElderColors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: ElderColors.textSecondary, fontSize: 14),
          prefixIcon: Icon(icon, color: ElderColors.clayLavender),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        onChanged: (_) {
          if (_errorMessage != null) {
            setState(() => _errorMessage = null);
          }
        },
      ),
    );
  }
}
