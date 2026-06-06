import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vertiege/ui/ui.dart';

import '../../config/tiers.dart';
import '../../router/world_navigation.dart';
import '../../services/chat_service.dart';
import '../../services/world_service.dart';
import '../../state/resident_provider.dart';
import '../../state/world_provider.dart';
import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/standing_display_color.dart';
import '../profile/cosmetic_avatar.dart';
import 'v_member_card.dart';

/// Resident list for a world channel — avatars, standing, tap to DM.
void showResidentListSheet(
  BuildContext context, {
  required String worldId,
  required String channelName,
}) {
  showVSheet(
    context,
    _ResidentListContent(worldId: worldId, channelName: channelName),
    maxSize: 0.75,
  );
}

class _ResidentListContent extends ConsumerStatefulWidget {
  final String worldId;
  final String channelName;

  const _ResidentListContent({
    required this.worldId,
    required this.channelName,
  });

  @override
  ConsumerState<_ResidentListContent> createState() =>
      _ResidentListContentState();
}

class _ResidentListContentState extends ConsumerState<_ResidentListContent> {
  List<Map<String, dynamic>> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final members = await WorldService.getMembers(widget.worldId);
      if (mounted) {
        setState(() {
          _members = members;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openDm(String residentId, String name) async {
    final me = ref.read(residentProvider).resident;
    if (me == null || me.id == residentId) return;
    final room = await ChatService.getOrCreateRoom(me.id, residentId);
    if (!mounted || room == null) return;
    final roomId = room['id'] as String?;
    if (roomId == null) return;
    Navigator.pop(context);
    context.push(chatRoomPath(roomId));
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final sovereignId = ref
        .watch(worldProvider)
        .worlds[widget.worldId]
        ?.sovereignId;

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
          Text(
            'Residents',
            style: TextStyle(
              fontSize: VFontSize.headlineSm,
              fontWeight: VFontWeight.bold,
              color: VCommuneColors.headerPrimaryOf(brightness),
            ),
          ),
          Text(
            '#${widget.channelName}',
            style: TextStyle(
              fontSize: VFontSize.bodyMd,
              color: VCommuneColors.textMutedOf(brightness),
            ),
          ),
          const SizedBox(height: VSpacing.md),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _members.isEmpty
                ? Center(
                    child: Text(
                      'No residents loaded',
                      style: TextStyle(
                        color: VCommuneColors.textMutedOf(brightness),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _members.length,
                    separatorBuilder: (_, _) => Divider(
                      color: VCommuneColors.dividerOf(brightness),
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final m = _members[index];
                      final id = m['resident_id'] as String? ?? '';
                      final name =
                          m['resident_name'] as String? ?? 'Resident';
                      final rep = (m['rep'] as int?) ?? 0;
                      final standing = getStanding(rep);
                      final nameColor = standingDisplayColor(
                        rep,
                        sovereignId: sovereignId,
                        residentId: id,
                      );

                      final tierValue =
                          (m['tier'] as int?) ??
                          (m['standing'] as int?) ??
                          1;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CosmeticAvatar(
                          imageUrl: m['avatar_url'] as String?,
                          seed: id,
                          size: 36,
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            fontWeight: VFontWeight.semiBold,
                            color: nameColor,
                          ),
                        ),
                        subtitle: Text(
                          '${standing.title} · $rep rep',
                          style: TextStyle(
                            fontSize: VFontSize.labelSm,
                            color: VCommuneColors.textMutedOf(brightness),
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          size: VIconSize.sm,
                          color: VCommuneColors.textMutedOf(brightness),
                        ),
                        onTap: () {
                          final me = ref.read(residentProvider).resident;
                          showResidentMemberCard(
                            context,
                            card: VMemberCard(
                              residentId: id,
                              name: name,
                              rep: rep,
                              tier: tierValue,
                              profession: m['profession'] as String?,
                              avatarUrl: m['avatar_url'] as String?,
                              sovereignId: sovereignId,
                              onMessage: me != null && me.id != id
                                  ? () => _openDm(id, name)
                                  : null,
                              onDismiss: () => Navigator.pop(context),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
