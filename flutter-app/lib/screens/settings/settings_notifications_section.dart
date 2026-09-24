import 'package:flutter/material.dart';

import 'package:vertiege/ui/ui.dart';
import 'settings_prestige_section.dart';

/// Notification preference switches for push, likes, comments, etc.
class SettingsNotificationsSection extends StatelessWidget {
  const SettingsNotificationsSection({
    super.key,
    required this.prefsLoaded,
    required this.pushEnabled,
    required this.likesEnabled,
    required this.commentsEnabled,
    required this.worldInvitesEnabled,
    required this.tierUpgradesEnabled,
    required this.onPushChanged,
    required this.onLikesChanged,
    required this.onCommentsChanged,
    required this.onWorldInvitesChanged,
    required this.onTierUpgradesChanged,
  });

  final bool prefsLoaded;
  final bool pushEnabled;
  final bool likesEnabled;
  final bool commentsEnabled;
  final bool worldInvitesEnabled;
  final bool tierUpgradesEnabled;
  final ValueChanged<bool> onPushChanged;
  final ValueChanged<bool> onLikesChanged;
  final ValueChanged<bool> onCommentsChanged;
  final ValueChanged<bool> onWorldInvitesChanged;
  final ValueChanged<bool> onTierUpgradesChanged;

  @override
  Widget build(BuildContext context) {
    return SettingsPrestigeSection(
      title: 'Notifications',
      children: [
        VSectionSwitchTile(
          icon: Icons.notifications_active,
          label: 'Push Notifications',
          value: pushEnabled,
          onChanged: prefsLoaded ? onPushChanged : null,
        ),
        VSectionSwitchTile(
          icon: Icons.favorite_border,
          label: 'Likes',
          value: likesEnabled,
          onChanged: prefsLoaded ? onLikesChanged : null,
        ),
        VSectionSwitchTile(
          icon: Icons.mode_comment_outlined,
          label: 'Comments',
          value: commentsEnabled,
          onChanged: prefsLoaded ? onCommentsChanged : null,
        ),
        VSectionSwitchTile(
          icon: VIcons.globe,
          label: 'World Invites',
          value: worldInvitesEnabled,
          onChanged: prefsLoaded ? onWorldInvitesChanged : null,
        ),
        VSectionSwitchTile(
          icon: Icons.military_tech,
          label: 'Tier Upgrades',
          value: tierUpgradesEnabled,
          onChanged: prefsLoaded ? onTierUpgradesChanged : null,
        ),
      ],
    );
  }
}
