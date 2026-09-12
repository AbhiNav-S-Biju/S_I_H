// ==============================================================================
// NIRVANA — 3D Claymorphic Input Field
// Description: Soft inset clay text field with large touch target, large label
// text and full accessibility support. Centralises input styling so every form
// in the app looks identical.
// ==============================================================================

import 'package:flutter/material.dart';
import '../../theme/elder_theme.dart';
import 'clay_3d_theme.dart';

class ClayTextField3D extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final bool autofocus;
  final bool isRequired;
  final String? semanticLabel;

  const ClayTextField3D({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.textInputAction,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.autofocus = false,
    this.isRequired = false,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      textField: true,
      label: semanticLabel ?? label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    isRequired ? '$label *' : label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: ElderColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: ElderColors.surface,
              borderRadius: BorderRadius.circular(
                ElderTheme.buttonBorderRadius,
              ),
              boxShadow: Clay3DTheme.cardShadow(blur: 12, offset: 5),
            ),
            child: TextFormField(
              controller: controller,
              enabled: enabled,
              keyboardType: keyboardType,
              obscureText: obscureText,
              validator: validator,
              onChanged: onChanged,
              onFieldSubmitted: onFieldSubmitted,
              textInputAction: textInputAction,
              maxLines: obscureText ? 1 : maxLines,
              minLines: minLines,
              autofocus: autofocus,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: ElderColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: ElderColors.textMuted,
                ),
                prefixIcon: prefixIcon,
                suffixIcon: suffixIcon,
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ElderTheme.buttonBorderRadius,
                  ),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ElderTheme.buttonBorderRadius,
                  ),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ElderTheme.buttonBorderRadius,
                  ),
                  borderSide: const BorderSide(
                    color: ElderColors.primary,
                    width: 2.0,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ElderTheme.buttonBorderRadius,
                  ),
                  borderSide: const BorderSide(
                    color: ElderColors.gentleErrorPrimary,
                    width: 2.0,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ElderTheme.buttonBorderRadius,
                  ),
                  borderSide: const BorderSide(
                    color: ElderColors.gentleErrorPrimary,
                    width: 2.0,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 18.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
