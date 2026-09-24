import 'package:flutter/material.dart';

import '../../theme/prestige_noir.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../feedback/v_states.dart';

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
    final height = size == VGateCtaSize.tall ? 56.0 : 48.0;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(VRadius.lg),
    );
    final labelStyle = const TextStyle(
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
            foregroundColor: VColors.onSurfaceVariantDark,
            side: const BorderSide(color: PrestigeNoir.borderLight),
            shape: shape,
          ),
        ),
      );
    }

    final leading = isLoading
        ? const VSpinner(color: VColors.onTertiary)
        : icon;

    if (leading != null) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: leading,
          label: Text(label),
          style: _filledStyle(labelStyle, shape),
        ),
      );
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: _filledStyle(labelStyle, shape),
        child: Text(label),
      ),
    );
  }

  ButtonStyle _filledStyle(TextStyle labelStyle, OutlinedBorder shape) {
    return FilledButton.styleFrom(
      backgroundColor: VColors.tertiary,
      foregroundColor: VColors.onTertiary,
      disabledBackgroundColor: VColors.surfaceContainerDark,
      textStyle: labelStyle,
      shape: shape,
    );
  }
}

enum VGateCtaSize { standard, tall }

enum VGateCtaVariant { filled, outlined }
