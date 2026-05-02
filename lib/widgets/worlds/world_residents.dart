import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/world.dart';
import '../../models/resident.dart';
import '../../services/world_service.dart';

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
        avatarUrl: 'https://via.placeholder.com/150',
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
          const Center(child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ))
        else if (_residents.isEmpty)
          Text('No residents yet', style: theme.textTheme.bodyMedium)
        else
          ..._residents.take(5).toList().asMap().entries.map((entry) {
            final idx = entry.key;
            final member = entry.value;
            final resident = member.resident;
            final medalColor = idx == 0
                ? const Color(0xFFD4A843)
                : idx == 1
                    ? const Color(0xFFC0C0C0)
                    : idx == 2
                        ? const Color(0xFFCD7F32)
                        : null;

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(resident.avatarUrl),
                child: medalColor != null
                    ? Text('${idx + 1}',
                        style: TextStyle(color: medalColor, fontWeight: FontWeight.bold))
                    : null,
              ),
              title: Text(resident.name),
              subtitle: Text(resident.tier.label),
              trailing: Text('Rep ${member.rep}'),
              onTap: () => context.push('/residents/${resident.id}'),
            );
          }),
      ],
    );
  }
}

class _MemberEntry {
  final Resident resident;
  final int rep;
  const _MemberEntry({required this.resident, required this.rep});
}
