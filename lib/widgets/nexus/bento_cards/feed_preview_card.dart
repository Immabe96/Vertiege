import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../state/post_provider.dart';
import '../../../theme/v_colors.dart';
import '../../../theme/design_system.dart';

/// Large card with 2 recent posts + "View All" link.
class FeedPreviewCard extends ConsumerWidget {
  const FeedPreviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postState = ref.watch(postProvider);
    final posts = postState.posts.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: IconSizes.sm,
                  color: VColors.primary,
                ),
                SizedBox(width: Spacing.xs),
                Text(
                  'LATEST POSTS',
                  style: TextStyle(
                    fontSize: FontSizes.labelSm,
                    fontWeight: FontWeights.semiBold,
                    color: VColors.onSurfaceVariant,
                    letterSpacing: LetterSpacing.label,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => context.push('/'),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Compose',
                    style: TextStyle(
                      fontSize: FontSizes.labelSm,
                      color: VColors.primary,
                    ),
                  ),
                  SizedBox(width: Spacing.xs),
                  Icon(
                    Icons.chevron_right,
                    size: IconSizes.sm,
                    color: VColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        if (posts.isEmpty)
          const Text(
            'No posts yet. Be the first!',
            style: TextStyle(
              fontSize: FontSizes.bodyMd,
              color: VColors.outline,
            ),
          )
        else
          ...posts.asMap().entries.map((entry) {
            final index = entry.key;
            final post = entry.value;
            final preview = post.content.length > 80
                ? '${post.content.substring(0, 80)}...'
                : post.content;

            return Padding(
              padding: EdgeInsets.only(
                bottom: index < posts.length - 1 ? Spacing.sm : 0,
              ),
              child: Container(
                padding: const EdgeInsets.all(Spacing.sm),
                decoration: BoxDecoration(
                  color: VColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(RadiusTokens.md),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  post.residentName,
                                  style: const TextStyle(
                                    fontSize: FontSizes.labelSm,
                                    fontWeight: FontWeights.semiBold,
                                    color: VColors.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (post.isAnnouncement) ...[
                                const SizedBox(width: Spacing.xs),
                                const Icon(
                                  Icons.campaign,
                                  size: 12,
                                  color: VColors.warning,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            preview,
                            style: const TextStyle(
                              fontSize: FontSizes.labelSm,
                              color: VColors.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
