import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/notification_provider.dart';
import '../../state/resident_provider.dart';
import '../../state/voice_provider.dart';
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [const _CampfireBar(), _buildBottomBar(index, unread)],
      ),
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
        padding: const EdgeInsets.fromLTRB(
          Spacing.marginMobile,
          Spacing.sm,
          Spacing.marginMobile,
          Spacing.sm,
        ),
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
                      widget.navigationShell.goBranch(
                        i,
                        initialLocation: i == index,
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              dest.icon,
                              size: IconSizes.md,
                              color: isActive
                                  ? AppColors.tertiary
                                  : AppColors.inkMuted,
                            ),
                            if (i == 0 && unread > 0)
                              Positioned(
                                top: -6,
                                right: -8,
                                child: _UnreadBadge(count: unread),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          dest.label,
                          style: TextStyle(
                            fontSize: FontSizes.labelSm,
                            fontWeight: isActive
                                ? FontWeights.semiBold
                                : FontWeights.regular,
                            color: isActive
                                ? AppColors.tertiary
                                : AppColors.inkMuted,
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

class _CampfireBar extends ConsumerWidget {
  const _CampfireBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voice = ref.watch(voiceProvider);
    if (!voice.isConnected) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        final campfireId = voice.activeCampfireId;
        final campfireName = voice.activeCampfireName ?? 'Campfire';
        if (campfireId != null) {
          final encodedName = Uri.encodeComponent(campfireName);
          context.push('/campfire/$campfireId?name=$encodedName');
        }
      },
      child: Container(
        height: 40,
        color: AppColors.warning.withValues(alpha: 0.12),
        child: Row(
          children: [
            const SizedBox(width: Spacing.lg),
            const Icon(
              Icons.local_fire_department,
              color: AppColors.warning,
              size: IconSizes.sm,
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                voice.activeCampfireName ?? 'Campfire',
                style: const TextStyle(
                  fontSize: FontSizes.labelSm,
                  fontWeight: FontWeights.semiBold,
                  color: AppColors.warning,
                ),
              ),
            ),
            Text(
              '${voice.participants.length}',
              style: const TextStyle(
                fontSize: FontSizes.labelSm,
                color: AppColors.warning,
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.call_end,
                size: IconSizes.sm,
                color: AppColors.error,
              ),
              onPressed: () => ref.read(voiceProvider.notifier).leaveCampfire(),
            ),
          ],
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
        color: AppColors.error,
        borderRadius: BorderRadius.all(Radius.circular(999)),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 9 ? '9+' : '$count',
        style: const TextStyle(
          color: AppColors.onError,
          fontSize: 9,
          fontWeight: FontWeights.bold,
        ),
      ),
    );
  }
}
