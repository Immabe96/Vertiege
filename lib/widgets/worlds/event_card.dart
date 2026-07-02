import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/post.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../state/post_provider.dart';
import '../../state/resident_provider.dart';
import '../../utils/date_format.dart';
import '../../ui/cards/v_card.dart';
import '../../ui/ui.dart';

/// Glass card showing an event post with title, date/time, RSVP button.
class EventCard extends ConsumerWidget {
  final Post post;

  const EventCard({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resident = ref.watch(residentProvider).resident;
    final hasRsvp = resident != null && post.eventRsvpIds.contains(resident.id);
    final rsvpCount = post.eventRsvpIds.length;
    final dateStr = post.eventStartsAt != null
        ? formatTimestamp(post.eventStartsAt!)
        : 'Date pending';

    return VCard(
      padding: const EdgeInsets.all(VSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: VColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(VRadius.sm),
                ),
                child: const Icon(
                  Icons.event,
                  size: VIconSize.md,
                  color: VColors.warning,
                ),
              ),
              const SizedBox(width: VSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.eventTitle ?? 'Event',
                      style: TextStyle(
                        fontSize: VFontSize.headlineMd,
                        fontWeight: VFontWeight.semiBold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: VFontSize.labelSm,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (post.content.isNotEmpty) ...[
            const SizedBox(height: VSpacing.sm),
            Text(
              post.content,
              style: TextStyle(
                fontSize: VFontSize.bodyMd,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: VSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$rsvpCount attending',
                  style: TextStyle(
                    fontSize: VFontSize.labelSm,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
              VButton(
                label: hasRsvp ? 'GOING' : 'ATTEND',
                icon: Icon(
                  hasRsvp ? Icons.event_available : Icons.event,
                  size: VIconSize.sm,
                ),
                onPressed: resident == null
                    ? null
                    : () {
                        ref
                            .read(postProvider.notifier)
                            .toggleEventRsvp(post.id, resident.id);
                      },
                variant: ButtonVariant.filled,
                size: ButtonSize.small,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
