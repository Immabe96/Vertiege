import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/notification_provider.dart';
import '../../state/resident_provider.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';
import '../../widgets/feed/post_input.dart';

final scrollToTopProvider = StateProvider<int>((ref) => 0);

class TabLayout extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const TabLayout({super.key, required this.navigationShell});

  @override
  ConsumerState<TabLayout> createState() => _TabLayoutState();
}

class _TabLayoutState extends ConsumerState<TabLayout>
    with TickerProviderStateMixin {
  bool _speedDialOpen = false;

  late final AnimationController _badgePulseController;
  late final AnimationController _speedDialController;
  late final Animation<double> _overlayOpacity;

  // Staggered animations for each speed-dial option.
  late final List<Animation<double>> _optionAnimations;

  @override
  void initState() {
    super.initState();

    // ── Badge pulse ────────────────────────────────────────
    _badgePulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    // Only start pulsing when there are unread notifications (handled in build).
    _badgePulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        final unread = ref
            .read(notificationProvider)
            .notifications
            .where((n) => !n.read)
            .length;
        if (unread > 0 && mounted) {
          _badgePulseController.repeat(reverse: true);
        }
      }
    });

    // ── Speed dial ─────────────────────────────────────────
    _speedDialController = AnimationController(
      duration: AnimDurations.normal,
      vsync: this,
    );
    _overlayOpacity = CurvedAnimation(
      parent: _speedDialController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _optionAnimations = List.generate(3, (i) {
      return CurvedAnimation(
        parent: _speedDialController,
        curve: Interval(
          0.1 + (i * 0.1),
          0.6 + (i * 0.1),
          curve: Curves.easeOutBack,
        ),
      );
    });
  }

  @override
  void dispose() {
    _badgePulseController.dispose();
    _speedDialController.dispose();
    super.dispose();
  }

  // ── Speed-dial actions ──────────────────────────────────

  void _openSpeedDial() {
    HapticFeedback.mediumImpact();
    setState(() => _speedDialOpen = true);
    _speedDialController.forward();
  }

  void _dismissSpeedDial() {
    _speedDialController.reverse().then((_) {
      if (mounted) setState(() => _speedDialOpen = false);
    });
  }

  void _onNewPost() {
    _dismissSpeedDial();
    // Navigate to Nexus tab where the feed lives, then show the composer.
    widget.navigationShell.goBranch(0);
    final resident = ref.read(residentProvider).resident;
    final worldId = resident?.joinedWorldIds.isNotEmpty == true
        ? resident!.joinedWorldIds.first
        : 'global';
    Future.delayed(AnimDurations.fast, () {
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(RadiusTokens.xl)),
        ),
        builder: (_) => PostInput(worldId: worldId),
      );
    });
  }

  void _onCreateWorld() {
    _dismissSpeedDial();
    context.push('/create-world');
  }

  void _onStartChat() {
    _dismissSpeedDial();
    widget.navigationShell.goBranch(2);
  }

  // ── Tab destinations ────────────────────────────────────

  static const _destinations = [
    (icon: Icons.explore_outlined, activeIcon: Icons.explore, label: 'Nexus'),
    (icon: Icons.public_outlined, activeIcon: Icons.public, label: 'Explore'),
    (icon: Icons.chat_outlined, activeIcon: Icons.chat, label: 'Chats'),
    (icon: Icons.person_outline, activeIcon: Icons.person, label: 'Identity'),
    (icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'Alerts'),
  ];

  static const _speedDialOptions = [
    (icon: Icons.edit, label: 'New Post'),
    (icon: Icons.public, label: 'Create World'),
    (icon: Icons.chat_bubble_outline, label: 'Start Chat'),
  ];

  // ── Speed-dial layout constants ─────────────────────────
  static const double _fabSize = 56;
  static const double _optionButtonSize = 44;
  static const double _arcRadius = 90;
  // Angles from vertical (straight up = 0): fan from -55° to +55°.
  static const List<double> _arcAngles = [-0.96, 0.0, 0.96]; // ~-55°, 0°, +55° in radians

  // ── Build ───────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final unread =
        ref.watch(notificationProvider).notifications.where((n) => !n.read).length;
    final theme = Theme.of(context);
    final index = widget.navigationShell.currentIndex;
    final isDark = theme.brightness == Brightness.dark;

    // Manage badge pulse: start when there are unread, stop when zero.
    if (unread > 0 && !_badgePulseController.isAnimating) {
      _badgePulseController.repeat(reverse: true);
    } else if (unread == 0 && _badgePulseController.isAnimating) {
      _badgePulseController.stop();
      _badgePulseController.reset();
    }

    // ── Speed-dial action callbacks ────────────────────
    final actions = <VoidCallback>[_onNewPost, _onCreateWorld, _onStartChat];

    return Stack(
      children: [
        // ── Main scaffold ──────────────────────────────────
        Scaffold(
          body: widget.navigationShell,
          bottomNavigationBar: _buildBottomBar(theme, index, unread, isDark),
        ),

        // ── Dim overlay when speed dial is open ────────────
        if (_speedDialOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _dismissSpeedDial,
              child: FadeTransition(
                opacity: _overlayOpacity,
                child: Container(color: Colors.black.withValues(alpha: 0.55)),
              ),
            ),
          ),

        // ── Speed-dial option buttons ──────────────────────
        if (_speedDialOpen)
          ..._buildSpeedDialOptions(actions, isDark),
      ],
    );
  }

  // ── Bottom bar ────────────────────────────────────────────

  Widget _buildBottomBar(
    ThemeData theme,
    int index,
    int unread,
    bool isDark,
  ) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.sm, Spacing.md, Spacing.md),
        child: SizedBox(
          height: 60,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth;
              final tabWidth = barWidth / _destinations.length;
              const indicatorWidth = 48.0;
              final indicatorLeft =
                  index * tabWidth + (tabWidth - indicatorWidth) / 2;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // ── Bar background ───────────────────────
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(RadiusTokens.xl),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: AppColors.alphaBorder),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withValues(alpha: 0.10),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),

                  // ── Spring-animated pill indicator ───────
                  AnimatedPositioned(
                    duration: AnimDurations.slow,
                    curve: AnimCurves.spring,
                    left: indicatorLeft,
                    top: 6,
                    child: Container(
                      width: indicatorWidth,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(RadiusTokens.lg),
                      ),
                    ),
                  ),

                  // ── Tab items ────────────────────────────
                  Row(
                    children: List.generate(_destinations.length, (i) {
                      final isActive = i == index;
                      final dest = _destinations[i];

                      return Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            if (i == index) {
                              ref
                                  .read(scrollToTopProvider.notifier)
                                  .state++;
                            }
                            widget.navigationShell.goBranch(
                              i,
                              initialLocation: i == index,
                            );
                          },
                          child: Semantics(
                            label: dest.label,
                            selected: isActive,
                            button: true,
                            child: _buildTabItem(
                              theme,
                              isActive,
                              isDark,
                              dest,
                              i,
                              unread,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  // ── Center FAB ───────────────────────────
                  Positioned(
                    left: barWidth / 2 - _fabSize / 2,
                    top: -_fabSize / 2,
                    child: GestureDetector(
                      onTap: _openSpeedDial,
                      child: Container(
                        width: _fabSize,
                        height: _fabSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: AppColors.gradientPrimary,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: ShadowTokens.lg,
                        ),
                        child: AnimatedRotation(
                          turns: _speedDialOpen ? 0.125 : 0.0, // 45° rotation
                          duration: AnimDurations.fast,
                          curve: Curves.easeOutBack,
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Single tab item ──────────────────────────────────────

  Widget _buildTabItem(
    ThemeData theme,
    bool isActive,
    bool isDark,
    ({IconData icon, IconData activeIcon, String label}) dest,
    int i,
    int unread,
  ) {
    final icon = Icon(
      isActive ? dest.activeIcon : dest.icon,
      size: IconSizes.md,
      color: isActive
          ? theme.colorScheme.primary
          : theme.colorScheme.onSurfaceVariant,
    );

    final label = Text(
      dest.label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
        color: isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Icon (with optional badge)
        if (i == 4 && unread > 0)
          _PulsingBadge(
            animation: _badgePulseController,
            label: unread > 99 ? '99+' : '$unread',
            child: icon,
          )
        else
          icon,

        // Label — always present in layout, fades opacity for active state
        SizedBox(height: isActive ? 3 : 2),
        AnimatedOpacity(
          duration: AnimDurations.fast,
          opacity: isActive ? 1.0 : 0.0,
          child: label,
        ),
      ],
    );
  }

  // ── Speed-dial options ───────────────────────────────────

  List<Widget> _buildSpeedDialOptions(
    List<VoidCallback> actions,
    bool isDark,
  ) {
    final bottomBarHeight = 60.0 +
        MediaQuery.of(context).padding.bottom +
        Spacing.md +
        Spacing.sm;
    final fabCenterX = MediaQuery.of(context).size.width / 2;
    // FAB center sits at the top edge of the bottom bar.
    final fabCenterY = MediaQuery.of(context).size.height - bottomBarHeight;

    return List.generate(_speedDialOptions.length, (i) {
      final angle = _arcAngles[i];
      final dx = _arcRadius * math.sin(angle);
      final dy = -_arcRadius * math.cos(angle);

      return Positioned(
        left: fabCenterX + dx - _optionButtonSize / 2,
        top: fabCenterY + dy - _optionButtonSize / 2,
        child: ScaleTransition(
          scale: _optionAnimations[i],
          child: FadeTransition(
            opacity: _optionAnimations[i],
            child: _SpeedDialOption(
              icon: _speedDialOptions[i].icon,
              label: _speedDialOptions[i].label,
              onTap: () {
                HapticFeedback.lightImpact();
                actions[i]();
              },
              isDark: isDark,
            ),
          ),
        ),
      );
    });
  }
}

// ── Pulsing badge wrapper ──────────────────────────────────

class _PulsingBadge extends StatelessWidget {
  final AnimationController animation;
  final String label;
  final Widget child;

  const _PulsingBadge({
    required this.animation,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final scale = 1.0 + (animation.value * 0.3);
        return Transform.scale(
          scale: scale,
          child: Badge(
            label: Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.white),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

// ── Single speed-dial option ───────────────────────────────

class _SpeedDialOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _SpeedDialOption({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label (to the left of the icon button, for left-side options)
          // We alternate placement based on position. For simplicity,
          // show label to the left always.
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm,
              vertical: Spacing.xs,
            ),
            decoration: BoxDecoration(
              color: (isDark ? Colors.grey[900] : Colors.grey[100])!
                  .withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(RadiusTokens.sm),
              boxShadow: ShadowTokens.sm,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: FontSizes.caption,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          // Circular icon button
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: AppColors.gradientPrimary,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: ShadowTokens.md,
            ),
            child: Icon(icon, color: Colors.white, size: IconSizes.md),
          ),
        ],
      ),
    );
  }
}
