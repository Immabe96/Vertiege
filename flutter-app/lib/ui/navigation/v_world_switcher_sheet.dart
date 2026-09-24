import 'package:flutter/material.dart';
import 'package:vertiege/ui/ui.dart';

import '../../models/world.dart';
import '../../router/search_navigation.dart';
import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';
import '../../widgets/worlds/world_icon.dart';

/// Quick jump between joined worlds (DCX-020).
void showWorldSwitcherSheet(
  BuildContext context, {
  required List<World> worlds,
  required String? selectedWorldId,
  required ValueChanged<World> onWorldSelected,
}) {
  showVSheet(
    context,
    _WorldSwitcherBody(
      worlds: worlds,
      selectedWorldId: selectedWorldId,
      onWorldSelected: (world) {
        Navigator.pop(context);
        onWorldSelected(world);
      },
      onSearch: () {
        Navigator.pop(context);
        openGlobalSearch(context);
      },
    ),
    maxSize: 0.55,
  );
}

class _WorldSwitcherBody extends StatefulWidget {
  final List<World> worlds;
  final String? selectedWorldId;
  final ValueChanged<World> onWorldSelected;
  final VoidCallback onSearch;

  const _WorldSwitcherBody({
    required this.worlds,
    required this.selectedWorldId,
    required this.onWorldSelected,
    required this.onSearch,
  });

  @override
  State<_WorldSwitcherBody> createState() => _WorldSwitcherBodyState();
}

class _WorldSwitcherBodyState extends State<_WorldSwitcherBody> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? widget.worlds
        : widget.worlds
              .where((w) => w.name.toLowerCase().contains(q))
              .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.lg,
        VSpacing.md,
        VSpacing.lg,
        VSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Switch world',
            style: TextStyle(
              fontSize: VFontSize.headlineSm,
              fontWeight: VFontWeight.bold,
              color: VCommuneColors.headerPrimary,
            ),
          ),
          const SizedBox(height: VSpacing.md),
          TextField(
            decoration: InputDecoration(
              hintText: 'Filter worlds…',
              prefixIcon: const Icon(Icons.search, size: VIconSize.md),
              isDense: true,
              filled: true,
              fillColor: VCommuneColors.surfaceSecondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(VRadius.pill),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: VSpacing.sm),
          VTile(
            prefix: const Icon(Icons.manage_search_outlined),
            title: const Text('Search residents and worlds'),
            onPress: widget.onSearch,
          ),
          const SizedBox(height: VSpacing.sm),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No worlds match',
                      style: TextStyle(color: VCommuneColors.textMuted),
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: VSpacing.xs),
                    itemBuilder: (context, index) {
                      final world = filtered[index];
                      final selected = world.id == widget.selectedWorldId;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(VRadius.md),
                          onTap: () => widget.onWorldSelected(world),
                          child: Ink(
                            decoration: BoxDecoration(
                              color: selected
                                  ? VCommuneColors.modifierSelected
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(VRadius.md),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: VSpacing.md,
                                vertical: VSpacing.sm,
                              ),
                              child: Row(
                                children: [
                                  WorldIcon(
                                    worldId: world.assetKey,
                                    size: VWorldIconSize.dense,
                                    useGlassContainer: false,
                                  ),
                                  const SizedBox(width: VSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          world.name,
                                          style: TextStyle(
                                            fontWeight: selected
                                                ? VFontWeight.semiBold
                                                : VFontWeight.medium,
                                            color: VCommuneColors.headerPrimary,
                                          ),
                                        ),
                                        Text(
                                          '${world.memberCount} residents',
                                          style: const TextStyle(
                                            color: VCommuneColors.textMuted,
                                            fontSize: VFontSize.labelMd,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (selected)
                                    const Icon(
                                      Icons.check,
                                      color: VCommuneColors.statusOnline,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
