// ==============================================================================
// NIRVANA - Patient Pairing Screen
// Description: 6-digit PIN entry screen for elderly patients.
// Large touch targets, auto-advance focus, clear error messages in plain language.
// Calls patientPairingProvider to validate the code server-side.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/features/patient/providers/patient_pairing_providers.dart';

class PatientPairingScreen extends ConsumerStatefulWidget {
  const PatientPairingScreen({super.key});

  @override
  ConsumerState<PatientPairingScreen> createState() =>
      _PatientPairingScreenState();
}

class _PatientPairingScreenState extends ConsumerState<PatientPairingScreen> {
  static const int _codeLength = 6;
  final List<TextEditingController> _controllers =
      List.generate(_codeLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_codeLength, (_) => FocusNode());

  bool _hasNavigated = false;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _currentCode =>
      _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      // Paste handling: distribute across boxes
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      for (int i = 0; i < _codeLength && i < digits.length; i++) {
        _controllers[index + i < _codeLength ? index + i : _codeLength - 1]
            .text = digits[i];
      }
      final nextFocus = (index + digits.length).clamp(0, _codeLength - 1);
      _focusNodes[nextFocus].requestFocus();
      setState(() {});
      return;
    }

    if (value.isNotEmpty) {
      // Advance to next box
      if (index < _codeLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }
    setState(() {});
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      setState(() {});
    }
  }

  void _clearAll() {
    for (final c in _controllers) {
      c.clear();
    }
    ref.read(patientPairingProvider.notifier).reset();
    _focusNodes[0].requestFocus();
    setState(() {});
  }

  Future<void> _verify() async {
    final code = _currentCode;
    if (code.length < _codeLength) return;
    FocusScope.of(context).unfocus();
    await ref.read(patientPairingProvider.notifier).pair(code);
  }

  @override
  Widget build(BuildContext context) {
    final pairingState = ref.watch(patientPairingProvider);

    // Navigate to success on pairing success
    ref.listen(patientPairingProvider, (_, next) {
      if (next.isSuccess && !_hasNavigated) {
        _hasNavigated = true;
        context.go('/patient/success');
      }
    });

    final isComplete = _currentCode.length == _codeLength;

    return Scaffold(
      backgroundColor: ElderColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          iconSize: 32,
          color: ElderColors.textSecondary,
          onPressed: () => context.go('/patient/welcome'),
          tooltip: 'Go back',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),

              // Icon
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: ElderColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.dialpad_rounded,
                  size: 48,
                  color: ElderColors.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Heading
              Text(
                'Enter Your Code',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: ElderColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Text(
                'Your caregiver showed you a 6-digit number.\nType it below.',
                style: TextStyle(
                  fontSize: 18,
                  color: ElderColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 44),

              // 6-digit PIN boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_codeLength, (i) {
                  return Padding(
                    padding: EdgeInsets.only(right: i < _codeLength - 1 ? 10 : 0),
                    child: _PinBox(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      hasError: pairingState.isError,
                      onChanged: (v) => _onDigitChanged(i, v),
                      onKeyEvent: (e) => _onKeyEvent(i, e),
                      autofocus: i == 0,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Error message
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: pairingState.isError
                    ? Container(
                        key: const ValueKey('error'),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: ElderColors.gentleErrorBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: ElderColors.gentleErrorBorder,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: ElderColors.gentleErrorPrimary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                pairingState.errorMessage ??
                                    'Incorrect code. Please try again.',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: ElderColors.gentleErrorText,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('no-error')),
              ),

              const SizedBox(height: 36),

              // Verify button
              SizedBox(
                width: double.infinity,
                height: 68,
                child: ElevatedButton(
                  onPressed:
                      isComplete && !pairingState.isLoading ? _verify : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ElderColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: ElderColors.border,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: isComplete ? 4 : 0,
                  ),
                  child: pairingState.isLoading
                      ? const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Verify Code',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Clear button
              TextButton.icon(
                onPressed: _clearAll,
                icon: const Icon(Icons.clear_rounded, size: 22),
                label: const Text(
                  'Clear',
                  style: TextStyle(fontSize: 18),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: ElderColors.textMuted,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Help hint
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: ElderColors.supportiveBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ElderColors.supportiveBorder),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: ElderColors.supportiveIcon,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'If you don\'t have a code, ask your caregiver to tap "Generate Pairing Code" on their phone.',
                        style: TextStyle(
                          fontSize: 15,
                          color: ElderColors.supportiveText,
                          height: 1.5,
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
    );
  }
}

// ==============================================================================
// PIN Box Widget
// ==============================================================================

class _PinBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final bool autofocus;
  final ValueChanged<String> onChanged;
  final ValueChanged<KeyEvent> onKeyEvent;

  const _PinBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
    required this.onKeyEvent,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 68,
      child: KeyboardListener(
        focusNode: FocusNode(skipTraversal: true),
        onKeyEvent: onKeyEvent,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 2, // Allow 2 temporarily for paste detection
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: hasError
                ? ElderColors.gentleErrorPrimary
                : ElderColors.textPrimary,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: controller.text.isNotEmpty
                ? ElderColors.primaryContainer
                : ElderColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: hasError
                    ? ElderColors.gentleErrorBorder
                    : ElderColors.border,
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: hasError
                    ? ElderColors.gentleErrorPrimary
                    : ElderColors.primary,
                width: 2.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: hasError
                    ? ElderColors.gentleErrorBorder
                    : (controller.text.isNotEmpty
                        ? ElderColors.primary
                        : ElderColors.border),
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
