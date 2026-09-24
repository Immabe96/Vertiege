import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../models/world.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';
import '../../config/tiers.dart';

/// Pinned constitution block at top of #rules channel (DCX-144).
class WorldConstitutionPin extends StatelessWidget {
  final World world;

  const WorldConstitutionPin({super.key, required this.world});

  String _markdown() {
    final c = world.constitution;
    final admission = switch (c.admission) {
      'invite' => 'Invite-only admission',
      'application' => 'Application required',
      'paid' => 'Paid entry',
      _ => 'Open admission',
    };
    final tierLine = c.minTier != null
        ? 'Minimum tier: ${tierNames[c.minTier] ?? 'Tier ${c.minTier}'} (${c.minTier})'
        : null;
    final professionLine = c.requiredProfession != null
        ? 'Required profession: ${c.requiredProfession}'
        : null;
    final posting = c.posting == 'council-only'
        ? 'Council-only posting'
        : 'All residents may post';
    final commenting = c.commenting == 'council-only'
        ? 'Council-only comments'
        : 'All residents may comment';

    return '''
### World constitution (pinned)

**$admission**  
${tierLine != null ? '$tierLine  \n' : ''}${professionLine != null ? '$professionLine  \n' : ''}$posting · $commenting  
Content: ${c.contentTypes.join(', ')}${c.entryFee > 0 ? ' · Entry fee: ${c.entryFee} coins' : ''}

This charter governs how residents join, post, and participate. Council updates are logged in governance.
''';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        VSpacing.md,
        VSpacing.sm,
        VSpacing.md,
        VSpacing.xs,
      ),
      padding: const EdgeInsets.all(VSpacing.md),
      decoration: BoxDecoration(
        color: VCommuneColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(VRadius.lg),
        border: Border.all(color: VColors.tertiary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.push_pin, size: VIconSize.sm, color: VColors.tertiary),
              SizedBox(width: VSpacing.xs),
              Text(
                'Pinned · Constitution',
                style: TextStyle(
                  fontSize: VFontSize.labelSm,
                  fontWeight: VFontWeight.bold,
                  color: VColors.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.sm),
          MarkdownBody(
            data: _markdown(),
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                color: VCommuneColors.textNormal,
                fontSize: VFontSize.bodySm,
                height: 1.35,
              ),
              strong: const TextStyle(
                color: VCommuneColors.headerPrimary,
                fontWeight: VFontWeight.bold,
              ),
              h3: const TextStyle(
                color: VCommuneColors.headerPrimary,
                fontSize: VFontSize.bodyLg,
                fontWeight: VFontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
