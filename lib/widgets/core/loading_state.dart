import 'package:flutter/material.dart';
import 'glass_panel.dart';
import 'screen_loading.dart';
import 'shimmer.dart';
import '../../theme/v_tokens.dart';

class VLoadingCard extends StatelessWidget {
  const VLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return VSurfacePanel(
      padding: const EdgeInsets.all(VSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Pulse(width: 150, height: VFontSize.headlineMd),
          const SizedBox(height: VSpacing.sm),
          const Pulse(height: VFontSize.bodyMd),
          const SizedBox(height: VSpacing.xs),
          const Pulse(width: double.infinity, height: VFontSize.bodyMd),
          const SizedBox(height: VSpacing.md),
          Row(
            children: const [
              Pulse(width: 60, height: 20),
              SizedBox(width: VSpacing.sm),
              Pulse(width: 40, height: 20),
            ],
          ),
        ],
      ),
    );
  }
}

@Deprecated('Use ScreenLoading.list()')
class VLoadingList extends StatelessWidget {
  final int itemCount;
  const VLoadingList({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) => const ScreenLoading.list();
}

@Deprecated('Use VLoadingCard')
typedef GlassLoadingCard = VLoadingCard;

@Deprecated('Use VLoadingList')
typedef GlassLoadingList = VLoadingList;
