import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../config/progression_glossary.dart';
import '../../config/world_page_ia.dart';
import '../../models/post.dart';
import '../../models/world.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../core/empty_state.dart';
import '../core/progression_help_button.dart';
import 'archive_world_banner.dart';
import 'world_growth_card.dart';

/// Visitor-first Home tab — Facebook Group/Page style landing.
class WorldHomeTab extends StatelessWidget {
  final World world;
  final String worldId;
  final List<Post> worldPosts;
  final bool isJoined;
  final VoidCallback onOpenRealmGuide;
  final VoidCallback onOpenFeed;

  const WorldHomeTab({
    super.key,
    required this.world,
    required this.worldId,
    required this.worldPosts,
    required this.isJoined,
    required this.onOpenRealmGuide,
    required this.onOpenFeed,
  });

  Post? get _adminAnnouncement {
    final sorted = [...worldPosts]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    for (final post in sorted) {
      if (post.isPinned || post.isDecree || post.isAnnouncement) {
        return post;
      }
      if (world.hasSovereign && post.residentId == world.sovereignId) {
        return post;
      }
    }
    return null;
  }

  List<Post> get _discussionPreviews {
    final sorted = [...worldPosts]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final announcement = _adminAnnouncement;
    return sorted
        .where((p) => p.id != announcement?.id)
        .take(2)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final announcement = _adminAnnouncement;
    final previews = _discussionPreviews;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (world.isArchive) const ArchiveWorldBanner(),
        const SizedBox(height: VSpacing.sm),
        _GroupMetaCard(world: world, isDark: isDark),
        WorldGrowthCard(world: world),
        if (announcement != null) ...[
          const SizedBox(height: VSpacing.md),
          _AdminAnnouncementCard(post: announcement, isDark: isDark),
        ],
        if (isJoined) ...[
          const SizedBox(height: VSpacing.md),
          FButton(
            onPress: onOpenFeed,
            child: const Text('Go to feed'),
          ),
        ],
        const SizedBox(height: VSpacing.lg),
        Row(
          children: [
            Text(
              'Recent discussion',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: VFontWeight.bold,
              ),
            ),
            const Spacer(),
            if (previews.isNotEmpty)
              TextButton(
                onPressed: onOpenFeed,
                child: const Text('See all'),
              ),
          ],
        ),
        const SizedBox(height: VSpacing.sm),
        if (previews.isEmpty)
          AppEmptyState(
            title: announcement == null ? 'No posts yet' : 'No other posts yet',
            description:
                'Member posts and admin updates will show up in the feed.',
            icon: Icons.forum_outlined,
          )
        else
          ...previews.map(
            (post) => Padding(
              padding: const EdgeInsets.only(bottom: VSpacing.sm),
              child: _DiscussionPreview(post: post, isDark: isDark),
            ),
          ),
        const SizedBox(height: VSpacing.md),
        TextButton(
          onPressed: onOpenRealmGuide,
          child: const Text('Realm guide, alliances & vault'),
        ),
        ProgressionHelpLink(
          focus: world.type == WorldType.dominion
              ? ProgressionFocus.worldLevel
              : ProgressionFocus.worldPrestige,
        ),
        const SizedBox(height: VSpacing.xl),
      ],
    );
  }
}

/// Group facts — identity lives in [WorldProfileHeader] above the tabs.
class _GroupMetaCard extends StatelessWidget {
  final World world;
  final bool isDark;

  const _GroupMetaCard({
    required this.world,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant;
    final desc = world.description.trim();

    return FCard.raw(
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About this group',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: VFontWeight.bold,
              ),
            ),
            const SizedBox(height: VSpacing.md),
            Wrap(
              spacing: VSpacing.xs,
              runSpacing: VSpacing.xs,
              children: [
                _MetaChip(
                  icon: Icons.people_outline,
                  label: '${world.memberCount} members',
                ),
                _MetaChip(
                  icon: world.constitution.admission == 'open'
                      ? Icons.lock_open
                      : Icons.lock_outline,
                  label: WorldPageIa.visibilityLabel(world),
                ),
                if (world.prestige > 0)
                  _MetaChip(
                    icon: Icons.auto_awesome,
                    label: ProgressionGlossary.worldPrestigeShort(world.prestige),
                  ),
              ],
            ),
            if (world.motto.isNotEmpty) ...[
              const SizedBox(height: VSpacing.sm),
              Text(
                world.motto,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  fontWeight: VFontWeight.medium,
                ),
              ),
            ],
            const SizedBox(height: VSpacing.sm),
            Text(
              desc.isEmpty ? 'No description yet.' : desc,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: muted,
                height: 1.45,
              ),
            ),
            if (world.welcomeMessage.trim().isNotEmpty) ...[
              const SizedBox(height: VSpacing.xs),
              Text(
                world.welcomeMessage,
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.sm,
        vertical: VSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(VRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: VIconSize.sm, color: fg),
          const SizedBox(width: VSpacing.xs),
          Text(
            label,
            style: TextStyle(fontSize: VFontSize.labelSm, color: fg),
          ),
        ],
      ),
    );
  }
}

class _AdminAnnouncementCard extends StatelessWidget {
  final Post post;
  final bool isDark;

  const _AdminAnnouncementCard({
    required this.post,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(VRadius.lg),
        border: Border.all(
          color: VColors.primary.withValues(alpha: 0.45),
          width: 1.5,
        ),
        gradient: LinearGradient(
          colors: [
            VColors.primary.withValues(alpha: isDark ? 0.18 : 0.08),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.campaign,
                  color: VColors.primary,
                  size: VIconSize.md,
                ),
                const SizedBox(width: VSpacing.xs),
                Text(
                  post.isDecree ? 'Admin announcement' : 'Pinned update',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: VColors.primary,
                    fontWeight: VFontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: VSpacing.sm),
            Text(
              post.content,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
            ),
            const SizedBox(height: VSpacing.sm),
            Text(
              post.residentName,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscussionPreview extends StatelessWidget {
  final Post post;
  final bool isDark;

  const _DiscussionPreview({
    required this.post,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant;

    return FCard.raw(
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.residentName,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: VFontWeight.semiBold,
              ),
            ),
            const SizedBox(height: VSpacing.xs),
            Text(
              post.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}
