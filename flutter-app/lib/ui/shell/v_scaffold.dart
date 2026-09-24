import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Full-screen Forui scaffold without header (e.g. world detail, chat).
class VScaffold extends StatelessWidget {
  final Widget child;
  final bool childPad;
  final Widget? header;
  final Widget? footer;

  const VScaffold({
    super.key,
    required this.child,
    this.childPad = true,
    this.header,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      childPad: childPad,
      header: header,
      footer: footer,
      child: child,
    );
  }
}
