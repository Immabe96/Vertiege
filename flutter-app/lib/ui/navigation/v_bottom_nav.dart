import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Root tab bar (Forui-backed). Pair with [VBottomNavigationBarItem].
class VBottomNavigationBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChange;
  final List<Widget> children;
  final bool safeAreaBottom;

  const VBottomNavigationBar({
    super.key,
    required this.index,
    required this.onChange,
    required this.children,
    this.safeAreaBottom = true,
  });

  @override
  Widget build(BuildContext context) {
    return FBottomNavigationBar(
      index: index,
      onChange: onChange,
      safeAreaBottom: safeAreaBottom,
      children: children,
    );
  }
}

class VBottomNavigationBarItem extends StatelessWidget {
  final Widget icon;
  final Widget label;

  const VBottomNavigationBarItem({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return FBottomNavigationBarItem(icon: icon, label: label);
  }
}

/// Whether the enclosing [VBottomNavigationBar] item is selected.
bool vBottomNavItemSelected(BuildContext context) {
  return FBottomNavigationBarData.of(context).selected;
}
