import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/world.dart';
import '../../state/resident_provider.dart';
import '../../state/world_provider.dart';
import '../../services/access_control.dart';
import 'access_icon.dart';

class WorldAccessGuard extends ConsumerWidget {
  final String worldId;
  final Widget child;

  const WorldAccessGuard({super.key, required this.worldId, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final world = ref.watch(worldProvider).worlds[worldId];
    final resident = ref.watch(residentProvider).resident;
    final theme = Theme.of(context);

    if (world == null) {
      return Center(child: Text('World not found', style: theme.textTheme.bodyLarge));
    }

    if (resident == null) {
      return Center(
        child: FilledButton(
          onPressed: () => context.go('/onboarding'),
          child: const Text('Get Started'),
        ),
      );
    }

    if (canAccessWorld(resident, world)) return child;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AccessIcon(type: AccessIconType.locked, size: 48),
              const SizedBox(height: 16),
              Text('Access Restricted', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(world.description, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (world.type == WorldType.wealth) {
                    ref.read(residentProvider.notifier).unlockWealthWorld(worldId);
                  } else if (world.type == WorldType.profession) {
                    ref.read(residentProvider.notifier).verifyProfession(world.requiredProfession ?? '');
                  }
                },
                child: Text(world.type == WorldType.wealth ? 'Unlock Access' : 'Verify Profession'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
