import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vertiege/ui/ui.dart';
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
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  const _FabConfig({
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
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
    final unread = ref
        .watch(notificationProvider)
        .notifications
        .where((n) => !n.read)
        .length;
    final index = widget.navigationShell.currentIndex;
    final overlayBlocksFab = ref.watch(tabShellOverlayProvider) > 0;
    final fabConfig = overlayBlocksFab ? null : _fabForTab(index, ref);

    if (index != _previousIndex) {
      _previousIndex = index;
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
                          child: Material(
                            elevation: 4,
                            color: fabConfig.backgroundColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(VRadius.lg),
                            ),
                            child: InkWell(
                              onTap: fabConfig.onPressed,
                              borderRadius: BorderRadius.circular(VRadius.lg),
                              child: SizedBox(
                                width: 56,
                                height: 56,
                                child: Icon(
                                  fabConfig.icon,
                                  size: VIconSize.lg,
                                  color: fabConfig.foregroundColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: footerBorder)),
            ),
            child: _MainBottomNav(
              index: index,
              unread: unread,
              onTabTap: (i) {
                VHaptics.lightImpact(context);
                if (i == index) {
                  ref.read(scrollToTopProvider.notifier).increment();
                }
                widget.navigationShell.goBranch(i, initialLocation: i == index);
              },
            ),
          ),
        ],
      ),
    );
  }

  _FabConfig? _fabForTab(int index, WidgetRef ref) {
    if (index != 0) return null;
    return _FabConfig(
      icon: Icons.edit,
      backgroundColor: VColors.primary,
      foregroundColor: VColors.onPrimary,
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
  final int unread;
  final void Function(int) onTabTap;

  const _MainBottomNav({
    required this.index,
    required this.unread,
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
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
      label: 'Worlds',
      semanticsLabel: 'Worlds',
    ),
    (
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: 'Chat',
      semanticsLabel: 'Messages',
    ),
    (
      icon: Icons.account_circle_outlined,
      activeIcon: Icons.account_circle,
      label: 'Identity',
      semanticsLabel: 'Identity',
    ),
    (
      icon: Icons.more_horiz,
      activeIcon: Icons.more_horiz,
      label: 'More',
      semanticsLabel: 'More',
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
            showBadge: i == 0 && unread > 0,
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
