import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

class VInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? error;
  final Widget? prefix;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final bool isDense;
  final FocusNode? focusNode;
  final String? initialValue;
  final String? counterText;

  const VInput({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.error,
    this.prefix,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.isDense = false,
    this.focusNode,
    this.initialValue,
    this.counterText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: VFontWeight.medium,
              color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: VSpacing.sm),
        ],
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          onTap: onTap,
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
          obscureText: obscureText,
          readOnly: readOnly,
          enabled: enabled,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefix,
            suffixIcon: suffix,
            prefixIconConstraints: prefix != null
                ? const BoxConstraints(minWidth: VTouchTarget.iconButton)
                : null,
            suffixIconConstraints: suffix != null
                ? const BoxConstraints(minWidth: VTouchTarget.iconButton)
                : null,
            counterText: counterText,
            errorText: error,
            isDense: isDense,
            contentPadding: isDense
                ? const EdgeInsets.symmetric(
                    horizontal: VSpacing.md,
                    vertical: VSpacing.sm,
                  )
                : const EdgeInsets.symmetric(
                    horizontal: VSpacing.lg,
                    vertical: VSpacing.md,
                  ),
          ),
        ),
      ],
    );
  }
}
