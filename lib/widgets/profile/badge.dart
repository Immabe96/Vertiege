import 'package:flutter/material.dart';
import '../../config/cosmetics.dart';

class Badge extends StatelessWidget {
  final String decorationId;

  const Badge({super.key, required this.decorationId});

  @override
  Widget build(BuildContext context) {
    final label = decorationLabels[decorationId] ?? 'Verified Professional';
    final theme = Theme.of(context);

    return Chip(
      avatar: const Icon(Icons.star, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      backgroundColor: theme.colorScheme.primaryContainer,
      side: BorderSide.none,
      padding: const EdgeInsets.all(4),
    );
  }
}
