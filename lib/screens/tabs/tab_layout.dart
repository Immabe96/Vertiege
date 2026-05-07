import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/notification_provider.dart';
import '../../state/resident_provider.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';
import '../../utils/haptics.dart';
import '../../widgets/feed/post_input.dart';

final scrollToTopProvider = StateProvider<int>((ref) => 0);

class TabLayout extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const TabLayout({super.key, required this.navigationShell});

  @override
  ConsumerState<TabLayout> createState() => _TabLayoutState();
}

class _TabLayoutState extends ConsumerState<TabLayout> {
  static const _destinations = [
    (icon: Icons.hub, label: 'NEXUS'),
    (icon: Icons.explore, label: 'WORLDS'),
    (icon: Icons.chat_bubble, label: 'CHAT'),
    (icon: Icons.account_circle, label: 'IDENTITY'),
  ];

  @override
  Widget build(BuildContext context) {
    final unread = ref
        .watch(notificationProvider)
        .notifications
        .where((n) => !n.read)
        .length;
    final index = widget.navigationShell.currentIndex;

    final showFab = index == 0 || index == 1;

    return Scaffold(
      body: widget.navigationShell,
      floatingActionButton: showFab
          ? SizedBox(
              width: 48,
              height: 48,
              child: FloatingActionButton(
                onPressed: () => _showComposeModal(context),
                backgroundColor: AppColors.tertiary,
                foregroundColor: AppColors.onTertiary,
                elevation: 0,
                shape: const CircleBorder(),
                child: const Icon(Icons.edit, size: IconSizes.md),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomBar(index, unread),
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

  Widget _buildBottomBar(int index, int unread) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Spacing.marginMobile, Spacing.sm, Spacing.marginMobile, Spacing.sm),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(RadiusTokens.full),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer.withAlpha(220),
              borderRadius: BorderRadius.circular(RadiusTokens.full),
              border: const Border(
                top: BorderSide(color: AppColors.glassBorder),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.canvas.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
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
                    onTap: () {
                      Haptics.selection();
                      if (i == index) {
                        ref.read(scrollToTopProvider.notifier).state++;
                      }
                      widget.navigationShell.goBranch(i, initialLocation: i == index);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          dest.icon,
                          size: IconSizes.md,
                          color: isActive ? AppColors.tertiary : AppColors.inkMuted,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          dest.label,
                          style: TextStyle(
                            fontSize: FontSizes.labelSm,
                            fontWeight: isActive ? FontWeights.semiBold : FontWeights.regular,
                            color: isActive ? AppColors.tertiary : AppColors.inkMuted,
                            letterSpacing: LetterSpacing.label,
                          ),
                        ),
                      ],
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
