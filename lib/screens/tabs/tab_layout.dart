import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:vertiege/ui/ui.dart';
import '../../state/commune_shell_provider.dart';
import '../../state/chat_provider.dart';
import '../../state/notification_provider.dart';
import '../../state/tab_shell_overlay_provider.dart';
import '../../state/resident_provider.dart';
import '../../widgets/core/campfire_mini_bar.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/v_motion.dart';
import '../../utils/v_haptics.dart';
import '../../widgets/core/glass_sheet.dart';
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

  /// All 4 shell branches are visible tabs (Explore is no longer a shell branch).
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

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final footerBorder = isDark ? VColors.outlineDark : VColors.outline;

    return ColoredBox(
      color: isDark ? VColors.surfaceDark : VColors.surface,
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
                          label: 'Compose post',
                          button: true,
                          child: FButton.icon(
                            variant: FButtonVariant.primary,
                            onPress: fabConfig.onPressed,
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
      maxSize: 0.95,
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

  static const _destinations = [
    (
      icon: Icons.hub_outlined,
      activeIcon: Icons.hub,
      label: 'Nexus',
      semanticsLabel: 'Nexus',
    ),
    (
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: 'Chat',
      semanticsLabel: 'Messages',
    ),
    (
      icon: Icons.emoji_events_outlined,
      activeIcon: Icons.emoji_events,
      label: 'Achievements',
      semanticsLabel: 'Achievements',
    ),
    (
      icon: Icons.account_circle_outlined,
      activeIcon: Icons.account_circle,
      label: 'Identity',
      semanticsLabel: 'Identity',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return VBottomNavigationBar(
      index: index,
      onChange: onTabTap,
      safeAreaBottom: true,
      children: [
        for (var i = 0; i < _destinations.length; i++)
          _navItem(
            dest: _destinations[i],
            showBadge: (i == 0 && nexusUnread > 0) || (i == 1 && chatUnread > 0),
            badgeCount: i == 0 ? nexusUnread : chatUnread,
            outlined: _destinations[i].icon,
            filled: _destinations[i].activeIcon,
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
