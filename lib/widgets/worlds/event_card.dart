import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/post.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';
import '../../state/post_provider.dart';
import '../../state/resident_provider.dart';
import '../../utils/date_format.dart';
import '../core/glass_panel.dart';

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

    return GlassPanel(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(RadiusTokens.sm),
                ),
                child: const Icon(Icons.event, size: IconSizes.md, color: AppColors.warning),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.eventTitle ?? 'Event',
                      style: const TextStyle(
                        fontSize: FontSizes.headlineMd,
                        fontWeight: FontWeights.semiBold,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: FontSizes.labelSm,
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (post.content.isNotEmpty) ...[
            const SizedBox(height: Spacing.sm),
            Text(
              post.content,
              style: const TextStyle(
                fontSize: FontSizes.bodyMd,
                color: AppColors.inkSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: Spacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$rsvpCount attending',
                  style: const TextStyle(
                    fontSize: FontSizes.labelSm,
                    color: AppColors.inkMuted,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () {
                  if (resident != null) {
                    ref
                        .read(postProvider.notifier)
                        .toggleEventRsvp(post.id, resident.id);
                  }
                },
                icon: Icon(
                  hasRsvp ? Icons.event_available : Icons.event,
                  size: IconSizes.sm,
                ),
                label: Text(hasRsvp ? 'GOING' : 'ATTEND'),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      hasRsvp ? AppColors.primary : AppColors.tertiary,
                  foregroundColor:
                      hasRsvp ? AppColors.onPrimary : AppColors.onTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
