import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HapticTab extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const HapticTab({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: child,
    );
  }
}
