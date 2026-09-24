import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Forui-backed labeled text field with validation.
class VTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final Widget? label;
  final String? hint;
  final TextCapitalization textCapitalization;
  final int? maxLength;
  final int? maxLines;
  final String? Function(String?)? validator;

  const VTextFormField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.textCapitalization = TextCapitalization.none,
    this.maxLength,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return FTextFormField(
      control: FTextFieldControl.managed(controller: controller),
      label: label,
      hint: hint,
      textCapitalization: textCapitalization,
      maxLength: maxLength,
      maxLines: maxLines,
      validator: validator,
    );
  }
}
