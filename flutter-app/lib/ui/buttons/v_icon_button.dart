import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../theme/v_tokens.dart';

/// Icon-only Forui button with semantics and minimum tap target (DCX-130).
class VIconButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool selected;
  final String semanticsLabel;
  final String? tooltip;

  const VIconButton({
    super.key,
    required this.child,
    required this.semanticsLabel,
    this.onPressed,
    this.selected = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final label = tooltip ?? semanticsLabel;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticsLabel,
      child: Tooltip(
        message: label,
        child: SizedBox(
          width: VTouchTarget.minimum,
          height: VTouchTarget.minimum,
          child: Center(
            child: FButton.icon(
              variant: selected ? FButtonVariant.primary : FButtonVariant.outline,
              onPress: onPressed,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
