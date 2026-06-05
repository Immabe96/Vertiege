import 'package:flutter/material.dart';
import 'package:vertiege/ui/ui.dart';

import '../../theme/v_tokens.dart';

/// Progressive disclosure wrapper for realm dossier blocks (Wave 17).
class DossierCollapsibleSection extends StatelessWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  const DossierCollapsibleSection({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return VSurfaceCard(
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
          childrenPadding: const EdgeInsets.fromLTRB(
            VSpacing.md,
            0,
            VSpacing.md,
            VSpacing.md,
          ),
          title: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: VFontWeight.bold,
            ),
          ),
          children: [child],
        ),
      ),
    );
  }
}
