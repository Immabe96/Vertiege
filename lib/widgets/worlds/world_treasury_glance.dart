import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/world_capability_matrix.dart';
import '../../models/treasury.dart';
import '../../models/world.dart';
import '../../router/world_navigation.dart';
import '../../services/treasury_service.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';

/// Compact treasury balance for world tools menu (DCX-137).
class WorldTreasuryGlance extends StatefulWidget {
  final String worldId;
  final World world;
  final bool isAdminOrCouncil;

  const WorldTreasuryGlance({
    super.key,
    required this.worldId,
    required this.world,
    required this.isAdminOrCouncil,
  });

  @override
  State<WorldTreasuryGlance> createState() => _WorldTreasuryGlanceState();
}

class _WorldTreasuryGlanceState extends State<WorldTreasuryGlance> {
  WorldTreasury? _treasury;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!WorldCapabilityMatrix.worldHasTreasury(widget.world)) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final treasury = await TreasuryService.getTreasury(widget.worldId);
      if (mounted) {
        setState(() {
          _treasury = treasury;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!WorldCapabilityMatrix.worldHasTreasury(widget.world)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.md,
        0,
        VSpacing.md,
        VSpacing.sm,
      ),
      child: Material(
        color: VCommuneColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(VRadius.lg),
        child: InkWell(
          onTap: () => context.push(
            worldTreasuryPath(widget.worldId, admin: widget.isAdminOrCouncil),
          ),
          borderRadius: BorderRadius.circular(VRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(VSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(VSpacing.sm),
                  decoration: BoxDecoration(
                    color: VColors.tertiary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(VRadius.md),
                  ),
                  child: const Icon(
                    Icons.account_balance_outlined,
                    color: VColors.tertiary,
                    size: VIconSize.md,
                  ),
                ),
                const SizedBox(width: VSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'World treasury',
                        style: TextStyle(
                          fontSize: VFontSize.labelSm,
                          color: VCommuneColors.textMuted,
                          fontWeight: VFontWeight.semiBold,
                        ),
                      ),
                      if (_loading)
                        const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Text(
                          _treasury != null
                              ? '${_treasury!.balance} coins'
                              : 'Not funded yet',
                          style: const TextStyle(
                            fontSize: VFontSize.headlineSm,
                            fontWeight: VFontWeight.bold,
                            color: VCommuneColors.headerPrimary,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: VCommuneColors.textMuted,
                  size: VIconSize.sm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
