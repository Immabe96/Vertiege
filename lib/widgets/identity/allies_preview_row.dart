import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/world_navigation.dart';
import '../../services/chat_service.dart';
import '../../state/ally_provider.dart';
import '../../state/resident_provider.dart';
import '../../widgets/core/v_feedback.dart';
import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';
import '../profile/cosmetic_avatar.dart';

/// Horizontal allies strip on the You tab (Wave 6).
class AlliesPreviewRow extends ConsumerStatefulWidget {
  const AlliesPreviewRow({super.key});

  @override
  ConsumerState<AlliesPreviewRow> createState() => _AlliesPreviewRowState();
}

class _AlliesPreviewRowState extends ConsumerState<AlliesPreviewRow> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = ref.read(residentProvider).resident?.id;
      if (id != null) {
        ref.read(allyProvider.notifier).loadAll(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final resident = ref.watch(residentProvider).resident;
    if (resident == null) return const SizedBox.shrink();

    final allies = ref.watch(allyProvider).allies;
    if (allies.isEmpty) return const SizedBox.shrink();

    final preview = allies.take(12).toList();

    final brightness = Theme.of(context).brightness;
    return ColoredBox(
      color: VCommuneColors.surfaceSecondaryOf(brightness),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VSpacing.md,
              VSpacing.sm,
              VSpacing.md,
              VSpacing.xs,
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Allies',
                    style: TextStyle(
                      fontSize: VFontSize.labelSm,
                      fontWeight: VFontWeight.semiBold,
                      color: VCommuneColors.headerSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/allies'),
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      fontSize: VFontSize.labelSm,
                      color: VCommuneColors.textLink,
                      fontWeight: VFontWeight.semiBold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(
                VSpacing.md,
                0,
                VSpacing.md,
                VSpacing.sm,
              ),
              itemCount: preview.length,
              separatorBuilder: (_, _) => const SizedBox(width: VSpacing.sm),
              itemBuilder: (context, index) {
                final ally = preview[index];
                final otherId = ally.otherId(resident.id);
                return GestureDetector(
                  onTap: () => _openAllyDm(context, resident.id, otherId),
                  onLongPress: () =>
                      context.push(residentProfilePath(otherId)),
                  child: Column(
                    children: [
                      CosmeticAvatar(seed: otherId, size: 44),
                      const SizedBox(height: 2),
                      SizedBox(
                        width: 48,
                        child: Text(
                          'Ally',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: VFontSize.labelSm,
                            color: VCommuneColors.textMutedOf(brightness),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Divider(height: 1, color: VCommuneColors.dividerOf(brightness)),
        ],
      ),
    );
  }

  Future<void> _openAllyDm(
    BuildContext context,
    String residentId,
    String otherId,
  ) async {
    final room = await ChatService.getOrCreateRoom(residentId, otherId);
    if (room == null) {
      if (context.mounted) {
        VFeedback.showMessage(context, 'Could not open chat.');
      }
      return;
    }
    if (!context.mounted) return;
    context.push(chatRoomPath(room['id'] as String));
  }
}
