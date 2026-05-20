import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

class VCard extends StatelessWidget {
  final Widget? child;
  final Widget? title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool isGlass;
  final Color? backgroundColor;
  final double? borderRadius;

  const VCard({
    super.key,
    this.child,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.padding,
    this.onTap,
    this.isGlass = false,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultBg = backgroundColor ?? (isDark ? VColors.surfaceContainerDark : VColors.surfaceContainerLow);

    final defaultBorder = isGlass
        ? Border.all(
            color: isDark
                ? VColors.outlineVariantDark
                : VColors.outlineVariant,
          )
        : Border.all(
            color: isDark
                ? VColors.outlineVariantDark.withValues(alpha: 0.2)
                : VColors.outlineVariant.withValues(alpha: 0.3),
          );

    final cardContent = Padding(
      padding: padding ?? const EdgeInsets.all(VSpacing.lg),
      child: _buildContent(context),
    );

    final card = Container(
      decoration: BoxDecoration(
        color: defaultBg,
        borderRadius: BorderRadius.circular(borderRadius ?? VRadius.lg),
        border: defaultBorder,
        boxShadow: isGlass ? null : VShadow.sm,
      ),
      child: cardContent,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius ?? VRadius.lg),
          child: card,
        ),
      );
    }

    return card;
  }

  Widget _buildContent(BuildContext context) {
    if (child != null) return child!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: VSpacing.md),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) title!,
              if (subtitle != null) ...[
                const SizedBox(height: VSpacing.xs),
                subtitle!,
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: VSpacing.md),
          trailing!,
        ],
      ],
    );
  }
}
