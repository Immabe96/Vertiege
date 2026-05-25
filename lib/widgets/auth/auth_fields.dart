import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Email field for auth screens ([FTextField.email]).
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
    return FTextField.email(
      control: FTextFieldControl.managed(
        controller: controller,
        onChange: onChanged != null ? (_) => onChanged!() : null,
      ),
      focusNode: focusNode,
      enabled: enabled,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      onSubmit: onSubmit,
      hint: 'you@example.com',
      error: error != null ? Text(error!) : null,
    );
  }
}

/// Password field for auth screens ([FTextField.password]).
class AuthPasswordField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return FTextField.password(
      control: FTextFieldControl.managed(
        controller: controller,
        onChange: onChanged != null ? (_) => onChanged!() : null,
      ),
      focusNode: focusNode,
      enabled: enabled,
      textInputAction: textInputAction,
      onSubmit: onSubmit,
      hint: hint,
      error: error != null ? Text(error!) : null,
    );
  }
}
