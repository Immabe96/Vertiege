import 'package:flutter/material.dart';

import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';
import '../icons/v_icons.dart';

/// Commune search field with optional filter chips (DCX-113).
class VSearchBar extends StatefulWidget {
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
  State<VSearchBar> createState() => _VSearchBarState();
}

class _VSearchBarState extends State<VSearchBar> {
  FocusNode? _ownedFocus;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? (_ownedFocus = FocusNode());
    _focusNode.addListener(_onFocusChanged);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant VSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode.removeListener(_onFocusChanged);
      _ownedFocus?.dispose();
      _ownedFocus = null;
      _focusNode = widget.focusNode ?? (_ownedFocus = FocusNode());
      _focusNode.addListener(_onFocusChanged);
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    widget.controller.removeListener(_onTextChanged);
    _ownedFocus?.dispose();
    super.dispose();
  }

  void _onFocusChanged() => setState(() {});
  void _onTextChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark
        ? VCommuneColors.surfaceSecondary
        : VCommuneColors.surfaceSecondaryLight;
    final focused = _focusNode.hasFocus;
    final borderColor = focused
        ? theme.colorScheme.primary
        : (isDark
            ? VCommuneColors.dividerSubtle
            : VCommuneColors.dividerSubtleLight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(VRadius.lg),
            border: Border.all(
              color: borderColor,
              width: focused ? 1.5 : 1,
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
                  controller: widget.controller,
                  focusNode: _focusNode,
                  autofocus: widget.autofocus,
                  cursorColor: theme.colorScheme.primary,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? VCommuneColors.textNormal
                        : VCommuneColors.textNormalLight,
                  ),
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? VCommuneColors.textMuted
                          : VCommuneColors.textMutedLight,
                    ),
                    filled: false,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: VSpacing.sm,
                    ),
                  ),
                ),
              ),
              if (widget.controller.text.isNotEmpty && widget.onClear != null)
                IconButton(
                  icon: const Icon(VIcons.x, size: VIconSize.md),
                  onPressed: widget.onClear,
                  tooltip: 'Clear search',
                ),
            ],
          ),
        ),
        if (widget.filters.isNotEmpty) ...[
          const SizedBox(height: VSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < widget.filters.length; i++) ...[
                  if (i > 0) const SizedBox(width: VSpacing.xs),
                  widget.filters[i],
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
