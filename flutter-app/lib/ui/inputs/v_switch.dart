import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class VSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const VSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FSwitch(value: value, onChange: onChanged);
  }
}
