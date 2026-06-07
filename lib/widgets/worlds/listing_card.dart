import 'package:flutter/material.dart';
import '../../models/listing.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

class ListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;
  final String? worldName;

  const ListingCard({
    super.key,
    required this.listing,
    required this.onTap,
    this.worldName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(VRadius.lg),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ListingImage(listing: listing),
                  Padding(
                    padding: const EdgeInsets.all(VSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: VFontWeight.semiBold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        if (worldName != null) ...[
                          Text(
                            worldName!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: VFontWeight.medium,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                        ],
                        Row(
                          children: [
                            Icon(
                              listing.coinPrice != null && listing.coinPrice! > 0
                                  ? Icons.monetization_on
                                  : Icons.sell,
                              size: VIconSize.xs,
                              color: VColors.tertiary,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                listing.coinPrice != null && listing.coinPrice! > 0
                                    ? '${listing.coinPrice} coins'
                                    : (listing.price ?? 'Free'),
                                style: const TextStyle(
                                  fontSize: VFontSize.labelSm,
                                  fontWeight: VFontWeight.bold,
                                  color: VColors.tertiary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (listing.priceNote != null && listing.priceNote!.isNotEmpty)
                          Text(
                            listing.priceNote!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 2),
                        Text(
                          listing.sellerName,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (listing.status == ListingStatus.sold)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: VColors.scrim,
                      borderRadius: BorderRadius.circular(VRadius.lg),
                    ),
                    child: const Center(
                      child: Text(
                        'SOLD',
                        style: TextStyle(
                          color: VColors.onPrimary,
                          fontSize: VFontSize.headlineSm,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListingImage extends StatelessWidget {
  final Listing listing;

  const _ListingImage({required this.listing});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AspectRatio(
      aspectRatio: 1.2,
      child: listing.imageUrl != null && listing.imageUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(VRadius.lg),
              ),
              child: Image.network(
                listing.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _Placeholder(isDark: isDark),
              ),
            )
          : _Placeholder(isDark: isDark),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final bool isDark;

  const _Placeholder({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? VColors.surfaceContainerHighDark
            : VColors.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(VRadius.lg),
        ),
      ),
      child: Icon(
        Icons.image_outlined,
        size: VIconSize.xl,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
