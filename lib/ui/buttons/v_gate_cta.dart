import 'package:flutter/material.dart';

import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

/// Gold tertiary CTA used in The Gate onboarding ritual.
///
/// Material-backed (no Forui) so brand styling stays isolated in `lib/ui/`.
class VGateCta extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final VGateCtaSize size;
  final VGateCtaVariant variant;

  const VGateCta({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.size = VGateCtaSize.standard,
    this.variant = VGateCtaVariant.filled,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final height = size == VGateCtaSize.tall ? 56.0 : 48.0;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(VRadius.lg),
    );
    final labelStyle = TextStyle(
      fontSize: VFontSize.bodyMd,
      fontWeight: VFontWeight.bold,
      letterSpacing: 0,
    );

    if (variant == VGateCtaVariant.outlined) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: icon ?? const SizedBox.shrink(),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark
                ? VColors.onSurfaceVariantDark
                : VColors.onSurfaceVariant,
            side: BorderSide(
              color: isDark ? VColors.glassBorderDark : VColors.glassBorder,
            ),
            shape: shape,
          ),
        ),
      );
    }

    final leading = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: VColors.onTertiary,
            ),
          )
        : icon;

    if (leading != null) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: leading,
          label: Text(label),
          style: _filledStyle(isDark, labelStyle, shape),
        ),
      );
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: _filledStyle(isDark, labelStyle, shape),
        child: Text(label),
      ),
    );
  }

  ButtonStyle _filledStyle(
    bool isDark,
    TextStyle labelStyle,
    OutlinedBorder shape,
  ) {
    return FilledButton.styleFrom(
      backgroundColor: VColors.tertiary,
      foregroundColor: VColors.onTertiary,
      disabledBackgroundColor: isDark
          ? VColors.surfaceContainerDark
          : VColors.surfaceContainerLow,
      textStyle: labelStyle,
      shape: shape,
    );
  }
}

enum VGateCtaSize { standard, tall }

enum VGateCtaVariant { filled, outlined }
