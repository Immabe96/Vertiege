import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/world.dart';
import '../../theme/v_colors.dart';
import 'world_tools_panel.dart';

/// End drawer — delegates to [WorldToolsPanel].
class WorldToolsDrawer extends ConsumerWidget {
  final World world;
  final String worldId;
  final bool isJoined;
  final bool isAdminOrCouncil;
  final VoidCallback onShare;
  final VoidCallback? onSettings;
  final VoidCallback onOpenRealmGuide;

  const WorldToolsDrawer({
    super.key,
    required this.world,
    required this.worldId,
    required this.isJoined,
    required this.isAdminOrCouncil,
    required this.onShare,
    this.onSettings,
    required this.onOpenRealmGuide,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? VColors.surfaceDark : VColors.surface,
      child: SafeArea(
        child: WorldToolsPanel(
          world: world,
          worldId: worldId,
          isJoined: isJoined,
          isAdminOrCouncil: isAdminOrCouncil,
          onDismiss: () => Navigator.pop(context),
          onShare: onShare,
          onSettings: onSettings,
          onOpenRealmGuide: onOpenRealmGuide,
        ),
      ),
    );
  }
}
