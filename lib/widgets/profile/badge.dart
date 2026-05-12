import 'package:flutter/material.dart';
import '../../config/cosmetics.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';
import '../../utils/world_assets.dart';

class Badge extends StatelessWidget {
  final String decorationId;

  const Badge({super.key, required this.decorationId});

  @override
  Widget build(BuildContext context) {
    final label = decorationLabels[decorationId] ?? 'Verified Professional';
    final imagePath = WorldAssets.badgeImageForId(decorationId);

    return Chip(
      avatar: imagePath != null
          ? ClipOval(
              child: Image.asset(
                imagePath,
                width: 22,
                height: 22,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(Icons.star, size: 16),
              ),
            )
          : const Icon(Icons.star, size: 16),
      label: Text(label, style: const TextStyle(fontSize: FontSizes.micro)),
      backgroundColor: AppColors.surfaceHigh,
      side: BorderSide.none,
      padding: const EdgeInsets.all(4),
    );
  }
}
