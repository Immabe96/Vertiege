import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Header toolbar action (Forui-backed). Use in [VPage.headerActions].
class VHeaderAction extends StatelessWidget {
  final Widget icon;
  final VoidCallback onPress;

  const VHeaderAction({
    super.key,
    required this.icon,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return FHeaderAction(icon: icon, onPress: onPress);
  }
}
