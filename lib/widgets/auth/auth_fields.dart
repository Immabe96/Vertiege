import 'package:flutter/material.dart';

import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

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

  InputDecoration _decoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(VRadius.md),
    );
    return InputDecoration(
      labelText: 'Email',
      hintText: 'you@example.com',
      errorText: error,
      border: border,
      enabledBorder: border.copyWith(
        borderSide: BorderSide(
          color: isDark ? VColors.outlineDark : VColors.outline,
        ),
      ),
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: VColors.primary, width: 2),
      ),
      isDense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      autocorrect: false,
      textInputAction: TextInputAction.next,
      onChanged: onChanged != null ? (_) => onChanged!() : null,
      onSubmitted: onSubmit,
      decoration: _decoration(context),
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

  InputDecoration _decoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(VRadius.md),
    );
    return InputDecoration(
      labelText: 'Password',
      hintText: widget.hint,
      errorText: widget.error,
      border: border,
      enabledBorder: border.copyWith(
        borderSide: BorderSide(
          color: isDark ? VColors.outlineDark : VColors.outline,
        ),
      ),
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: VColors.primary, width: 2),
      ),
      suffixIcon: IconButton(
        icon: Icon(
          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
      isDense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      obscureText: _obscure,
      autofillHints: const [AutofillHints.password],
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged != null ? (_) => widget.onChanged!() : null,
      onSubmitted: widget.onSubmit,
      decoration: _decoration(context),
    );
  }
}
