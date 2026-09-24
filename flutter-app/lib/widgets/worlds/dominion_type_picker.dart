import 'package:flutter/material.dart';
import '../../config/world_page_ia.dart';
import '../../models/world.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/icons/v_icons.dart';

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose world type',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: VFontWeight.bold,
          ),
        ),
        const SizedBox(height: VSpacing.xs),
        Text(
          'Community for discussion, or Shop for marketplace and treasury.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: VSpacing.lg),
        ...WorldPageIa.userCreatableDominions.map((type) {
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(VSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : (VColors.surfaceContainerDark),
          borderRadius: BorderRadius.circular(VRadius.lg),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _typeColor(context, type).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(VRadius.md),
              ),
              child: Icon(
                _typeIcon(type),
                size: VIconSize.lg,
                color: _typeColor(context, type),
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
                      color: isSelected ? Theme.of(context).colorScheme.primary : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    type.lore,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(VIcons.badgeCheck, color: Theme.of(context).colorScheme.primary, size: VIconSize.md),
          ],
        ),
      ),
    );
  }

  Color _typeColor(BuildContext context, DominionType type) {
    switch (type) {
      case DominionType.marketplace:
        return VColors.tertiary;
      case DominionType.academy:
        return Theme.of(context).colorScheme.primary;
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
