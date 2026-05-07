import 'package:flutter/material.dart';
import '../../config/cosmetics.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';

class Badge extends StatelessWidget {
  final String decorationId;

  const Badge({super.key, required this.decorationId});

  @override
  Widget build(BuildContext context) {
    final label = decorationLabels[decorationId] ?? 'Verified Professional';

    return Chip(
      avatar: const Icon(Icons.star, size: 16),
      label: Text(label, style: const TextStyle(fontSize: FontSizes.micro)),
      backgroundColor: AppColors.surfaceHigh,
      side: BorderSide.none,
      padding: const EdgeInsets.all(4),
    );
  }
}
