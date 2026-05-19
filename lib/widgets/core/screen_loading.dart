import 'package:forui/forui.dart';
import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/design_system.dart';
import 'glass_panel.dart';
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
            (_) => const _GlassPostCardShimmer(),
          ),
        );
      case ScreenLoadingType.list:
        return Column(
          children: List.generate(
            itemCount,
            (_) => const _GlassChatTileShimmer(),
          ),
        );
      case ScreenLoadingType.grid:
        return GridView.builder(

          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: Spacing.md,
            crossAxisSpacing: Spacing.md,
            childAspectRatio: 0.85,
          ),
          itemCount: itemCount,
          itemBuilder: (_, _) => FCard(

            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Pulse(width: double.infinity, height: 14),
                SizedBox(height: Spacing.sm),
                Pulse(width: 80, height: 12),
              ],
            ),
          ),
        );
      case ScreenLoadingType.profile:
        return _ProfileShimmer();
      case ScreenLoadingType.detail:
        return _DetailShimmer();
    }
  }
}

// ──────────────────────────────────────────────────────────────
// Glass-styled shimmer placeholders
// ──────────────────────────────────────────────────────────────

class _GlassPostCardShimmer extends StatelessWidget {
  const _GlassPostCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(

        vertical: Spacing.sm,
      ),
      child: FCard(

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Pulse(width: 48, height: 48,
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: Spacing.xs),
                  Pulse(
                    width: MediaQuery.of(context).size.width * 0.35,
                    height: FontSizes.body,

                  ),
                  const SizedBox(height: Spacing.sm),
                  const Pulse(
                  const SizedBox(height: Spacing.xs),
                  Pulse(
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: 14,

                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassChatTileShimmer extends StatelessWidget {
  const _GlassChatTileShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(

        vertical: Spacing.sm + 2,
      ),
      child: FCard(

        child: Row(
          children: [
            const Pulse(width: 56, height: 56,
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Pulse(
                    width: MediaQuery.of(context).size.width * 0.3,
                    height: FontSizes.body,

                  ),
                  const SizedBox(height: Spacing.xs + 2),
                  Pulse(
                    width: MediaQuery.of(context).size.width * 0.55,
                    height: FontSizes.body,

                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileShimmer extends StatelessWidget {
  const _ProfileShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(

        vertical: Spacing.xl,
      ),
      child: FCard(

        child: Column(
          children: [
            const Center(
              child: Pulse(
                width: 80,
                height: 80,

              ),
            ),
            const SizedBox(height: Spacing.lg),
            const Pulse(
              width: 160,
              height: 20,

            ),
            const SizedBox(height: Spacing.sm),
            const Pulse(
              width: 100,
              height: 14,

            ),
            const SizedBox(height: Spacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (_) => const _StatShimmer()),
            ),
            const SizedBox(height: Spacing.xl),
            const Pulse(height: 14,
            const SizedBox(height: Spacing.sm),
            const Pulse(height: 14,
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
    return Column(
      children: const [
        Pulse(width: 48, height: 22,
        SizedBox(height: Spacing.xs),
        Pulse(width: 36, height: 12,
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
        Padding(

          child: FCard(

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Pulse(
                  width: 200,
                  height: 24,

                ),
                const SizedBox(height: Spacing.sm),
                const Pulse(
                  width: 120,
                  height: 14,

                ),
                const SizedBox(height: Spacing.lg),
                const Pulse(height: 14,
                const SizedBox(height: Spacing.sm),
                const Pulse(height: 14,
                const SizedBox(height: Spacing.sm),
                const Pulse(
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
