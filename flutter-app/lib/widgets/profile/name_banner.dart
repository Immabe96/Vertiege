import 'package:flutter/material.dart';
import '../../config/cosmetics.dart';
import '../../theme/v_tokens.dart';

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
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.lg,
            vertical: VSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: cosmetic.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(VRadius.md),
            border: Border.all(color: cosmetic.color.withValues(alpha: 0.3)),
          ),
          child: Text(
            name,
            style: TextStyle(
              color: cosmetic.color,
              fontWeight: VFontWeight.bold,
              fontSize: VFontSize.headlineMd,
            ),
          ),
        );
      }
    }

    return Text(name, style: theme.textTheme.titleMedium);
  }
}
