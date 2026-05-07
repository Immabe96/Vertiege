import 'package:flutter/material.dart';
import '../../theme/colors.dart';

enum AccessIconType { locked, unlocked, denied }

class AccessIcon extends StatelessWidget {
  final AccessIconType type;
  final double size;

  const AccessIcon({super.key, this.type = AccessIconType.locked, this.size = 24});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      AccessIconType.unlocked => (Icons.lock_open, AppColors.semanticSuccess),
      AccessIconType.locked => (Icons.lock, AppColors.primary),
      AccessIconType.denied => (Icons.block, AppColors.semanticError),
    };

    return Icon(icon, size: size, color: color);
  }
}
