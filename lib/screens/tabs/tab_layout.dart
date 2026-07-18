import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vertiege/l10n/app_localizations.dart';
import 'package:vertiege/ui/ui.dart';
import '../../state/commune_shell_provider.dart';
import '../../state/chat_provider.dart';
import '../../state/notification_provider.dart';
import '../../state/tab_shell_overlay_provider.dart';
import '../../state/resident_provider.dart';
import '../../widgets/core/campfire_mini_bar.dart';
import '../../theme/prestige_noir.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/v_haptics.dart';
import '../../widgets/feed/post_input.dart';

class ScrollToTopNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state++;
}

final scrollToTopProvider = NotifierProvider<ScrollToTopNotifier, int>(
  ScrollToTopNotifier.new,
);

class _FabConfig {
  final IconData icon;
  final VoidCallback onPressed;

  const _FabConfig({
    required this.icon,
    required this.onPressed,
  });
}

class TabLayout extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const TabLayout({super.key, required this.navigationShell});

  @override
  ConsumerState<TabLayout> createState() => _TabLayoutState();
}

class _TabLayoutState extends ConsumerState<TabLayout>
    with TickerProviderStateMixin {
  static const Duration _fabAnimDuration = VAnimation.normal;

  /// Shell branches: Nexus (0), Worlds (1), Chat (2), You (3).
  static const _branchForTab = [0, 1, 2, 3];

  late AnimationController _fabController;
  late Animation<double> _fabScale;
  late Animation<double> _fabRotation;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: _fabAnimDuration,
      vsync: this,
    );
    _fabScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeOutBack),
    );
    _fabRotation = Tween<double>(
      begin: 0.0,
      end: 0.25,
    ).animate(CurvedAnimation(parent: _fabController, curve: Curves.easeOut));
    _fabController.forward();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nexusUnread = ref
        .watch(notificationProvider)
        .notifications
        .where((n) => !n.read)
        .length;
    final residentId = ref.watch(residentProvider.select((s) => s.resident?.id));
    final chatUnread = ref.watch(
      chatProvider.select(
        (s) => s.totalChatTabUnread(currentUserId: residentId),
      ),
    );
    final shellIndex = widget.navigationShell.currentIndex;
    final tabIndex = _visibleTabIndex(shellIndex);
    final hideNav = ref.watch(hideBottomNavProvider);
    final overlayBlocksFab = ref.watch(tabShellOverlayProvider) > 0;
    final fabConfig =
        hideNav || overlayBlocksFab ? null : _fabForTab(shellIndex, ref);

    if (shellIndex != _previousIndex) {
      _previousIndex = shellIndex;
      if (fabConfig != null) {
        _fabController.forward(from: 0.0);
      }
    }

    final footerBorder = VColors.outlineVariantDark;

    return ColoredBox(
      color: PrestigeNoir.bg,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                widget.navigationShell,
                const CampfireMiniBar(),
                if (fabConfig != null)
                  Positioned(
                    right: VSpacing.lg,
                    bottom: VSpacing.lg,
                    child: ScaleTransition(
                      scale: _fabScale,
                      child: RotationTransition(
                        turns: _fabRotation,
                        child: Semantics(
                          label: AppLocalizations.of(context).composePost,
                          button: true,
                          child: FloatingActionButton(
                            onPressed: fabConfig.onPressed,
                            backgroundColor: VColors.brand,
                            foregroundColor: VColors.onBrand,
                            elevation: 4,
                            child: Icon(
                              fabConfig.icon,
                              size: VIconSize.lg,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!hideNav)
            DecoratedBox(
              decoration: BoxDecoration(
                color: PrestigeNoir.chrome,
                border: Border(top: BorderSide(color: footerBorder)),
              ),
              child: _MainBottomNav(
                index: tabIndex,
                nexusUnread: nexusUnread,
                chatUnread: chatUnread,
                onTabTap: (visibleIndex) {
                  VHaptics.lightImpact(context);
                  final branch = _branchForTab[visibleIndex];
                  if (branch == shellIndex) {
                    ref.read(scrollToTopProvider.notifier).increment();
                  }
                  widget.navigationShell.goBranch(
                    branch,
                    initialLocation: branch == shellIndex,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  int _visibleTabIndex(int shellIndex) {
    final i = _branchForTab.indexOf(shellIndex);
    if (i < 0) return 0;
    return i;
  }

  _FabConfig? _fabForTab(int shellIndex, WidgetRef ref) {
    if (shellIndex != 0) return null;
    return _FabConfig(
      icon: Icons.edit,
      onPressed: () {
        VHaptics.mediumImpact(context);
        _showComposeModal(context);
      },
    );
  }

  void _showComposeModal(BuildContext context) {
    final resident = ref.read(residentProvider).resident;
    final worldId = resident?.joinedWorldIds.isNotEmpty == true
        ? resident!.joinedWorldIds.first
        : 'nexus';

    showAppSheet(
      context,
      PostInput(worldId: worldId, showWorldSelector: true),
    );
  }
}

class _MainBottomNav extends StatelessWidget {
  final int index;
  final int nexusUnread;
  final int chatUnread;
  final void Function(int) onTabTap;

  const _MainBottomNav({
    required this.index,
    required this.nexusUnread,
    required this.chatUnread,
    required this.onTabTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final destinations = [
      (
        icon: Icons.hub_outlined,
        activeIcon: Icons.hub,
        label: l10n.tabNexus,
        semanticsLabel: l10n.tabNexus,
      ),
      (
        icon: Icons.public_outlined,
        activeIcon: Icons.public,
        label: l10n.tabWorlds,
        semanticsLabel: l10n.tabWorlds,
      ),
      (
        icon: Icons.chat_bubble_outline,
        activeIcon: Icons.chat_bubble,
        label: l10n.tabChat,
        semanticsLabel: l10n.tabChat,
      ),
      (
        icon: Icons.account_circle_outlined,
        activeIcon: Icons.account_circle,
        label: l10n.tabYou,
        semanticsLabel: l10n.tabYou,
      ),
    ];
    return VBottomNavigationBar(
      index: index,
      onChange: onTabTap,
      children: [
        for (var i = 0; i < destinations.length; i++)
          _navItem(
            dest: destinations[i],
            showBadge: (i == 0 && nexusUnread > 0) || (i == 2 && chatUnread > 0),
            badgeCount: i == 0 ? nexusUnread : chatUnread,
            outlined: destinations[i].icon,
            filled: destinations[i].activeIcon,
          ),
      ],
    );
  }

  Widget _navItem({
    required ({
      IconData icon,
      IconData activeIcon,
      String label,
      String semanticsLabel,
    })
    dest,
    required bool showBadge,
    required int badgeCount,
    required IconData outlined,
    required IconData filled,
  }) {
    return Semantics(
      label: dest.semanticsLabel,
      button: true,
      child: VBottomNavigationBarItem(
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            _TabNavIcon(outlined: outlined, filled: filled),
            if (showBadge)
              Positioned(
                top: -2,
                right: -6,
                child: _UnreadBadge(count: badgeCount),
              ),
          ],
        ),
        label: Text(dest.label),
      ),
    );
  }
}

class _TabNavIcon extends StatelessWidget {
  final IconData outlined;
  final IconData filled;

  const _TabNavIcon({required this.outlined, required this.filled});

  @override
  Widget build(BuildContext context) {
    final selected = vBottomNavItemSelected(context);
    return Icon(selected ? filled : outlined);
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        color: VColors.error,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        count > 9 ? '9+' : '$count',
        style: const TextStyle(
          color: VColors.onError,
          fontSize: VFontSize.labelSm,
          fontWeight: VFontWeight.bold,
        ),
      ),
    );
  }
}
