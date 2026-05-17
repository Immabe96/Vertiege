import 'package:flutter/material.dart';
import '../../models/world.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

class DominionTypePicker extends StatelessWidget {
  final DominionType? selected;
  final ValueChanged<DominionType> onSelected;

  const DominionTypePicker({
    super.key,
    this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Dominion Type',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: VFontWeight.bold,
          ),
        ),
        const SizedBox(height: VSpacing.xs),
        Text(
          'Each type has unique features and identity.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: VSpacing.lg),
        ...DominionType.values.map((type) {
          final isSelected = selected == type;
          return Padding(
            padding: const EdgeInsets.only(bottom: VSpacing.sm),
            child: _DominionTypeCard(
              type: type,
              isSelected: isSelected,
              onTap: () => onSelected(type),
            ),
          );
        }),
      ],
    );
  }
}

class _DominionTypeCard extends StatelessWidget {
  final DominionType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _DominionTypeCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(VSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? VColors.primary.withValues(alpha: 0.1)
              : (isDark ? VColors.surfaceContainerDark : VColors.surfaceContainer),
          borderRadius: BorderRadius.circular(VRadius.lg),
          border: Border.all(
            color: isSelected ? VColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _typeColor(type).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(VRadius.md),
              ),
              child: Icon(
                _typeIcon(type),
                size: VIconSize.lg,
                color: _typeColor(type),
              ),
            ),
            const SizedBox(width: VSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.displayName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: VFontWeight.bold,
                      color: isSelected ? VColors.primary : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    type.lore,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: VColors.primary, size: VIconSize.md),
          ],
        ),
      ),
    );
  }

  Color _typeColor(DominionType type) {
    switch (type) {
      case DominionType.marketplace:
        return VColors.tertiary;
      case DominionType.academy:
        return VColors.primary;
      case DominionType.sanctuary:
        return VColors.success;
      case DominionType.archive:
        return VColors.warning;
    }
  }

  IconData _typeIcon(DominionType type) {
    switch (type) {
      case DominionType.marketplace:
        return Icons.storefront;
      case DominionType.academy:
        return Icons.school;
      case DominionType.sanctuary:
        return Icons.self_improvement;
      case DominionType.archive:
        return Icons.menu_book;
    }
  }
}
