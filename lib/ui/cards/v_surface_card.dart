import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../theme/v_tokens.dart';

/// Forui card shell for list tiles and form sections.
class VSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const VSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(VSpacing.md),
  });

  @override
  Widget build(BuildContext context) {
    return FCard.raw(
      child: Padding(padding: padding, child: child),
    );
  }
}
