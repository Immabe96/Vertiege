import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/rank.dart';
import '../../services/rank_service.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/ui.dart';
import '../../widgets/core/loading_state.dart';
import 'world_settings_card.dart';

class WorldSettingsRanks extends ConsumerStatefulWidget {
  final String worldId;

  const WorldSettingsRanks({super.key, required this.worldId});

  @override
  ConsumerState<WorldSettingsRanks> createState() => _WorldSettingsRanksState();
}

class _WorldSettingsRanksState extends ConsumerState<WorldSettingsRanks> {
  List<Rank> _ranks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ranks = await RankService.fetchWorldRanks(widget.worldId);
    if (mounted) {
      setState(() {
        _ranks = ranks;
        _loading = false;
      });
    }
  }

  Future<void> _showCreateDialog() async {
    final controller = TextEditingController();
    try {
      await showVDialog<void>(
        context: context,
        title: 'Create Rank',
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Rank name'),
          autofocus: true,
        ),
        actions: [
          vDialogActionsRow([
            VButton(
              label: 'Cancel',
              onPressed: () => Navigator.pop(context),
              variant: ButtonVariant.text,
            ),
            VButton(
              label: 'Create',
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                await RankService.createRank(
                  worldId: widget.worldId,
                  name: name,
                );
                if (!mounted) return;
                Navigator.pop(context);
                _load();
              },
            ),
          ]),
        ],
      );
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WorldSettingsCard(
      padding: const EdgeInsets.all(VSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.military_tech,
                color: VColors.tertiary,
                size: VIconSize.md,
              ),
              const SizedBox(width: VSpacing.sm),
              const Expanded(
                child: Text(
                  'Ranks',
                  style: TextStyle(
                    fontSize: VFontSize.headlineMd,
                    fontWeight: VFontWeight.bold,
                  ),
                ),
              ),
              VButton(
                label: 'Create',
                variant: ButtonVariant.text,
                size: ButtonSize.small,
                icon: const Icon(VIcons.plus, size: VIconSize.sm),
                onPressed: _showCreateDialog,
              ),
            ],
          ),
          const SizedBox(height: VSpacing.sm),
          if (_loading)
            const Center(child: VLoadingCard())
          else if (_ranks.isEmpty)
            Text(
              'No ranks yet. Create one to assign privileges.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else
            ..._ranks.map(
              (r) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: VSpacing.sm,
                  vertical: VSpacing.xs,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _parseHex(r.colorHex),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: VSpacing.sm),
                    Expanded(
                      child: Text(
                        r.name,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: VIconSize.sm),
                      onPressed: () async {
                        await RankService.deleteRank(r.id);
                        _load();
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Color _parseHex(String hex) =>
    Color(int.parse('FF${hex.substring(1)}', radix: 16));
