import 'package:forui/forui.dart';
import 'package:flutter/material.dart';
import 'glass_panel.dart';
import 'shimmer.dart';
import '../../theme/design_system.dart';

class GlassLoadingCard extends StatelessWidget {
  const GlassLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return FCard(

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Pulse(width: 150, height: FontSizes.headlineMd),
          const SizedBox(height: Spacing.sm),
          const Pulse(height: FontSizes.bodyMd),
          const SizedBox(height: Spacing.xs),
          const Pulse(width: double.infinity, height: FontSizes.bodyMd),
          const SizedBox(height: Spacing.md),
          Row(
            children: const [
              Pulse(width: 60, height: 20),
              SizedBox(width: Spacing.sm),
              Pulse(width: 40, height: 20),
            ],
          ),
        ],
      ),
    );
  }
}

class GlassLoadingList extends StatelessWidget {
  final int itemCount;
  const GlassLoadingList({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(

      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm + 4),
      itemBuilder: (_, _) => const GlassLoadingCard(),
    );
  }
}
