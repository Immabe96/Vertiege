import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/world.dart';
import '../../models/resident.dart';

class WorldResidents extends StatelessWidget {
  final World world;
  final List<Resident> residents;

  const WorldResidents({super.key, required this.world, this.residents = const []});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = List<Resident>.from(residents)
      ..sort((a, b) => b.tier.value.compareTo(a.tier.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Residents', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (residents.isEmpty)
          Text('No residents yet', style: theme.textTheme.bodyMedium)
        else
          ...sorted.take(5).toList().asMap().entries.map((entry) {
            final idx = entry.key;
            final resident = entry.value;
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
                    ? Text('${idx + 1}', style: TextStyle(color: medalColor, fontWeight: FontWeight.bold))
                    : null,
              ),
              title: Text(resident.name),
              subtitle: Text(ResidentTier.fromValue(resident.tier.value).label),
              trailing: Text('Streak ${resident.streakCount}'),
              onTap: () => context.push('/residents/${resident.id}'),
            );
          }),
      ],
    );
  }
}
