// ==============================================================================
// NIRVANA - Patient Pairing Screen
// Description: 6-digit PIN entry screen for elderly patients.
// Claymorphic design with large touch targets, auto-advance focus,
// clear feedback in plain language, and soft dual shadows.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/app/widgets/widgets.dart';
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
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: LargeIconButton(
            icon: Icons.arrow_back_rounded,
            semanticLabel: 'Go back',
            onPressed: () => context.go('/patient/welcome'),
            size: 48,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // Dialpad Icon Clay Bubble
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: ElderColors.primaryContainer,
                  shape: BoxShape.circle,
                  boxShadow: NirvanaShadows.float(tint: ElderColors.primary),
                ),
                child: const Icon(
                  Icons.dialpad_rounded,
                  size: 44,
                  color: ElderColors.primary,
                ),
              ),
              const SizedBox(height: 20),

              // Heading
              const Text(
                'Enter Your Code',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: ElderColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              const Text(
                'Your caregiver showed you a 6-digit number.\nType it below.',
                style: TextStyle(
                  fontSize: 17,
                  color: ElderColors.textSecondary,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),

              // 6-digit PIN boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_codeLength, (i) {
                  return Padding(
                    padding: EdgeInsets.only(right: i < _codeLength - 1 ? 8 : 0),
                    child: _ClayPinBox(
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
                          borderRadius: BorderRadius.circular(ElderTheme.cardBorderRadius),
                          boxShadow: NirvanaShadows.card(tint: ElderColors.gentleErrorPrimary),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: ElderColors.coralDeep,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                pairingState.errorMessage ??
                                    'Incorrect code. Please try again.',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: ElderColors.coralDeep,
                                  fontWeight: FontWeight.w700,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('no-error')),
              ),

              const SizedBox(height: 32),

              // Verify button
              SizedBox(
                width: double.infinity,
                child: LargeActionButton(
                  label: 'Verify Code',
                  isLoading: pairingState.isLoading,
                  icon: Icons.check_circle_rounded,
                  variant: LargeActionButtonVariant.primary,
                  onPressed: isComplete && !pairingState.isLoading ? _verify : null,
                ),
              ),

              const SizedBox(height: 14),

              // Clear button
              TextButton.icon(
                onPressed: _clearAll,
                icon: const Icon(Icons.refresh_rounded, size: 22),
                label: const Text(
                  'Clear All Digits',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: ElderColors.textSecondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Help hint
              SupportiveMessage(
                message: 'If you do not have a code, ask your caregiver to tap "Generate Pairing Code" on their phone.',
                icon: Icons.lightbulb_outline_rounded,
                backgroundColor: ElderColors.pastelSage,
                accentColor: ElderColors.forestDeep,
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
// Claymorphic PIN Box Widget
// ==============================================================================

class _ClayPinBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final bool autofocus;
  final ValueChanged<String> onChanged;
  final ValueChanged<KeyEvent> onKeyEvent;

  const _ClayPinBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
    required this.onKeyEvent,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = controller.text.isNotEmpty;

    return Container(
      width: 48,
      height: 64,
      decoration: BoxDecoration(
        color: hasValue ? ElderColors.primaryContainer : ElderColors.surface,
        borderRadius: BorderRadius.circular(NirvanaRadii.icon),
        border: Border.all(
          color: hasError
              ? ElderColors.gentleErrorPrimary
              : (hasValue ? ElderColors.primary : ElderColors.border),
          width: hasValue ? 1.5 : 1.0,
        ),
        boxShadow: NirvanaShadows.input,
      ),
      child: KeyboardListener(
        focusNode: FocusNode(skipTraversal: true),
        onKeyEvent: onKeyEvent,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 2,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: hasError
                ? ElderColors.coralDeep
                : (hasValue ? ElderColors.primary : ElderColors.textPrimary),
          ),
          decoration: const InputDecoration(
            counterText: '',
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

