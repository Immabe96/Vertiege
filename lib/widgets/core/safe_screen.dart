import 'package:flutter/material.dart';

class SafeScreen extends StatelessWidget {
  final Widget child;
  final bool disableTop;
  final bool disableBottom;

  const SafeScreen({super.key, required this.child, this.disableTop = false, this.disableBottom = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: !disableTop,
        bottom: !disableBottom,
        child: child,
      ),
    );
  }
}
