import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/world_provider.dart';
import '../../widgets/worlds/world_card.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worldState = ref.watch(worldProvider);
    final worlds = worldState.worlds;

    return Scaffold(
      appBar: AppBar(title: const Text('Explore Worlds')),
      body: worldState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : worlds.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.public_off, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text('No worlds available', style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: worlds.length,
                  itemBuilder: (context, index) {
                    final world = worlds.values.elementAt(index);
                    return WorldCard(world: world);
                  },
                ),
    );
  }
}
