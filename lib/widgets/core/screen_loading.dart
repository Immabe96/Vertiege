import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/cards/v_card.dart';
import 'shimmer.dart';

enum ScreenLoadingType { feed, list, grid, profile, detail }

class ScreenLoading extends StatelessWidget {
  final ScreenLoadingType type;
  final int itemCount;

  const ScreenLoading({super.key, required this.type, this.itemCount = 5});

  const ScreenLoading.feed({super.key})
    : type = ScreenLoadingType.feed,
      itemCount = 4;

  const ScreenLoading.list({super.key})
    : type = ScreenLoadingType.list,
      itemCount = 6;

  const ScreenLoading.grid({super.key})
    : type = ScreenLoadingType.grid,
      itemCount = 6;

  const ScreenLoading.profile({super.key})
    : type = ScreenLoadingType.profile,
      itemCount = 1;

  const ScreenLoading.detail({super.key})
    : type = ScreenLoadingType.detail,
      itemCount = 1;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case ScreenLoadingType.feed:
        return Column(
          children: List.generate(
            itemCount,
            (_) => const ShimmerPostCard(),
          ),
        );
      case ScreenLoadingType.list:
        return Column(
          children: List.generate(
            itemCount,
            (_) => const ShimmerChatTile(),
          ),
        );
      case ScreenLoadingType.grid:
        return GridView.builder(
          padding: const EdgeInsets.all(VSpacing.md),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: VSpacing.md,
            crossAxisSpacing: VSpacing.md,
            childAspectRatio: 0.85,
          ),
          itemCount: itemCount,
          itemBuilder: (_, _) => const VCard(
            padding: EdgeInsets.all(VSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Pulse(height: 14),
                SizedBox(height: VSpacing.sm),
                Pulse(width: 80, height: 12),
              ],
            ),
          ),
        );
      case ScreenLoadingType.profile:
        return const _ProfileShimmer();
      case ScreenLoadingType.detail:
        return const _DetailShimmer();
    }
  }
}

class _ProfileShimmer extends StatelessWidget {
  const _ProfileShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.lg,
        vertical: VSpacing.xl,
      ),
      child: VCard(
        padding: const EdgeInsets.all(VSpacing.lg),
        child: Column(
          children: [
            const Center(
              child: Pulse(
                width: 80,
                height: 80,
                borderRadius: VRadius.pill,
              ),
            ),
            const SizedBox(height: VSpacing.lg),
            const Pulse(
              width: 160,
              height: 20,
            ),
            const SizedBox(height: VSpacing.sm),
            const Pulse(
              width: 100,
              height: 14,
            ),
            const SizedBox(height: VSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (_) => const _StatShimmer()),
            ),
            const SizedBox(height: VSpacing.xl),
            const Pulse(height: 14),
            const SizedBox(height: VSpacing.sm),
            const Pulse(height: 14),
          ],
        ),
      ),
    );
  }
}

class _StatShimmer extends StatelessWidget {
  const _StatShimmer();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Pulse(width: 48, height: 22),
        SizedBox(height: VSpacing.xs),
        Pulse(width: 36, height: 12),
      ],
    );
  }
}

class _DetailShimmer extends StatelessWidget {
  const _DetailShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 200,
          color: VColors.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
        const Padding(
          padding: EdgeInsets.all(VSpacing.md),
          child: VCard(
            padding: EdgeInsets.all(VSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Pulse(
                  width: 200,
                  height: 24,
                ),
                SizedBox(height: VSpacing.sm),
                Pulse(
                  width: 120,
                  height: 14,
                ),
                SizedBox(height: VSpacing.lg),
                Pulse(height: 14),
                SizedBox(height: VSpacing.sm),
                Pulse(height: 14),
                SizedBox(height: VSpacing.sm),
                Pulse(
                  width: 200,
                  height: 14,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
