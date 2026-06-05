import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Top app bar for tab roots and hubs (non-nested). See [VNestedHeader] for drill-in.
class VHeader extends StatelessWidget {
  final Widget title;
  final List<Widget> suffixes;

  const VHeader({
    super.key,
    required this.title,
    this.suffixes = const [],
  });

  @override
  Widget build(BuildContext context) {
    return FHeader(title: title, suffixes: suffixes);
  }
}
