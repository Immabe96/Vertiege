import 'package:forui/forui.dart';
import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/design_system.dart';
import 'glass_panel.dart';

class ProtocolLogs extends StatelessWidget {
  final List<String> logs;
  const ProtocolLogs({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    return FCard(

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: VColors.error,

                ),
              ),
              const SizedBox(width: Spacing.sm),
              const Text(
                'PROTOCOL LOGS',
                style: TextStyle(
                  fontSize: FontSizes.headlineMd,
                  fontWeight: FontWeights.semiBold,
                  color: VColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          ...logs.map(
            (log) => Padding(

              child: Text(
                log,
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: FontSizes.labelSm,
                  color: VColors.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
