import 'package:flutter/material.dart';

enum AccessIconType { locked, unlocked, denied }

class AccessIcon extends StatelessWidget {
  final AccessIconType type;
  final double size;

  const AccessIcon({super.key, this.type = AccessIconType.locked, this.size = 24});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      AccessIconType.unlocked => (Icons.lock_open, Colors.green),
      AccessIconType.locked => (Icons.lock, Theme.of(context).colorScheme.primary),
      AccessIconType.denied => (Icons.block, Theme.of(context).colorScheme.error),
    };

    return Icon(icon, size: size, color: color);
  }
}
