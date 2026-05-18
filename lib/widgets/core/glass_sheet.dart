import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// A bottom sheet wrapper using forui's FSheet.
class GlassSheet extends StatelessWidget {
  final Widget child;

  const GlassSheet({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

/// Shows a modal sheet using forui's [showFSheet].
void showGlassSheet(
  BuildContext context,
  Widget child, {
  double initialSize = 0.7,
  double minSize = 0.25,
  double maxSize = 0.95,
}) {
  showFSheet(
    context: context,
    side: FLayout.btt,
    mainAxisMaxRatio: maxSize,
    draggable: true,
    barrierDismissible: true,
    builder: (_) => SingleChildScrollView(child: child),
  );
}
