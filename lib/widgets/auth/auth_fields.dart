import 'package:flutter/material.dart';

import '../../theme/prestige_noir.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

InputDecoration prestigeAuthFieldDecoration({
  String? hint,
  Widget? suffixIcon,
  String? errorText,
}) {
  return InputDecoration(
    hintText: hint,
    errorText: errorText,
    filled: true,
    fillColor: PrestigeNoir.surfaceRaised,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: VSpacing.lg,
      vertical: 14,
    ),
    hintStyle: const TextStyle(color: PrestigeNoir.mutedDim),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(VRadius.md),
      borderSide: const BorderSide(color: PrestigeNoir.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(VRadius.md),
      borderSide: const BorderSide(color: PrestigeNoir.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(VRadius.md),
      borderSide: const BorderSide(color: VColors.brand, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(VRadius.md),
      borderSide: const BorderSide(color: VColors.error),
    ),
    suffixIcon: suffixIcon,
  );
}

class PrestigeAuthFieldLabel extends StatelessWidget {
  const PrestigeAuthFieldLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: VFontSize.labelMd,
          fontWeight: VFontWeight.medium,
          color: PrestigeNoir.muted,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// Email field for auth screens (Material — avoids Forui focus issues on login).
class AuthEmailField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool enabled;
  final VoidCallback? onChanged;
  final ValueChanged<String>? onSubmit;
  final String? error;

  const AuthEmailField({
    super.key,
    required this.controller,
    this.focusNode,
    this.enabled = true,
    this.onChanged,
    this.onSubmit,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PrestigeAuthFieldLabel(label: 'Email'),
        TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          autocorrect: false,
          style: const TextStyle(color: PrestigeNoir.foreground),
          textInputAction: TextInputAction.next,
          onChanged: onChanged != null ? (_) => onChanged!() : null,
          onSubmitted: onSubmit,
          decoration: prestigeAuthFieldDecoration(
            hint: 'you@email.com',
            errorText: error,
          ),
        ),
      ],
    );
  }
}

/// Password field for auth screens (Material).
class AuthPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool enabled;
  final TextInputAction textInputAction;
  final VoidCallback? onChanged;
  final ValueChanged<String>? onSubmit;
  final String? hint;
  final String? error;

  const AuthPasswordField({
    super.key,
    required this.controller,
    this.focusNode,
    this.enabled = true,
    this.textInputAction = TextInputAction.done,
    this.onChanged,
    this.onSubmit,
    this.hint,
    this.error,
  });

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PrestigeAuthFieldLabel(label: 'Password'),
        TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          obscureText: _obscure,
          autofillHints: const [AutofillHints.password],
          style: const TextStyle(color: PrestigeNoir.foreground),
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged != null ? (_) => widget.onChanged!() : null,
          onSubmitted: widget.onSubmit,
          decoration: prestigeAuthFieldDecoration(
            hint: widget.hint ?? '••••••••',
            errorText: widget.error,
            suffixIcon: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: PrestigeNoir.muted,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
      ],
    );
  }
}
