import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Inline info / status alert (Forui-backed).
class VAlert extends StatelessWidget {
  final Widget? icon;
  final Widget title;
  final Widget? subtitle;

  const VAlert({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return FAlert(
      variant: FAlertVariant.primary,
      icon: icon ?? const SizedBox.shrink(),
      title: title,
      subtitle: subtitle,
    );
  }
}
