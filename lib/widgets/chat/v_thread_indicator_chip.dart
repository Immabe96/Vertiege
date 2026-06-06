import 'package:flutter/material.dart';

import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';

/// Thread reply count chip — tap opens the thread.
class VThreadIndicatorChip extends StatelessWidget {
  final int replyCount;
  final String? previewText;
  final VoidCallback? onTap;

  const VThreadIndicatorChip({
    super.key,
    required this.replyCount,
    this.previewText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (replyCount <= 0) return const SizedBox.shrink();

    final label = replyCount == 1 ? '1 reply' : '$replyCount replies';

    return Padding(
      padding: const EdgeInsets.only(top: VSpacing.xs),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(VRadius.sm),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.sm,
              vertical: VSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: VCommuneColors.surfaceTertiary,
              borderRadius: BorderRadius.circular(VRadius.sm),
              border: Border.all(color: VCommuneColors.dividerSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.forum_outlined,
                      size: 14,
                      color: VCommuneColors.textLink,
                    ),
                    const SizedBox(width: VSpacing.xs),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: VFontSize.labelSm,
                        fontWeight: VFontWeight.semiBold,
                        color: VCommuneColors.textLink,
                      ),
                    ),
                  ],
                ),
                if (previewText != null && previewText!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    previewText!,
                    style: const TextStyle(
                      fontSize: VFontSize.labelSm,
                      color: VCommuneColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
