import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';
import '../core/glass_panel.dart';

class ResourceVault extends StatelessWidget {
  const ResourceVault({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock, color: AppColors.hustler, size: IconSizes.sm + 2),
              const SizedBox(width: Spacing.sm),
              Text(
                'RESOURCE VAULT',
                style: const TextStyle(
                  fontSize: FontSizes.labelSm,
                  fontWeight: FontWeights.semiBold,
                  color: AppColors.ink,
                  letterSpacing: LetterSpacing.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          _VaultItem(name: 'Arbitrage_Bot_V4.exe', sharedBy: 'Apex', color: AppColors.hustler),
          _VaultItem(name: 'DeFi_Yield_Manifest.pdf', sharedBy: 'Elite Tier', color: AppColors.primary),
          _VaultItem(name: 'Network_Grid_Map.json', sharedBy: 'Real-time Data', color: AppColors.tertiary),
        ],
      ),
    );
  }
}

class _VaultItem extends StatelessWidget {
  final String name, sharedBy;
  final Color color;
  const _VaultItem({required this.name, required this.sharedBy, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.sm + 2),
      padding: const EdgeInsets.all(Spacing.sm + 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(RadiusTokens.md),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: FontSizes.labelSm, fontWeight: FontWeights.semiBold, color: AppColors.ink)),
                Text('Shared by $sharedBy', style: const TextStyle(fontSize: FontSizes.labelSm, color: AppColors.inkMuted)),
              ],
            ),
          ),
          Icon(Icons.download, color: color, size: IconSizes.sm),
        ],
      ),
    );
  }
}
