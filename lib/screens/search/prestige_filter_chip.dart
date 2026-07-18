import 'package:flutter/material.dart';

import '../../theme/prestige_noir.dart';
import '../../theme/v_tokens.dart';

class PrestigeFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const PrestigeFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? PrestigeNoir.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? PrestigeNoir.accent : PrestigeNoir.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: VFontSize.labelSm,
            fontWeight: selected ? VFontWeight.semiBold : VFontWeight.medium,
            color: selected ? PrestigeNoir.accent : PrestigeNoir.muted,
          ),
        ),
      ),
    );
  }
}
