import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../router/world_navigation.dart';
import '../models/listing.dart';
import '../services/marketplace_service.dart';
import '../services/cosmetic_purchase_service.dart';
import '../state/resident_provider.dart';
import '../forui/v_hub_page.dart';
import '../theme/v_colors.dart';
import '../theme/v_tokens.dart';
import '../widgets/worlds/listing_card.dart';
import '../widgets/core/shimmer.dart';
import '../widgets/core/empty_state.dart';
import '../widgets/core/v_feedback.dart';
import '../widgets/profile/cosmetic_avatar.dart';

enum _ShopCategory { passes, seeds, boosts, cosmetics }

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
    final coins = resident?.sovereignCoins ?? 0;
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
            color: VColors.tertiary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(VRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.monetization_on,
                size: VIconSize.sm,
                color: VColors.tertiary,
              ),
              const SizedBox(width: VSpacing.xs),
              Text(
                '$coins',
                style: const TextStyle(
                  fontSize: VFontSize.bodyMd,
                  fontWeight: VFontWeight.bold,
                  color: VColors.tertiary,
                ),
              ),
            ],
          ),
        ),
      ],
      body: FTabs(
        expands: true,
        control: const FTabControl.managed(),
        children: [
          FTabEntry(
            label: const Text('Cosmetics'),
            child: _ShopGrid(
              category: _ShopCategory.cosmetics,
              items: _cosmetics,
              coins: coins,
            ),
          ),
          const FTabEntry(
            label: Text('Dominions'),
            child: _DominionsTab(),
          ),
          const FTabEntry(
            label: Text('Coming soon'),
            child: _PayToWinComingSoonTab(),
          ),
        ],
      ),
    );
  }

  static const _passes = <_ShopItem>[
    _ShopItem(
      'Neon District Pass',
      'Unlock Neon District wealth world',
      200,
      Icons.diamond,
      VColors.tertiary,
      'Pass',
    ),
    _ShopItem(
      'Crystal Shore Pass',
      'Unlock Crystal Shore wealth world',
      150,
      Icons.diamond,
      VColors.primary,
      'Pass',
    ),
    _ShopItem(
      'Azure Coast Pass',
      'Unlock Azure Coast wealth world',
      300,
      Icons.diamond,
      VColors.success,
      'Pass',
    ),
    _ShopItem(
      'Tech Sprawl Pass',
      'Unlock Tech Sprawl wealth world',
      250,
      Icons.diamond,
      VColors.warning,
      'Pass',
    ),
  ];

  static const _seeds = <_ShopItem>[
    _ShopItem(
      'Seed of Creation',
      'Create your own Dominion world',
      500,
      Icons.shield,
      VColors.success,
      'Seed',
    ),
    _ShopItem(
      'Double Seed Bundle',
      'Two Seeds of Creation at a discount',
      850,
      Icons.shield,
      VColors.tertiary,
      'Seed',
    ),
  ];

  static const _boosts = <_ShopItem>[
    _ShopItem(
      'Profile Spotlight',
      'Highlight your profile card for 24 hours',
      100,
      Icons.auto_awesome,
      VColors.primary,
      'Flair',
    ),
    _ShopItem(
      'Draft Cabinet',
      'Unlock an extra saved-draft slot',
      150,
      Icons.inventory_2_outlined,
      VColors.tertiary,
      'Convenience',
    ),
    _ShopItem(
      'Reaction Pack',
      'Add cosmetic reactions to your palette',
      200,
      Icons.add_reaction_outlined,
      VColors.warning,
      'Cosmetic',
    ),
    _ShopItem(
      'Nameplate Spark',
      'Add a subtle spark to your nameplate',
      75,
      Icons.auto_awesome,
      VColors.success,
      'Cosmetic',
    ),
  ];

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.store_outlined,
              size: 48,
              color: isDark
                  ? VColors.onSurfaceVariantDark
                  : VColors.onSurfaceVariant,
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
                color: isDark
                    ? VColors.onSurfaceVariantDark
                    : VColors.onSurfaceVariant,
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
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: canAfford ? () => _buyItem(context, ref, item) : null,
      onLongPress: () => _previewItem(context, item),
      child: FCard.raw(
        child: Padding(
          padding: const EdgeInsets.all(VSpacing.md),
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
                        color: isDark
                            ? VColors.onSurfaceVariantDark
                            : VColors.onSurfaceVariant,
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
                  child: Icon(
                    item.icon,
                    size: VIconSize.lg,
                    color: item.color,
                  ),
                ),
                const SizedBox(height: VSpacing.sm),
                Text(
                  item.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: VFontWeight.semiBold,
                    color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? VColors.onSurfaceVariantDark
                        : VColors.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      Icons.monetization_on,
                      size: VIconSize.xs,
                      color: VColors.tertiary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${item.price}',
                      style: const TextStyle(
                        fontSize: VFontSize.labelSm,
                        fontWeight: VFontWeight.bold,
                        color: VColors.tertiary,
                      ),
                    ),
                    const Spacer(),
                    FButton(
                      variant: canAfford
                          ? FButtonVariant.primary
                          : FButtonVariant.outline,
                      size: FButtonSizeVariant.sm,
                      onPress: canAfford
                          ? () => _buyItem(context, ref, item)
                          : null,
                      child: Text(canAfford ? 'Buy' : 'Locked'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    );
  }

  void _previewItem(BuildContext context, _ShopItem item) {
    final resident = ref.read(residentProvider).resident;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(VSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.name,
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                fontWeight: VFontWeight.bold,
              ),
            ),
            const SizedBox(height: VSpacing.md),
            CosmeticAvatar(
              imageUrl: resident?.avatarUrl,
              size: 96,
              borderColor: item.color,
            ),
            const SizedBox(height: VSpacing.sm),
            Text(
              item.description,
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: VSpacing.md),
            Text(
              '${item.price} coins · ${item.subtype}',
              style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                color: VColors.tertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _buyItem(
    BuildContext context,
    WidgetRef ref,
    _ShopItem item,
  ) async {
    if (category == _ShopCategory.boosts || category == _ShopCategory.passes) {
      if (context.mounted) {
        VFeedback.showMessage(
          context,
          'Paid progression and world access are disabled in v1.',
        );
      }
      return;
    }

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
      final listings = await MarketplaceService.getAllActiveListings(limit: 50);
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DominionListingDetailSheet(listing: listing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
              color: isDark
                  ? VColors.surfaceContainerDark
                  : VColors.surfaceContainer,
              borderRadius: BorderRadius.circular(VRadius.lg),
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
            Icon(Icons.error_outline, size: 48, color: VColors.error),
            const SizedBox(height: VSpacing.md),
            Text(_error!, style: const TextStyle(color: VColors.error)),
            const SizedBox(height: VSpacing.md),
            FilledButton.icon(
              onPressed: _loadListings,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
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
              color: isDark
                  ? VColors.onSurfaceVariantDark
                  : VColors.onSurfaceVariant,
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
                color: isDark
                    ? VColors.onSurfaceVariantDark
                    : VColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadListings,
      color: VColors.primary,
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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? VColors.surfaceContainerDark : VColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(VRadius.xl),
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
                borderRadius: BorderRadius.circular(VRadius.lg),
                child: Image.network(
                  listing.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: isDark
                        ? VColors.surfaceContainerHighDark
                        : VColors.surfaceContainerHigh,
                    child: Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: isDark
                          ? VColors.onSurfaceVariantDark
                          : VColors.onSurfaceVariant,
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
                  Icon(
                    Icons.sell,
                    size: VIconSize.sm,
                    color: VColors.tertiary,
                  ),
                  const SizedBox(width: VSpacing.xs),
                  Text(
                    listing.price!,
                    style: const TextStyle(
                      fontSize: VFontSize.bodyLg,
                      fontWeight: VFontWeight.bold,
                      color: VColors.tertiary,
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
                  color: isDark
                      ? VColors.onSurfaceVariantDark
                      : VColors.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: VSpacing.sm),
            Text(
              'Seller: ${listing.sellerName}',
              style: TextStyle(
                color: isDark
                    ? VColors.onSurfaceVariantDark
                    : VColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: VSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.sm,
                vertical: VSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: VColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(VRadius.pill),
              ),
              child: Text(
                listing.category.name[0].toUpperCase() +
                    listing.category.name.substring(1),
                style: const TextStyle(
                  color: VColors.primary,
                  fontWeight: VFontWeight.semiBold,
                  fontSize: VFontSize.labelSm,
                ),
              ),
            ),
            const SizedBox(height: VSpacing.lg),
            Text(
              listing.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? VColors.onSurfaceVariantDark
                    : VColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: VSpacing.xl),
            FilledButton.icon(
              onPressed: () {
                context.push(exploreWorldPath(listing.worldId));
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('View in World'),
            ),
            const SizedBox(height: VSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _PayToWinComingSoonTab extends StatelessWidget {
  const _PayToWinComingSoonTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: AppEmptyState(
        title: 'Passes, seeds & boosts',
        description:
            'Pay-to-win items stay out of v1. Cosmetics and dominions are available in other tabs.',
        icon: Icons.lock_clock_outlined,
      ),
    );
  }
}
