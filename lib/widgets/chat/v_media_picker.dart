import 'package:flutter/material.dart';
import 'package:vertiege/ui/ui.dart';

import '../../models/resident.dart';
import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';

/// Bottom sheet: GIF shortcuts + tier-gated sticker packs.
void showVMediaPicker(
  BuildContext context, {
  required Resident? resident,
  required void Function(String assetUrl) onPick,
}) {
  showVSheet(
    context,
    _VMediaPickerContent(resident: resident, onPick: onPick),
    maxSize: 0.55,
  );
}

class _VMediaPickerContent extends StatelessWidget {
  final Resident? resident;
  final void Function(String assetUrl) onPick;

  const _VMediaPickerContent({
    required this.resident,
    required this.onPick,
  });

  static const _gifs = [
    ('👏', 'Applause'),
    ('🎉', 'Celebrate'),
    ('🔥', 'Fire'),
    ('💯', 'Hundred'),
    ('😂', 'Laugh'),
    ('❤️', 'Love'),
  ];

  static const _baseStickers = ['✨', '🏆', '⚔️', '🛡️', '🌟', '💎'];

  @override
  Widget build(BuildContext context) {
    final tier = resident?.tier.value ?? 1;
    final premiumStickers = tier >= 3
        ? ['👑', '🦅', '🔮']
        : <String>[];
    final eliteStickers = tier >= 5 ? ['💠', '🜂'] : <String>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.lg,
        VSpacing.md,
        VSpacing.lg,
        VSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'GIF & stickers',
            style: TextStyle(
              fontSize: VFontSize.headlineSm,
              fontWeight: VFontWeight.bold,
              color: VCommuneColors.headerPrimary,
            ),
          ),
          const SizedBox(height: VSpacing.md),
          const Text(
            'Quick reactions',
            style: TextStyle(
              fontSize: VFontSize.labelSm,
              fontWeight: VFontWeight.semiBold,
              color: VCommuneColors.textMuted,
            ),
          ),
          const SizedBox(height: VSpacing.sm),
          Wrap(
            spacing: VSpacing.sm,
            runSpacing: VSpacing.sm,
            children: _gifs
                .map(
                  (g) => _MediaChip(
                    label: g.$1,
                    onTap: () {
                      Navigator.pop(context);
                      onPick(g.$1);
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: VSpacing.lg),
          const Text(
            'Stickers',
            style: TextStyle(
              fontSize: VFontSize.labelSm,
              fontWeight: VFontWeight.semiBold,
              color: VCommuneColors.textMuted,
            ),
          ),
          const SizedBox(height: VSpacing.sm),
          Wrap(
            spacing: VSpacing.sm,
            runSpacing: VSpacing.sm,
            children: [
              ..._baseStickers.map(
                (s) => _MediaChip(
                  label: s,
                  onTap: () {
                    Navigator.pop(context);
                    onPick(s);
                  },
                ),
              ),
              ...premiumStickers.map(
                (s) => _MediaChip(
                  label: s,
                  locked: tier < 3,
                  lockLabel: 'Tier 3+',
                  onTap: tier >= 3
                      ? () {
                          Navigator.pop(context);
                          onPick(s);
                        }
                      : null,
                ),
              ),
              ...eliteStickers.map(
                (s) => _MediaChip(
                  label: s,
                  locked: tier < 5,
                  lockLabel: 'Apex',
                  onTap: tier >= 5
                      ? () {
                          Navigator.pop(context);
                          onPick(s);
                        }
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MediaChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool locked;
  final String? lockLabel;

  const _MediaChip({
    required this.label,
    this.onTap,
    this.locked = false,
    this.lockLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: locked ? 0.45 : 1,
      child: Material(
        color: VCommuneColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(VRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(VRadius.md),
          child: Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(label, style: const TextStyle(fontSize: 28)),
                if (locked && lockLabel != null)
                  Positioned(
                    bottom: 2,
                    child: Text(
                      lockLabel!,
                      style: const TextStyle(
                        fontSize: 8,
                        color: VCommuneColors.textMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
