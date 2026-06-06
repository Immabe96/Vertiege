import 'package:flutter/material.dart';

import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';
import '../icons/v_icons.dart';

/// Commune search field with optional filter chips (DCX-113).
class VSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final List<VSearchFilterChip> filters;
  final bool autofocus;

  const VSearchBar({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText = 'Search worlds, residents, posts…',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.filters = const [],
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark
        ? VCommuneColors.surfaceSecondary
        : VCommuneColors.surfaceSecondaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(VRadius.lg),
            border: Border.all(
              color: isDark
                  ? VCommuneColors.dividerSubtle
                  : VCommuneColors.dividerSubtleLight,
            ),
          ),
          child: Row(
            children: [
              Icon(
                VIcons.search,
                size: VIconSize.md,
                color: isDark
                    ? VCommuneColors.textMuted
                    : VCommuneColors.textMutedLight,
              ),
              const SizedBox(width: VSpacing.sm),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: autofocus,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? VCommuneColors.textNormal
                        : VCommuneColors.textNormalLight,
                  ),
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? VCommuneColors.textMuted
                          : VCommuneColors.textMutedLight,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: VSpacing.sm,
                    ),
                  ),
                ),
              ),
              if (controller.text.isNotEmpty && onClear != null)
                IconButton(
                  icon: const Icon(VIcons.x, size: VIconSize.md),
                  onPressed: onClear,
                  tooltip: 'Clear search',
                ),
            ],
          ),
        ),
        if (filters.isNotEmpty) ...[
          const SizedBox(height: VSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < filters.length; i++) ...[
                  if (i > 0) const SizedBox(width: VSpacing.xs),
                  filters[i],
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class VSearchFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const VSearchFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        fontWeight: selected ? VFontWeight.bold : VFontWeight.medium,
        color: selected
            ? theme.colorScheme.onPrimary
            : (isDark
                ? VCommuneColors.textMuted
                : VCommuneColors.textMutedLight),
      ),
      selectedColor: theme.colorScheme.primary,
      backgroundColor: isDark
          ? VCommuneColors.surfaceSecondaryAlt
          : VCommuneColors.surfaceSecondaryAltLight,
      side: BorderSide(
        color: selected
            ? theme.colorScheme.primary
            : (isDark
                ? VCommuneColors.dividerSubtle
                : VCommuneColors.dividerSubtleLight),
      ),
      padding: const EdgeInsets.symmetric(horizontal: VSpacing.xs),
    );
  }
}
