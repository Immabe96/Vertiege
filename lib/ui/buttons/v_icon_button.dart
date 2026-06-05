import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Icon-only Forui button (e.g. create-world icon picker).
class VIconButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool selected;

  const VIconButton({
    super.key,
    required this.child,
    this.onPressed,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return FButton.icon(
      variant: selected ? FButtonVariant.primary : FButtonVariant.outline,
      onPress: onPressed,
      child: child,
    );
  }
}
