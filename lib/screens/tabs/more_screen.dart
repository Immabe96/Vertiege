import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../forui/v_hub_page.dart';
import '../../theme/v_tokens.dart';
import '../../widgets/v_section_list.dart';

/// Secondary navigation hub — accessible via the More tab.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VHubPage(
      title: 'More',
      body: ListView(
        padding: const EdgeInsets.all(VSpacing.md),
        children: [
          VSectionList(
            title: 'Your Journey',
            children: [
              VSectionTile(
                icon: Icons.emoji_events,
                label: 'Achievements',
                onTap: () => context.push('/achievements'),
              ),
              VSectionTile(
                icon: Icons.trending_up,
                label: 'Ascension Path',
                onTap: () => context.push('/ascension-path'),
              ),
              VSectionTile(
                icon: Icons.leaderboard,
                label: 'Hall of Ascension',
                onTap: () => context.push('/hall-of-ascension'),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.md),
          VSectionList(
            title: 'Account',
            children: [
              VSectionTile(
                icon: Icons.shopping_bag,
                label: 'Cosmetics Shop',
                onTap: () => context.push('/shop'),
              ),
              VSectionTile(
                icon: Icons.workspace_premium,
                label: 'Subscription',
                onTap: () => context.push('/subscription'),
              ),
              VSectionTile(
                icon: Icons.settings,
                label: 'Settings',
                onTap: () => context.push('/settings'),
              ),
              VSectionTile(
                icon: Icons.notifications,
                label: 'Notifications',
                onTap: () => context.push('/notifications'),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.md),
          VSectionList(
            title: 'Explore',
            children: [
              VSectionTile(
                icon: Icons.public,
                label: 'Discover Worlds',
                onTap: () => context.push('/explore/discover'),
              ),
              VSectionTile(
                icon: Icons.search,
                label: 'Search',
                onTap: () => context.push('/search'),
              ),
              VSectionTile(
                icon: Icons.emoji_events,
                label: 'Challenges',
                onTap: () => context.push('/challenges'),
              ),
              VSectionTile(
                icon: Icons.groups,
                label: 'Leagues',
                onTap: () => context.push('/leagues'),
              ),
              VSectionTile(
                icon: Icons.calendar_month,
                label: 'Season',
                onTap: () => context.push('/season'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
