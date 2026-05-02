import 'package:flutter/material.dart';

class AppSearchBar extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChangeText;
  final String placeholder;

  const AppSearchBar({
    super.key,
    required this.value,
    required this.onChangeText,
    this.placeholder = 'Search...',
  });

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      hintText: placeholder,
      onChanged: onChangeText,
      leading: const Icon(Icons.search),
    );
  }
}
