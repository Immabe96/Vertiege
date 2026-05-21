import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/design_system.dart';
import '../core/shimmer.dart';

class ShimmerWorldCard extends StatelessWidget {
  const ShimmerWorldCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? VColors.glassBackgroundDark : VColors.glassBackground,
        borderRadius: BorderRadius.circular(RadiusTokens.card),
        border: Border.all(color: isDark ? VColors.glassBorderDark : VColors.glassBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 130,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(width: 120, child: Pulse(borderRadius: 0)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.sm + 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Pulse(
                      width: MediaQuery.of(context).size.width * 0.25,
                      height: FontSizes.body,
                      borderRadius: RadiusTokens.chip,
                    ),
                    const SizedBox(height: Spacing.sm),
                    Pulse(
                      width: MediaQuery.of(context).size.width * 0.18,
                      height: FontSizes.caption,
                      borderRadius: RadiusTokens.chip,
                    ),
                    const SizedBox(height: Spacing.sm),
                    const Pulse(
                      height: FontSizes.caption,
                      borderRadius: RadiusTokens.chip,
                    ),
                    const SizedBox(height: Spacing.xs),
                    Pulse(
                      width: MediaQuery.of(context).size.width * 0.22,
                      height: FontSizes.caption,
                      borderRadius: RadiusTokens.chip,
                    ),
                    const SizedBox(height: Spacing.sm),
                    const Row(
                      children: [
                        Pulse(
                          width: 50,
                          height: 20,
                          borderRadius: RadiusTokens.chip,
                        ),
                        SizedBox(width: Spacing.xs),
                        Pulse(
                          width: 36,
                          height: 20,
                          borderRadius: RadiusTokens.chip,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
