import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';

class GhostInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? initialValue;
  final int? maxLines;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;

  const GhostInput({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.initialValue,
    this.maxLines = 1,
    this.autofocus = false,
    this.onChanged,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!.toUpperCase(),
            style: const TextStyle(
              fontSize: FontSizes.labelSm,
              fontWeight: FontWeights.semiBold,
              color: AppColors.tertiary,
              letterSpacing: LetterSpacing.label,
            ),
          ),
          const SizedBox(height: Spacing.xs),
        ],
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          autofocus: autofocus,
          maxLines: maxLines,
          onChanged: onChanged,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: FontSizes.bodyMd,
            fontWeight: FontWeights.regular,
            color: AppColors.ink,
            height: LineHeight.body,
          ),
          decoration: InputDecoration(
            hintText: hint,
            border: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.glassBorder),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.glassBorder),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.tertiary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: Spacing.sm + 4,
            ),
            isDense: false,
          ),
        ),
      ],
    );
  }
}
