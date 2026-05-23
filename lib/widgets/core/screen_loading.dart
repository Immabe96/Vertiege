import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
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
          padding: const EdgeInsets.all(VSpacing.md),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: VSpacing.md,
            crossAxisSpacing: VSpacing.md,
            childAspectRatio: 0.85,
          ),
          itemCount: itemCount,
          itemBuilder: (_, _) => VSurfacePanel(
            padding: const EdgeInsets.all(VSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Pulse(width: double.infinity, height: 14),
                SizedBox(height: VSpacing.sm),
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
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.md,
        vertical: VSpacing.sm,
      ),
      child: VSurfacePanel(
        padding: const EdgeInsets.all(VSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Pulse(width: 48, height: 48, borderRadius: VRadius.pill),
            const SizedBox(width: VSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: VSpacing.xs),
                  Pulse(
                    width: MediaQuery.of(context).size.width * 0.35,
                    height: VFontSize.bodyMd,
                    borderRadius: VRadius.sm,
                  ),
                  const SizedBox(height: VSpacing.sm),
                  const Pulse(borderRadius: VRadius.sm),
                  const SizedBox(height: VSpacing.xs),
                  Pulse(
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: 14,
                    borderRadius: VRadius.sm,
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
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.md,
        vertical: VSpacing.sm + 2,
      ),
      child: VSurfacePanel(
        padding: const EdgeInsets.all(VSpacing.md),
        child: Row(
          children: [
            const Pulse(width: 56, height: 56, borderRadius: VRadius.pill),
            const SizedBox(width: VSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Pulse(
                    width: MediaQuery.of(context).size.width * 0.3,
                    height: VFontSize.bodyMd,
                    borderRadius: VRadius.sm,
                  ),
                  const SizedBox(height: VSpacing.xs + 2),
                  Pulse(
                    width: MediaQuery.of(context).size.width * 0.55,
                    height: VFontSize.bodyMd,
                    borderRadius: VRadius.sm,
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
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.lg,
        vertical: VSpacing.xl,
      ),
      child: VSurfacePanel(
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
              borderRadius: VRadius.sm,
            ),
            const SizedBox(height: VSpacing.sm),
            const Pulse(
              width: 100,
              height: 14,
              borderRadius: VRadius.sm,
            ),
            const SizedBox(height: VSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (_) => const _StatShimmer()),
            ),
            const SizedBox(height: VSpacing.xl),
            const Pulse(height: 14, borderRadius: VRadius.sm),
            const SizedBox(height: VSpacing.sm),
            const Pulse(height: 14, borderRadius: VRadius.sm),
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
        Pulse(width: 48, height: 22, borderRadius: VRadius.sm),
        SizedBox(height: VSpacing.xs),
        Pulse(width: 36, height: 12, borderRadius: VRadius.sm),
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
          padding: const EdgeInsets.all(VSpacing.md),
          child: VSurfacePanel(
            padding: const EdgeInsets.all(VSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Pulse(
                  width: 200,
                  height: 24,
                  borderRadius: VRadius.sm,
                ),
                const SizedBox(height: VSpacing.sm),
                const Pulse(
                  width: 120,
                  height: 14,
                  borderRadius: VRadius.sm,
                ),
                const SizedBox(height: VSpacing.lg),
                const Pulse(height: 14, borderRadius: VRadius.sm),
                const SizedBox(height: VSpacing.sm),
                const Pulse(height: 14, borderRadius: VRadius.sm),
                const SizedBox(height: VSpacing.sm),
                const Pulse(
                  width: 200,
                  height: 14,
                  borderRadius: VRadius.sm,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
