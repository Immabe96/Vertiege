import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

class VButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final Widget? icon;
  final ButtonVariant variant;
  final ButtonSize size;

  const VButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
    this.variant = ButtonVariant.filled,
    this.size = ButtonSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final height = switch (size) {
      ButtonSize.small => 36.0,
      ButtonSize.medium => 44.0,
      ButtonSize.large => 52.0,
    };

    final fontSize = switch (size) {
      ButtonSize.small => VFontSize.labelMd,
      ButtonSize.medium => VFontSize.labelLg,
      ButtonSize.large => VFontSize.bodyMd,
    };

    final padding = switch (size) {
      ButtonSize.small => const EdgeInsets.symmetric(horizontal: VSpacing.md),
      ButtonSize.medium => const EdgeInsets.symmetric(horizontal: VSpacing.xl),
      ButtonSize.large => const EdgeInsets.symmetric(horizontal: VSpacing.xxl),
    };

    Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: fontSize,
            height: fontSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(
                variant == ButtonVariant.outlined
                    ? (isDark ? VColors.primaryLight : VColors.primary)
                    : VColors.onPrimary,
              ),
            ),
          ),
          if (icon != null) const SizedBox(width: VSpacing.sm),
        ] else if (icon != null) ...[
          icon!,
          const SizedBox(width: VSpacing.sm),
        ],
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontSize: fontSize,
            fontWeight: VFontWeight.semiBold,
          ),
        ),
      ],
    );

    final button = switch (variant) {
      ButtonVariant.filled => FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            minimumSize: Size(isFullWidth ? double.infinity : 0, height),
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(VRadius.md),
            ),
          ),
          child: child,
        ),
      ButtonVariant.outlined => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: Size(isFullWidth ? double.infinity : 0, height),
            padding: padding,
            side: BorderSide(
              color: isDark
                  ? VColors.primaryLight.withValues(alpha: 0.4)
                  : VColors.primary.withValues(alpha: 0.4),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(VRadius.md),
            ),
          ),
          child: child,
        ),
      ButtonVariant.text => TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            minimumSize: Size(isFullWidth ? double.infinity : 0, height),
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(VRadius.md),
            ),
          ),
          child: child,
        ),
      ButtonVariant.tonal => FilledButton.tonal(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            minimumSize: Size(isFullWidth ? double.infinity : 0, height),
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(VRadius.md),
            ),
          ),
          child: child,
        ),
      ButtonVariant.glass => _GlassButton(
          onPressed: isLoading ? null : onPressed,
          isFullWidth: isFullWidth,
          height: height,
          padding: padding,
          isDark: isDark,
          child: child,
        ),
    };

    return isFullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}

class _GlassButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isFullWidth;
  final double height;
  final EdgeInsetsGeometry padding;
  final bool isDark;
  final Widget child;

  const _GlassButton({
    required this.onPressed,
    required this.isFullWidth,
    required this.height,
    required this.padding,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: isFullWidth ? double.infinity : null,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: isDark
              ? VColors.glassBackgroundDark
              : VColors.glassBackground,
          borderRadius: BorderRadius.circular(VRadius.md),
          border: Border.all(
            color: isDark
                ? VColors.glassBorderDark
                : VColors.glassBorder,
          ),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

enum ButtonVariant { filled, outlined, text, tonal, glass }
enum ButtonSize { small, medium, large }
