import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/notification_provider.dart';
import '../../state/resident_provider.dart';
import '../../state/voice_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
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
  late AnimationController _fabController;
  late Animation<double> _fabScale;
  late Animation<double> _fabRotation;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: VAnimation.normal,
      vsync: this,
    );
    _fabScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeOutBack),
    );
    _fabRotation = Tween<double>(begin: 0.0, end: 0.25).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeOut),
    );
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
    final fabConfig = _fabForTab(index, ref);

    if (index != _previousIndex) {
      _previousIndex = index;
      if (fabConfig != null) {
        _fabController.forward(from: 0.0);
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          widget.navigationShell,
          _FloatingCampfireBar(),
        ],
      ),
      floatingActionButton: fabConfig != null
          ? ScaleTransition(
              scale: _fabScale,
              child: RotationTransition(
                turns: _fabRotation,
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: FloatingActionButton(
                    onPressed: fabConfig.onPressed,
                    backgroundColor: fabConfig.backgroundColor,
                    foregroundColor: fabConfig.foregroundColor,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(VRadius.lg),
                    ),
                    child: Icon(fabConfig.icon, size: VIconSize.lg),
                  ),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _GlassNavBar(
        index: index,
        unread: unread,
        onTabTap: (i) {
          HapticFeedback.lightImpact();
          if (i == index) {
            ref.read(scrollToTopProvider.notifier).increment();
          }
          widget.navigationShell.goBranch(
            i,
            initialLocation: i == index,
          );
        },
      ),
    );
  }

  _FabConfig? _fabForTab(int index, WidgetRef ref) {
    // Only show compose FAB on Nexus tab (index 0).
    // Create-world moved to Explore page UI. New DM in Chat page header.
    // Edit profile accessible from Identity page.
    if (index != 0) return null;
    return _FabConfig(
      icon: Icons.edit,
      backgroundColor: VColors.primary,
      foregroundColor: VColors.onPrimary,
      onPressed: () => _showComposeModal(context),
    );
  }

  void _showComposeModal(BuildContext context) {
    final resident = ref.read(residentProvider).resident;
    final worldId = resident?.joinedWorldIds.isNotEmpty == true
        ? resident!.joinedWorldIds.first
        : 'nexus';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => PostInput(worldId: worldId, showWorldSelector: true),
    );
  }
}

class _GlassNavBar extends ConsumerWidget {
  final int index;
  final int unread;
  final void Function(int) onTabTap;

  const _GlassNavBar({
    required this.index,
    required this.unread,
    required this.onTabTap,
  });

  static const _destinations = [
    (icon: Icons.hub_outlined, activeIcon: Icons.hub, label: 'Nexus'),
    (icon: Icons.explore_outlined, activeIcon: Icons.explore, label: 'Discover'),
    (
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: 'Chat',
    ),
    (
      icon: Icons.account_circle_outlined,
      activeIcon: Icons.account_circle,
      label: 'Identity',
    ),
    (icon: Icons.more_horiz, activeIcon: Icons.more_horiz, label: 'More'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(VSpacing.lg, 0, VSpacing.lg, VSpacing.sm),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(VRadius.xl),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: isDark
                  ? VColors.surfaceContainerDark
                  : VColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(VRadius.xl),
              border: Border.all(
                color: isDark
                    ? VColors.outlineVariantDark
                    : VColors.outlineVariant,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? VColors.dark : VColors.onSurface).withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: List.generate(_destinations.length, (i) {
                final isActive = i == index;
                final dest = _destinations[i];

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTabTap(i),
                    child: AnimatedContainer(
                      duration: VAnimation.fast,
                      margin: const EdgeInsets.symmetric(
                        horizontal: VSpacing.xs,
                        vertical: VSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? (isDark
                                ? VColors.primaryContainerDark
                                : VColors.primaryContainer)
                                .withValues(alpha: 0.4)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(VRadius.md),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              AnimatedSwitcher(
                                duration: VAnimation.fast,
                                transitionBuilder: (child, animation) {
                                  return ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  );
                                },
                                child: Icon(
                                  isActive ? dest.activeIcon : dest.icon,
                                  key: ValueKey(isActive),
                                  size: VIconSize.lg,
                                  color: isActive
                                      ? (isDark
                                          ? VColors.primaryLight
                                          : VColors.primary)
                                      : (isDark
                                          ? VColors.onSurfaceVariantDark
                                          : VColors.onSurfaceVariant),
                                ),
                              ),
                              if (i == 0 && unread > 0)
                                Positioned(
                                  top: -2,
                                  right: -4,
                                  child: _UnreadBadge(count: unread),
                                ),
                            ],
                          ),
                          const SizedBox(height: VSpacing.xxs),
                          AnimatedDefaultTextStyle(
                            duration: VAnimation.fast,
                            style: TextStyle(
                              fontSize: VFontSize.labelSm,
                              fontWeight: isActive
                                  ? VFontWeight.semiBold
                                  : VFontWeight.regular,
                              color: isActive
                                  ? (isDark
                                      ? VColors.primaryLight
                                      : VColors.primary)
                                  : (isDark
                                      ? VColors.onSurfaceVariantDark
                                      : VColors.onSurfaceVariant),
                            ),
                            child: Text(dest.label),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingCampfireBar extends ConsumerWidget {
  const _FloatingCampfireBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voice = ref.watch(voiceProvider);
    if (!voice.isConnected) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Positioned(
      top: VSpacing.xl,
      left: VSpacing.lg,
      right: VSpacing.lg,
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {
              final campfireId = voice.activeCampfireId;
              final campfireName = voice.activeCampfireName ?? 'Campfire';
              if (campfireId != null) {
                final encodedName = Uri.encodeComponent(campfireName);
                context.push('/campfire/$campfireId?name=$encodedName');
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.md,
                vertical: VSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? VColors.surfaceContainerDark
                    : VColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(VRadius.pill),
                border: Border.all(
                  color: isDark
                      ? VColors.outlineVariantDark
                      : VColors.outlineVariant,
                ),
                boxShadow: VShadow.lg,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: VColors.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: VSpacing.sm),
                  Flexible(
                    child: Text(
                      voice.activeCampfireName ?? 'Campfire',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: VFontWeight.semiBold,
                        color: isDark
                            ? VColors.onSurfaceDark
                            : VColors.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: VSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VSpacing.xs,
                      vertical: VSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: (isDark
                              ? VColors.primaryContainerDark
                              : VColors.primaryContainer)
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(VRadius.pill),
                    ),
                    child: Text(
                      '${voice.participants.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: VFontWeight.semiBold,
                        color: isDark
                            ? VColors.primaryLight
                            : VColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: VSpacing.sm),
                  GestureDetector(
                    onTap: () =>
                        ref.read(voiceProvider.notifier).leaveCampfire(),
                    child: Container(
                      width: VTouchTarget.iconButton,
                      height: VTouchTarget.iconButton,
                      decoration: BoxDecoration(
                        color: VColors.error.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.call_end,
                        size: VIconSize.sm,
                        color: VColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
