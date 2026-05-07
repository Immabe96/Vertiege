import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/world.dart';
import '../../config/tiers.dart';
import '../../models/resident.dart';
import '../../services/world_service.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';
import '../core/fade_in.dart';
import '../core/loading_state.dart';
import '../profile/cosmetic_avatar.dart';

class WorldResidents extends ConsumerStatefulWidget {
  final World world;

  const WorldResidents({super.key, required this.world});

  @override
  ConsumerState<WorldResidents> createState() => _WorldResidentsState();
}

class _WorldResidentsState extends ConsumerState<WorldResidents> {
  List<_MemberEntry> _residents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final members = await WorldService.getMembers(widget.world.id);
      if (mounted) {
        setState(() {
          _residents = members.map((m) => _MemberEntry(
            resident: _toResident(m),
            rep: m['rep'] ?? 0,
          )).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Resident _toResident(Map<String, dynamic> m) => Resident(
        id: m['resident_id'] ?? '',
        name: m['resident_name'] ?? 'Member',
        tier: ResidentTier.fromValue(m['standing'] ?? 1),
        avatarUrl: 'assets/generated/avatar-1.png',
        streakCount: 0,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Residents (${_residents.length})', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (_loading)
          const GlassLoadingCard()
        else if (_residents.isEmpty)
          Text('No residents yet', style: theme.textTheme.bodyMedium)
        else
          ..._residents.take(5).toList().asMap().entries.map((entry) {
            final idx = entry.key;
            final member = entry.value;
            final resident = member.resident;
            final standing = getStanding(member.rep);
            final isSovereign = resident.id == widget.world.sovereignId;
            final medalColor = idx == 0
                ? AppColors.tertiary
                : idx == 1
                    ? AppColors.silver
                    : idx == 2
                        ? AppColors.bronze
                        : null;

            return FadeIn(
              delayMs: idx * 50,
              child: ListTile(
                leading: Stack(
                  alignment: Alignment.center,
                  children: [
                    CosmeticAvatar(imageUrl: resident.avatarUrl, size: 40),
                    if (medalColor != null)
                      Text('${idx + 1}',
                          style: TextStyle(color: medalColor, fontWeight: FontWeights.bold, fontSize: FontSizes.body)),
                  ],
                ),
                title: Row(
                  children: [
                    Flexible(child: Text(resident.name, overflow: TextOverflow.ellipsis)),
                    if (isSovereign) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.auto_awesome, size: 14, color: theme.colorScheme.primary),
                    ],
                  ],
                ),
                subtitle: Text(standing.title),
                trailing: Text('Rep ${member.rep}', style: theme.textTheme.labelSmall),
                onTap: () => context.push('/residents/${resident.id}'),
              ),
            );
          }),
          if (_residents.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: TextButton(
                onPressed: () => context.push(
                  '/explore/${widget.world.id}/members'
                  '?name=${Uri.encodeComponent(widget.world.name)}'
                  '&sovereign=${Uri.encodeComponent(widget.world.sovereignId)}',
                ),
                child: Text('See all ${_residents.length} members'),
              ),
            ),
      ],
    );
  }
}

class _MemberEntry {
  final Resident resident;
  final int rep;
  const _MemberEntry({required this.resident, required this.rep});
}
