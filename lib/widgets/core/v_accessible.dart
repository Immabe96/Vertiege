import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../theme/v_tokens.dart';

/// Icon-only header action with tooltip, semantics, and ~48dp tap target.
class VAccessibleHeaderAction extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onPress;

  const VAccessibleHeaderAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: SizedBox(
          width: VTouchTarget.minimum,
          height: VTouchTarget.minimum,
          child: Center(
            child: FHeaderAction(icon: icon, onPress: onPress),
          ),
        ),
      ),
    );
  }
}

/// Minimum tap target for custom tappable chips/tiles.
class VMinTapTarget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticsLabel;

  const VMinTapTarget({
    super.key,
    required this.child,
    this.onTap,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: VTouchTarget.minimum,
        minHeight: VTouchTarget.minimum,
      ),
      child: Center(child: child),
    );
    if (semanticsLabel != null) {
      content = Semantics(
        button: onTap != null,
        label: semanticsLabel,
        child: content,
      );
    }
    if (onTap == null) return content;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VRadius.pill),
        child: content,
      ),
    );
  }
}
