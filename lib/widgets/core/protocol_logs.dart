import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/cards/v_card.dart';

class ProtocolLogs extends StatelessWidget {
  final List<String> logs;
  const ProtocolLogs({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    return VCard(
      padding: const EdgeInsets.all(VSpacing.lg),
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
                  borderRadius: BorderRadius.circular(VRadius.sm),
                ),
              ),
              const SizedBox(width: VSpacing.sm),
              Text(
                'PROTOCOL LOGS',
                style: TextStyle(
                  fontSize: VFontSize.headlineMd,
                  fontWeight: VFontWeight.semiBold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.md),
          ...logs.map(
            (log) => Padding(
              padding: const EdgeInsets.only(bottom: VSpacing.xs),
              child: Text(
                log,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: VFontSize.labelSm,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
