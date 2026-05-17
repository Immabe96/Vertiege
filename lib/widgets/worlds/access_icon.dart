import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';

enum AccessIconType { locked, unlocked, denied }

class AccessIcon extends StatelessWidget {
  final AccessIconType type;
  final double size;

  const AccessIcon({
    super.key,
    this.type = AccessIconType.locked,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      AccessIconType.unlocked => (Icons.lock_open, VColors.success),
      AccessIconType.locked => (Icons.lock, VColors.primary),
      AccessIconType.denied => (Icons.block, VColors.error),
    };

    return Icon(icon, size: size, color: color);
  }
}
