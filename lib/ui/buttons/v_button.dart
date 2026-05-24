import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../theme/v_context_colors.dart';
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
    if (variant == ButtonVariant.glass) {
      return _GlassButton(
        label: label,
        onPressed: isLoading ? null : onPressed,
        isFullWidth: isFullWidth,
        isLoading: isLoading,
        icon: icon,
        size: size,
      );
    }

    final fVariant = switch (variant) {
      ButtonVariant.filled => FButtonVariant.primary,
      ButtonVariant.outlined => FButtonVariant.outline,
      ButtonVariant.text => FButtonVariant.ghost,
      ButtonVariant.tonal => FButtonVariant.secondary,
      ButtonVariant.glass => FButtonVariant.primary,
    };

    final fSize = switch (size) {
      ButtonSize.small => FButtonSizeVariant.sm,
      ButtonSize.medium => FButtonSizeVariant.md,
      ButtonSize.large => FButtonSizeVariant.lg,
    };

    final child = _ButtonLabel(
      label: label,
      isLoading: isLoading,
      icon: icon,
      variant: variant,
    );

    final button = FButton(
      variant: fVariant,
      size: fSize,
      onPress: isLoading ? null : onPressed,
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      child: child,
    );

    return isFullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}

class _ButtonLabel extends StatelessWidget {
  final String label;
  final bool isLoading;
  final Widget? icon;
  final ButtonVariant variant;

  const _ButtonLabel({
    required this.label,
    required this.isLoading,
    this.icon,
    required this.variant,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: FCircularProgress(),
      );
    }

    if (icon == null) return Text(label);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        icon!,
        const SizedBox(width: VSpacing.sm),
        Text(label),
      ],
    );
  }
}

class _GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isFullWidth;
  final bool isLoading;
  final Widget? icon;
  final ButtonSize size;

  const _GlassButton({
    required this.label,
    this.onPressed,
    required this.isFullWidth,
    required this.isLoading,
    this.icon,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final height = switch (size) {
      ButtonSize.small => 36.0,
      ButtonSize.medium => 44.0,
      ButtonSize.large => 52.0,
    };

    final padding = switch (size) {
      ButtonSize.small => const EdgeInsets.symmetric(horizontal: VSpacing.md),
      ButtonSize.medium => const EdgeInsets.symmetric(horizontal: VSpacing.xl),
      ButtonSize.large => const EdgeInsets.symmetric(horizontal: VSpacing.xxl),
    };

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: isFullWidth ? double.infinity : null,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: context.vSurfaceContainer,
          borderRadius: BorderRadius.circular(VRadius.md),
          border: Border.all(color: context.vOutlineVariant),
        ),
        alignment: Alignment.center,
        child: _ButtonLabel(
          label: label,
          isLoading: isLoading,
          icon: icon,
          variant: ButtonVariant.glass,
        ),
      ),
    );
  }
}

enum ButtonVariant { filled, outlined, text, tonal, glass }
enum ButtonSize { small, medium, large }
