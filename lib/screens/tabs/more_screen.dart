import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../forui/v_hub_page.dart';
import '../../state/resident_provider.dart';
import '../../theme/v_tokens.dart';
import '../../widgets/v_section_list.dart';

/// Secondary navigation hub — accessible via the More tab.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tier = ref.watch(residentProvider).resident?.tier.value ?? 1;
    return VHubPage(
      title: 'More',
      body: ListView(
        padding: const EdgeInsets.all(VSpacing.md),
        children: [
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
                detail: tier < 2 ? 'Unlocks at High Roller' : null,
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
        ],
      ),
    );
  }
}
