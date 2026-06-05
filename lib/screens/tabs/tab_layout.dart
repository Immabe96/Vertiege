import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vertiege/ui/ui.dart';
import '../../state/commune_shell_provider.dart';
import '../../state/notification_provider.dart';
import '../../widgets/core/campfire_mini_bar.dart';
import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/v_haptics.dart';

class ScrollToTopNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state++;
}

final scrollToTopProvider = NotifierProvider<ScrollToTopNotifier, int>(
  ScrollToTopNotifier.new,
);

class TabLayout extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const TabLayout({super.key, required this.navigationShell});

  @override
  ConsumerState<TabLayout> createState() => _TabLayoutState();
}

class _TabLayoutState extends ConsumerState<TabLayout> {
  /// Shell branch indices for the 3 visible tabs (Home, Notifications, You).
  static const _branchForTab = [0, 4, 3];

  int _visibleTabIndex(int shellIndex) {
    final i = _branchForTab.indexOf(shellIndex);
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final unread = ref
        .watch(notificationProvider)
        .notifications
        .where((n) => !n.read)
        .length;
    final shellIndex = widget.navigationShell.currentIndex;
    final tabIndex = _visibleTabIndex(shellIndex);
    final hideNav = ref.watch(hideBottomNavProvider);

    return ColoredBox(
      color: VCommuneColors.surfaceTertiary,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                widget.navigationShell,
                const CampfireMiniBar(),
              ],
            ),
          ),
          if (!hideNav)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: VCommuneColors.dividerSubtle)),
              ),
              child: _MainBottomNav(
                index: tabIndex,
                unread: unread,
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
}

class _MainBottomNav extends StatelessWidget {
  final int index;
  final int unread;
  final void Function(int) onTabTap;

  const _MainBottomNav({
    required this.index,
    required this.unread,
    required this.onTabTap,
  });

  static const _destinations = [
    (
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
      semanticsLabel: 'Home',
    ),
    (
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications,
      label: 'Alerts',
      semanticsLabel: 'Notifications',
    ),
    (
      icon: Icons.account_circle_outlined,
      activeIcon: Icons.account_circle,
      label: 'You',
      semanticsLabel: 'You',
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
            showBadge: i == 1 && unread > 0,
            badgeCount: unread,
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
        color: VCommuneColors.statusDnd,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        count > 9 ? '9+' : '$count',
        style: const TextStyle(
          color: VCommuneColors.headerPrimary,
          fontSize: VFontSize.labelSm,
          fontWeight: VFontWeight.bold,
        ),
      ),
    );
  }
}
