import 'package:flutter/material.dart';
import '../../ui/cards/v_card.dart';
import 'screen_loading.dart';
import 'shimmer.dart';
import '../../theme/v_tokens.dart';

class VLoadingCard extends StatelessWidget {
  const VLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const VCard(
      padding: EdgeInsets.all(VSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Pulse(width: 150, height: VFontSize.headlineMd),
          SizedBox(height: VSpacing.sm),
          Pulse(height: VFontSize.bodyMd),
          SizedBox(height: VSpacing.xs),
          Pulse(height: VFontSize.bodyMd),
          SizedBox(height: VSpacing.md),
          Row(
            children: [
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
