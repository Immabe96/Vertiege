import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Nested [FHeader] with optional back/action prefixes (chat, thread, Campfire).
class VNestedHeader extends StatelessWidget {
  final Widget title;
  final List<Widget> prefixes;
  final List<Widget> suffixes;

  const VNestedHeader({
    super.key,
    required this.title,
    this.prefixes = const [],
    this.suffixes = const [],
  });

  @override
  Widget build(BuildContext context) {
    return FHeader.nested(
      title: title,
      prefixes: prefixes,
      suffixes: suffixes,
    );
  }
}
