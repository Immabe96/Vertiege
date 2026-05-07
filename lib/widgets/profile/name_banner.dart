import 'package:flutter/material.dart';
import '../../config/cosmetics.dart';
import '../../theme/design_system.dart';

class NameBanner extends StatelessWidget {
  final String? profession;
  final String name;

  const NameBanner({super.key, this.profession, required this.name});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (profession != null) {
      final cosmetic = professionCosmetics[profession];
      if (cosmetic != null) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.sm),
          decoration: BoxDecoration(
            color: cosmetic.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(RadiusTokens.cardFeatured),
            border: Border.all(color: cosmetic.color.withValues(alpha: 0.3)),
          ),
          child: Text(name, style: TextStyle(color: cosmetic.color, fontWeight: FontWeights.bold, fontSize: FontSizes.headingCard)),
        );
      }
    }

    return Text(name, style: theme.textTheme.titleMedium);
  }
}
