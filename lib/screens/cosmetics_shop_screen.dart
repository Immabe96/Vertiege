import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../router/world_navigation.dart';
import '../models/listing.dart';
import '../config/progression_access.dart';
import '../services/marketplace_service.dart';
import '../services/cosmetic_purchase_service.dart';
import '../state/achievement_provider.dart';
import '../state/resident_provider.dart';
import 'package:vertiege/ui/ui.dart';
import '../theme/prestige_noir.dart';
import '../theme/v_colors.dart';
import '../theme/v_tokens.dart';
import '../widgets/core/empty_state.dart';
import '../widgets/worlds/listing_card.dart';
import '../widgets/core/shimmer.dart';
import '../widgets/profile/cosmetic_avatar.dart';

enum _ShopCategory { cosmetics }

class CosmeticsShopScreen extends ConsumerStatefulWidget {
  const CosmeticsShopScreen({super.key});

  @override
  ConsumerState<CosmeticsShopScreen> createState() =>
      _CosmeticsShopScreenState();
}

class _CosmeticsShopScreenState extends ConsumerState<CosmeticsShopScreen> {
  @override
  Widget build(BuildContext context) {
    final resident = ref.watch(residentProvider).resident;
    final achievements = ref.watch(achievementProvider).userAchievements;
    final shopUnlocked = ProgressionAccess.canAccessShop(achievements);
    final coins = resident?.sovereignCoins ?? 0;

    if (!shopUnlocked) {
      return VHubPage(
        title: 'Shop',
        showBack: true,
        body: AppEmptyState(
          icon: Icons.lock_outline,
          title: 'Shop unlocks with standing',
          description:
              'Verify one life achievement first — cosmetics come after identity.',
          actionLabel: 'Submit proof',
          onAction: () => context.push('/achievements'),
        ),
      );
    }

    return VHubPage(
      title: 'Shop',
      showBack: true,
      headerActions: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.md,
            vertical: VSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: PrestigeNoir.accentSoft,
            borderRadius: BorderRadius.circular(VRadius.pill),
            border: Border.all(color: VColors.brand.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.monetization_on,
                size: VIconSize.sm,
                color: VColors.brand,
              ),
              const SizedBox(width: VSpacing.xs),
              Text(
                '$coins',
                style: const TextStyle(
                  fontSize: VFontSize.bodyMd,
                  fontWeight: VFontWeight.bold,
                  color: VColors.brand,
                ),
              ),
            ],
          ),
        ),
      ],
      body: VTabs(
        tabs: [
          VTabEntry(
            label: const Text('Cosmetics'),
            child: _ShopGrid(
              category: _ShopCategory.cosmetics,
              items: _cosmetics,
              coins: coins,
            ),
          ),
          const VTabEntry(label: Text('Dominions'), child: _DominionsTab()),
        ],
      ),
    );
  }

  static const _cosmetics = <_ShopItem>[
    _ShopItem(
      'Violet Halo Frame',
      'Glowing violet profile border',
      30,
      Icons.circle_outlined,
      VColors.primary,
      'Frame',
    ),
    _ShopItem(
      'Gold Trim Frame',
      'Golden prestige border',
      50,
      Icons.circle_outlined,
      VColors.tertiary,
      'Frame',
    ),
    _ShopItem(
      'Obsidian Frame',
      'Dark obsidian border',
      25,
      Icons.circle_outlined,
      VColors.onSurfaceVariant,
      'Frame',
    ),
    _ShopItem(
      'Crimson Edge Frame',
      'Red warning border',
      40,
      Icons.circle_outlined,
      VColors.error,
      'Frame',
    ),
    _ShopItem(
      'Cosmic Banner',
      'Starry space profile banner',
      80,
      Icons.auto_awesome,
      VColors.primary,
      'Banner',
    ),
    _ShopItem(
      'Forge Banner',
      'Molten gold pattern banner',
      100,
      Icons.auto_awesome,
      VColors.tertiary,
      'Banner',
    ),
    _ShopItem(
      'Gold Name Color',
      'Golden name display',
      60,
      Icons.palette,
      VColors.tertiary,
      'Effect',
    ),
    _ShopItem(
      'Violet Ink',
      'Violet name color',
      45,
      Icons.palette,
      VColors.primary,
      'Effect',
    ),
    _ShopItem(
      'Sparkle Effect',
      'Subtle sparkle on profile',
      70,
      Icons.auto_awesome,
      VColors.warning,
      'Effect',
    ),
  ];
}

class _ShopItem {
  final String name;
  final String description;
  final int price;
  final IconData icon;
  final Color color;
  final String subtype;

  const _ShopItem(
    this.name,
    this.description,
    this.price,
    this.icon,
    this.color,
    this.subtype,
  );
}

class _ShopGrid extends StatelessWidget {
  final _ShopCategory category;
  final List<_ShopItem> items;
  final int coins;

  const _ShopGrid({
    required this.category,
    required this.items,
    required this.coins,
  });

  @override
  Widget build(BuildContext context) {

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.store_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: VSpacing.md),
            const Text(
              'Coming soon',
              style: TextStyle(fontWeight: VFontWeight.semiBold),
            ),
            const SizedBox(height: VSpacing.xs),
            Text(
              'New items are being crafted.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(VSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: VSpacing.sm,
        mainAxisSpacing: VSpacing.sm,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final canAfford = coins >= item.price;

        return _ShopCard(
          category: category,
          item: item,
          canAfford: canAfford,
          index: index,
        );
      },
    );
  }
}

class _ShopCard extends ConsumerWidget {
  final _ShopCategory category;
  final _ShopItem item;
  final bool canAfford;
  final int index;

  const _ShopCard({
    required this.category,
    required this.item,
    required this.canAfford,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: canAfford ? () => _buyItem(context, ref, item) : null,
      onLongPress: () => _previewItem(context, ref, item),
      child: VPrestigeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(VRadius.pill),
                    ),
                    child: Text(
                      item.subtype,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: item.color,
                        fontWeight: VFontWeight.semiBold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (!canAfford)
                    Icon(
                      Icons.lock_outline,
                      size: VIconSize.xs,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
              const Spacer(),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(VRadius.lg),
                ),
                child: Icon(item.icon, size: VIconSize.lg, color: item.color),
              ),
              const SizedBox(height: VSpacing.sm),
              Text(
                item.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: VFontWeight.semiBold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                item.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(
                    Icons.monetization_on,
                    size: VIconSize.xs,
                    color: VColors.brand,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${item.price}',
                    style: const TextStyle(
                      fontSize: VFontSize.labelSm,
                      fontWeight: VFontWeight.bold,
                      color: VColors.brand,
                    ),
                  ),
                  const Spacer(),
                  VButton(
                    label: canAfford ? 'Buy' : 'Locked',
                    size: ButtonSize.small,
                    variant: canAfford
                        ? ButtonVariant.filled
                        : ButtonVariant.outlined,
                    onPressed: canAfford
                        ? () => _buyItem(context, ref, item)
                        : null,
                  ),
                ],
              ),
            ],
          ),
      ),
    );
  }

  void _previewItem(BuildContext context, WidgetRef ref, _ShopItem item) {
    final resident = ref.read(residentProvider).resident;
    showVSheet(
      context,
      Padding(
        padding: const EdgeInsets.all(VSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: VFontWeight.bold),
            ),
            const SizedBox(height: VSpacing.md),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: item.color, width: 3),
              ),
              child: CosmeticAvatar(
                imageUrl: resident?.avatarUrl,
                seed: resident?.id,
                size: 96,
              ),
            ),
            const SizedBox(height: VSpacing.sm),
            Text(
              item.description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: VSpacing.md),
            Text(
              '${item.price} coins · ${item.subtype}',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: VColors.brand),
            ),
          ],
        ),
      ),
      maxSize: 0.55,
    );
  }

  Future<void> _buyItem(
    BuildContext context,
    WidgetRef ref,
    _ShopItem item,
  ) async {
    if (category == _ShopCategory.cosmetics) {
      final cosmeticId = item.name.toLowerCase().replaceAll(' ', '_');
      final error = await CosmeticPurchaseService.purchaseWithCoins(
        cosmeticId: cosmeticId,
        coinPrice: item.price,
      );
      if (!context.mounted) return;
      if (error != null) {
        VFeedback.showMessage(context, error);
        return;
      }
      await ref.read(residentProvider.notifier).loadResident();
      VFeedback.showMessage(context, '${item.name} purchased!');
      return;
    }

    final notifier = ref.read(residentProvider.notifier);
    final spent = notifier.spendCoins(item.price);
    final success = spent && notifier.addDecoration(item.name);
    if (success && context.mounted) {
      VFeedback.showMessage(context, '${item.name} purchased!');
    } else if (context.mounted) {
      VFeedback.showMessage(context, 'Not enough coins for ${item.name}.');
    }
  }
}

class _DominionsTab extends ConsumerStatefulWidget {
  const _DominionsTab();

  @override
  ConsumerState<_DominionsTab> createState() => _DominionsTabState();
}

class _DominionsTabState extends ConsumerState<_DominionsTab> {
  List<Listing> _listings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  Future<void> _loadListings() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final listings = await MarketplaceService.getAllActiveListings();
      if (mounted) {
        setState(() {
          _listings = listings;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load listings';
        });
      }
    }
  }

  void _openListingDetail(Listing listing) {
    showVSheet(
      context,
      _DominionListingDetailSheet(listing: listing),
      maxSize: 0.85,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return GridView.builder(
        padding: const EdgeInsets.all(VSpacing.md),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.78,
          crossAxisSpacing: VSpacing.sm,
          mainAxisSpacing: VSpacing.sm,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: PrestigeNoir.surfaceRaised,
              borderRadius: BorderRadius.circular(VRadius.bento),
              border: Border.all(color: PrestigeNoir.borderLight),
            ),
            child: const Column(
              children: [
                Expanded(child: Pulse(borderRadius: 0)),
                Padding(
                  padding: EdgeInsets.all(VSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Pulse(height: 14, width: 80),
                      SizedBox(height: VSpacing.xs),
                      Pulse(height: 12, width: 50),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: VColors.error),
            const SizedBox(height: VSpacing.md),
            Text(_error!, style: const TextStyle(color: VColors.error)),
            const SizedBox(height: VSpacing.md),
            VButton(
              label: 'Retry',
              icon: const Icon(Icons.refresh),
              onPressed: _loadListings,
            ),
          ],
        ),
      );
    }

    if (_listings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.storefront_outlined,
              size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: VSpacing.md),
            const Text(
              'No active listings',
              style: TextStyle(fontWeight: VFontWeight.semiBold),
            ),
            const SizedBox(height: VSpacing.xs),
            Text(
              'Listings from your worlds will appear here.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadListings,
      color: Theme.of(context).colorScheme.primary,
      child: GridView.builder(
        padding: const EdgeInsets.all(VSpacing.md),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.78,
          crossAxisSpacing: VSpacing.sm,
          mainAxisSpacing: VSpacing.sm,
        ),
        itemCount: _listings.length,
        itemBuilder: (context, index) {
          final listing = _listings[index];
          return ListingCard(
            listing: listing,
            onTap: () => _openListingDetail(listing),
          );
        },
      ),
    );
  }
}

class _DominionListingDetailSheet extends StatelessWidget {
  final Listing listing;

  const _DominionListingDetailSheet({required this.listing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: PrestigeNoir.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(VRadius.bento),
        ),
      ),
      padding: const EdgeInsets.all(VSpacing.lg),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (listing.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(VRadius.bento),
                child: Image.network(
                  listing.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 200,
                    color: PrestigeNoir.surfaceRaised,
                    child: Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: PrestigeNoir.muted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: VSpacing.lg),
            ],
            Text(
              listing.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: VFontWeight.bold,
              ),
            ),
            const SizedBox(height: VSpacing.xs),
            if (listing.price != null)
              Row(
                children: [
                  const Icon(Icons.sell, size: VIconSize.sm, color: VColors.brand),
                  const SizedBox(width: VSpacing.xs),
                  Text(
                    listing.price!,
                    style: const TextStyle(
                      fontSize: VFontSize.bodyLg,
                      fontWeight: VFontWeight.bold,
                      color: VColors.brand,
                    ),
                  ),
                ],
              ),
            if (listing.priceNote != null && listing.priceNote!.isNotEmpty) ...[
              const SizedBox(height: VSpacing.xs),
              Text(
                listing.priceNote!,
                style: TextStyle(
                  fontSize: VFontSize.labelSm,
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: VSpacing.sm),
            Text(
              'Seller: ${listing.sellerName}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: VSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.sm,
                vertical: VSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: PrestigeNoir.accentSoft,
                borderRadius: BorderRadius.circular(VRadius.pill),
                border: Border.all(color: VColors.brand.withValues(alpha: 0.25)),
              ),
              child: Text(
                listing.category.name[0].toUpperCase() +
                    listing.category.name.substring(1),
                style: const TextStyle(
                  color: VColors.brand,
                  fontWeight: VFontWeight.semiBold,
                  fontSize: VFontSize.labelSm,
                ),
              ),
            ),
            const SizedBox(height: VSpacing.lg),
            Text(
              listing.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: VSpacing.xl),
            VButton(
              label: 'View in World',
              icon: const Icon(Icons.open_in_new),
              onPressed: () {
                context.push(exploreWorldPath(listing.worldId));
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: VSpacing.md),
          ],
        ),
      ),
    );
  }
}
