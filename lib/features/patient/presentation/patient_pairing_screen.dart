// ==============================================================================
// NIRVANA - Patient Pairing Screen (3D Claymorphism)
// Description: Tactile 6-digit PIN entry screen for elderly patients with embossed PIN boxes,
// large touch targets, floating ambient 3D decorations, and calm feedback.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/widgets/clay_3d/clay_3d.dart';
import '../../../features/patient/providers/patient_pairing_providers.dart';

class PatientPairingScreen extends ConsumerStatefulWidget {
  const PatientPairingScreen({super.key});

  @override
  ConsumerState<PatientPairingScreen> createState() =>
      _PatientPairingScreenState();
}

class _PatientPairingScreenState extends ConsumerState<PatientPairingScreen> {
  static const int _codeLength = 6;
  final List<TextEditingController> _controllers = List.generate(
    _codeLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    _codeLength,
    (_) => FocusNode(),
  );

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

  String get _currentCode => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      for (int i = 0; i < _codeLength && i < digits.length; i++) {
        _controllers[index + i < _codeLength ? index + i : _codeLength - 1]
                .text =
            digits[i];
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

    return ClayScaffold3D(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Top Navigation Row
          Row(
            children: [
              GestureDetector(
                onTap: () => context.go('/patient/welcome'),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Clay3DTheme.cardSurface,
                    shape: BoxShape.circle,
                    boxShadow: Clay3DTheme.cardShadow(blur: 8, offset: 3),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 24,
                      color: Clay3DTheme.textDark,
                    ),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),

          const SizedBox(height: 12),

          // 3D Dialpad Token
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Clay3DTheme.lavenderLight,
              shape: BoxShape.circle,
              boxShadow: Clay3DTheme.deepShadow(blur: 16, offset: 6),
            ),
            child: const Center(
              child: Icon(
                Icons.dialpad_rounded,
                size: 40,
                color: Color(0xFF6B58A0),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Heading
          Text(
            'Enter Your Code',
            style: GoogleFonts.nunito(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Clay3DTheme.textDark,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            'Your caregiver showed you a 6-digit number.\nType it below.',
            style: GoogleFonts.nunito(
              fontSize: 15,
              color: Clay3DTheme.textMuted,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // 6-digit 3D Embossed PIN boxes
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 8.0;
              final pinWidth =
                  ((constraints.maxWidth - spacing * (_codeLength - 1)) /
                          _codeLength)
                      .clamp(40.0, 48.0);

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_codeLength, (i) {
                  return Padding(
                    padding: EdgeInsets.only(
                      right: i < _codeLength - 1 ? spacing : 0,
                    ),
                    child: _Clay3DPinBox(
                      width: pinWidth,
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      hasError: pairingState.isError,
                      onChanged: (v) => _onDigitChanged(i, v),
                      onKeyEvent: (e) => _onKeyEvent(i, e),
                      autofocus: i == 0,
                    ),
                  );
                }),
              );
            },
          ),

          const SizedBox(height: 20),

          // Error message
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: pairingState.isError
                ? ClayCard3D(
                    key: const ValueKey('error'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    borderRadius: 20,
                    color: const Color(0xFFFBE4E0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: Clay3DTheme.coral,
                          size: 26,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            pairingState.errorMessage ??
                                'Incorrect code. Please try again.',
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              color: Clay3DTheme.coral,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('no-error')),
          ),

          const SizedBox(height: 24),

          // Verify Button
          SizedBox(
            width: double.infinity,
            child: ClayButton3D(
              label: 'Verify Code',
              icon: Icons.check_circle_rounded,
              color: Clay3DTheme.lavender,
              isLoading: pairingState.isLoading,
              onPressed: isComplete && !pairingState.isLoading ? _verify : null,
            ),
          ),

          const SizedBox(height: 14),

          // Clear Button
          TextButton.icon(
            onPressed: _clearAll,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: Text(
              'Clear All Digits',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Clay3DTheme.textMuted,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),

          const SizedBox(height: 20),

          // Help hint 3D card
          ClayCard3D(
            padding: const EdgeInsets.all(16),
            borderRadius: 20,
            color: const Color(0xFFE9F4F0),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Color(0xFF286D6D),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'If you do not have a code, ask your caregiver to tap "Generate Pairing Code" on their phone.',
                    style: GoogleFonts.nunito(
                      fontSize: 13.5,
                      color: const Color(0xFF286D6D),
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ==============================================================================
// 3D Embossed PIN Box Widget
// ==============================================================================
class _Clay3DPinBox extends StatelessWidget {
  final double width;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final bool autofocus;
  final ValueChanged<String> onChanged;
  final ValueChanged<KeyEvent> onKeyEvent;

  const _Clay3DPinBox({
    required this.width,
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
      width: width,
      height: 64,
      decoration: BoxDecoration(
        color: hasValue
            ? Clay3DTheme.lavenderLight.withValues(alpha: 0.70)
            : Clay3DTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: hasValue
            ? Clay3DTheme.cardShadow(blur: 8, offset: 3)
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  offset: const Offset(3, 3),
                  blurRadius: 6,
                ),
                const BoxShadow(
                  color: Colors.white,
                  offset: Offset(-2, -2),
                  blurRadius: 5,
                ),
              ],
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
          style: GoogleFonts.nunito(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: hasError
                ? Clay3DTheme.coral
                : (hasValue ? const Color(0xFF5D4A8C) : Clay3DTheme.textDark),
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
