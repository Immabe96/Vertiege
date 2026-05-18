import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/v_colors.dart';
import '../../theme/design_system.dart';
import '../../state/event_provider.dart';
import '../../state/resident_provider.dart';
import '../../services/permission_service.dart';
import '../../ui/icons/v_icons.dart';
import '../../ui/buttons/v_button.dart';

class WorldEventsCard extends ConsumerWidget {
  final String worldId;
  final String sovereignId;

  const WorldEventsCard({
    super.key,
    required this.worldId,
    required this.sovereignId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events =
        ref
            .watch(eventProvider)
            .eventsByWorld[worldId]
            ?.where((e) => e.isUpcoming)
            .toList() ??
        [];
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final resident = ref.watch(residentProvider).resident;
    final canCreate =
        resident != null &&
        WorldPermissions.canAnnounce(resident, worldId, sovereignId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.xs,
          ),
          child: Row(
            children: [
              Icon(
                Icons.event_note,
                size: IconSizes.sm,
                color: VColors.primary,
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                'Upcoming Events',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeights.bold,
                ),
              ),
              const Spacer(),
              if (canCreate)
                TextButton.icon(
                  onPressed: () => _showCreateEvent(context, ref),
                  icon: const Icon(VIcons.plus, size: IconSizes.xs),
                  label: const Text('Create'),
                ),
            ],
          ),
        ),
        if (events.isEmpty)
          Padding(
            padding: const EdgeInsets.only(
              left: Spacing.md,
              bottom: Spacing.xs,
            ),
            child: Text(
              'No upcoming events',
              style: theme.textTheme.bodySmall?.copyWith(color: cs.outline),
            ),
          )
        else
          ...events.take(3).map((event) {
            final isRsvp =
                resident != null && event.rsvpIds.contains(resident.id);
            return ListTile(
              dense: true,
              leading: Icon(
                isRsvp ? Icons.event_available : Icons.event,
                size: IconSizes.md,
                color: isRsvp ? VColors.primary : cs.onSurfaceVariant,
              ),
              title: Text(event.title, style: theme.textTheme.bodyMedium),
              subtitle: Text(
                event.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall,
              ),
              trailing: VButton(
                label: isRsvp
                    ? 'Going (${event.rsvpIds.length})'
                    : 'RSVP (${event.rsvpIds.length})',
                onPressed: () {
                  if (resident != null) {
                    ref
                        .read(eventProvider.notifier)
                        .toggleRsvp(worldId, event.id, resident.id);
                  }
                },
                variant: ButtonVariant.text,
              ),
            );
          }),
      ],
    );
  }

  void _showCreateEvent(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Event title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          VButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(ctx),
            variant: ButtonVariant.text,
          ),
          VButton(
            label: 'Create',
            onPressed: () {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) return;
              final resident = ref.read(residentProvider).resident;
              if (resident == null) return;
              ref
                  .read(eventProvider.notifier)
                  .createEvent(
                    worldId: worldId,
                    title: title,
                    description: descCtrl.text.trim(),
                    createdBy: resident.id,
                    createdByName: resident.name,
                    startsAt: DateTime.now()
                        .add(const Duration(hours: 1))
                        .millisecondsSinceEpoch,
                  );
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}
