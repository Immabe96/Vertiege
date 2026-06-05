import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class VSelectItem<T> {
  final T value;
  final Widget title;

  const VSelectItem({required this.value, required this.title});
}

/// Forui-backed select dropdown (lifted control).
class VSelect<T> extends StatelessWidget {
  final T? value;
  final ValueChanged<T?> onChanged;
  final String hint;
  final Widget? label;
  final List<VSelectItem<T>> items;
  final String Function(T value)? format;

  const VSelect({
    super.key,
    required this.value,
    required this.onChanged,
    required this.hint,
    required this.items,
    this.label,
    this.format,
  });

  @override
  Widget build(BuildContext context) {
    return FSelect<T>.rich(
      format: format ?? (value) => value.toString(),
      control: FSelectControl.lifted(value: value, onChange: onChanged),
      label: label,
      hint: hint,
      children: [
        for (final item in items)
          FSelectItem<T>(value: item.value, title: item.title),
      ],
    );
  }
}
