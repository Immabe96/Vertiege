import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/post.dart';
import '../../router/world_navigation.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/verified_moment.dart';

/// Public standing posts on a resident profile (Nexus + world feed).
class ProfileStandingGrid extends StatelessWidget {
  final List<Post> posts;
  final int maxVisible;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;

  const ProfileStandingGrid({
    super.key,
    required this.posts,
    this.maxVisible = 9,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final visible = posts.take(maxVisible).toList();
    final overflow = posts.length - visible.length;

    if (posts.isEmpty) {
      return Text(
        'No standing posts yet.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: isDark
              ? VColors.onSurfaceVariantDark
              : VColors.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.hub_outlined, size: VIconSize.md, color: VColors.primary),
            const SizedBox(width: VSpacing.xs),
            Text(
              'Standing',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: VFontWeight.semiBold,
              ),
            ),
            const Spacer(),
            if (overflow > 0)
              Text(
                '+$overflow more',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? VColors.onSurfaceVariantDark
                      : VColors.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: VSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            const columns = 3;
            const spacing = VSpacing.xs;
            final cellWidth =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;
            const aspect = 1.05;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: visible.map((post) {
                return _StandingCell(
                  post: post,
                  width: cellWidth,
                  height: cellWidth * aspect,
                  isDark: isDark,
                  onTap: () => context.push(
                    exploreWorldPath(post.worldId, postId: post.id),
                  ),
                );
              }).toList(),
            );
          },
        ),
        if (hasMore && onLoadMore != null) ...[
          const SizedBox(height: VSpacing.md),
          Align(
            alignment: Alignment.center,
            child: TextButton.icon(
              onPressed: isLoadingMore ? null : onLoadMore,
              icon: isLoadingMore
                  ? SizedBox(
                      width: VIconSize.sm,
                      height: VIconSize.sm,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: VColors.primary,
                      ),
                    )
                  : const Icon(Icons.expand_more, size: VIconSize.md),
              label: Text(isLoadingMore ? 'Loading…' : 'Load more standing'),
            ),
          ),
        ],
      ],
    );
  }
}

class _StandingCell extends StatelessWidget {
  final Post post;
  final double width;
  final double height;
  final bool isDark;
  final VoidCallback onTap;

  const _StandingCell({
    required this.post,
    required this.width,
    required this.height,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final verified = isVerifiedMomentPost(post);
    final snippet = post.content.trim();
    final preview = snippet.isEmpty
        ? 'Post'
        : (snippet.length > 72 ? '${snippet.substring(0, 72)}…' : snippet);

    return Material(
      color: isDark
          ? VCommuneColors.surfaceSecondary
          : VCommuneColors.surfaceSecondaryLight,
      borderRadius: BorderRadius.circular(VRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: width,
          height: height,
          child: Padding(
            padding: const EdgeInsets.all(VSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (verified)
                  Row(
                    children: [
                      Icon(
                        Icons.verified,
                        size: VIconSize.sm,
                        color: VColors.brand,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Verified',
                        style: TextStyle(
                          fontSize: VFontSize.labelSm,
                          fontWeight: VFontWeight.semiBold,
                          color: VColors.brand,
                        ),
                      ),
                    ],
                  ),
                Expanded(
                  child: Text(
                    preview,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: VFontSize.labelSm,
                      color: isDark
                          ? VCommuneColors.textNormal
                          : VCommuneColors.textNormalLight,
                      height: 1.25,
                    ),
                  ),
                ),
                if (post.reactions.isNotEmpty)
                  Text(
                    '${post.reactions.values.fold<int>(0, (a, b) => a + b)} reactions',
                    style: TextStyle(
                      fontSize: VFontSize.labelSm,
                      color: isDark
                          ? VCommuneColors.textMuted
                          : VCommuneColors.textMutedLight,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
