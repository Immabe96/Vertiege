import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../forui/v_hub_page.dart';
import '../../models/listing.dart';
import '../../router/world_navigation.dart';
import '../../services/chat_service.dart';
import '../../config/world_capability_matrix.dart';
import '../../services/analytics_events.dart';
import '../../services/analytics_service.dart';
import '../../services/marketplace_service.dart';
import '../../state/resident_provider.dart';
import '../../state/world_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../widgets/worlds/listing_card.dart';
import '../../widgets/worlds/create_listing_dialog.dart';
import '../../widgets/core/screen_loading.dart';
import '../../widgets/core/empty_state.dart';
import '../../widgets/core/v_accessible.dart';
import '../../widgets/core/v_feedback.dart';
import '../../widgets/core/new_user_context_hint.dart';
import '../../ui/icons/v_icons.dart';

class WorldMarketplaceScreen extends ConsumerStatefulWidget {
  final String worldId;
  final bool isMember;

  const WorldMarketplaceScreen({
    super.key,
    required this.worldId,
    this.isMember = false,
  });

  @override
  ConsumerState<WorldMarketplaceScreen> createState() =>
      _WorldMarketplaceScreenState();
}

class _WorldMarketplaceScreenState extends ConsumerState<WorldMarketplaceScreen> {
  List<Listing> _listings = [];
  bool _loading = true;
  String? _error;
  ListingCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadListings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.logEvent(
        AnalyticsEvents.marketplaceViewed,
        parameters: {'world_id': widget.worldId},
      );
    });
  }

  Future<void> _loadListings() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final listings = await MarketplaceService.getListings(
        widget.worldId,
        category: _selectedCategory,
        status: ListingStatus.active,
      );
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

  void _openCreateListing() {
    final resident = ref.read(residentProvider).resident;
    final world = ref.read(worldProvider).worlds[widget.worldId];
    if (world == null) {
      VFeedback.showError(context, 'World not found');
      return;
    }
    final block = WorldCapabilityMatrix.blockReasonCreateListing(
      resident,
      world,
      isJoined: widget.isMember,
    );
    if (block != null) {
      VFeedback.showMessage(context, block);
      return;
    }
    showDialog<bool>(
      context: context,
      builder: (ctx) => CreateListingDialog(worldId: widget.worldId),
    ).then((result) {
      if (result == true) _loadListings();
    });
  }

  void _openListingDetail(Listing listing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ListingDetailSheet(
        listing: listing,
        worldId: widget.worldId,
        isMember: widget.isMember,
        onPurchased: _loadListings,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resident = ref.watch(residentProvider).resident;
    final world = ref.watch(worldProvider).worlds[widget.worldId];
    final canList = world != null &&
        WorldCapabilityMatrix.canCreateListing(
          resident,
          world,
          isJoined: widget.isMember,
        );

    return VHubPage(
      title: 'Marketplace',
      showBack: true,
      headerActions: [
        if (widget.isMember && canList)
          VAccessibleHeaderAction(
            label: 'Create listing',
            icon: const Icon(Icons.add),
            onPress: _openCreateListing,
          ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NewUserContextHint(
            message: WorldCapabilityMatrix.marketplaceRepHint(),
          ),
          if (world != null &&
              WorldCapabilityMatrix.blockReasonCreateListing(
                    resident,
                    world,
                    isJoined: widget.isMember,
                  ) !=
                  null)
            NewUserContextHint(
              message: WorldCapabilityMatrix.createListingGateHint(),
              icon: Icons.lock_outline,
            ),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const ScreenLoading.grid();
    }

    if (_error != null) {
      return AppErrorState(message: _error, onRetry: _loadListings);
    }

    if (_listings.isEmpty) {
      return AppEmptyState(
        title: 'No listings yet',
        description: widget.isMember
            ? 'Be the first to create a listing!'
            : 'This world has no active listings.',
        icon: Icons.storefront_outlined,
        actionLabel: widget.isMember ? 'Create Listing' : null,
        onAction: widget.isMember ? _openCreateListing : null,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadListings,
      color: VColors.primary,
      child: Column(
        children: [
          _CategoryChips(
            selected: _selectedCategory,
            onSelected: (cat) {
              setState(() => _selectedCategory = cat);
              _loadListings();
            },
          ),
          Expanded(
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
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final ListingCategory? selected;
  final ValueChanged<ListingCategory?> onSelected;

  const _CategoryChips({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.md,
        vertical: VSpacing.sm,
      ),
      child: Row(
        children: [
          _Chip(
            label: 'All',
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          const SizedBox(width: VSpacing.xs),
          ...ListingCategory.values.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(right: VSpacing.xs),
              child: _Chip(
                label: cat.name[0].toUpperCase() + cat.name.substring(1),
                selected: selected == cat,
                onTap: () => onSelected(cat),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return VMinTapTarget(
      semanticsLabel: label,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.md,
          vertical: VSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? VColors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(VRadius.pill),
          border: Border.all(
            color: selected
                ? VColors.primary
                : VColors.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: VFontSize.labelSm,
            fontWeight: selected ? VFontWeight.semiBold : VFontWeight.regular,
            color: selected ? VColors.primary : null,
          ),
        ),
      ),
    );
  }
}

class _ListingDetailSheet extends ConsumerStatefulWidget {
  final Listing listing;
  final String worldId;
  final bool isMember;
  final VoidCallback onPurchased;

  const _ListingDetailSheet({
    required this.listing,
    required this.worldId,
    required this.isMember,
    required this.onPurchased,
  });

  @override
  ConsumerState<_ListingDetailSheet> createState() =>
      _ListingDetailSheetState();
}

class _ListingDetailSheetState extends ConsumerState<_ListingDetailSheet> {
  bool _purchasing = false;

  Listing get listing => widget.listing;

  Future<void> _contactSeller() async {
    final resident = ref.read(residentProvider).resident;
    if (resident == null) return;

    Navigator.of(context).pop();

    final room = await ChatService.getOrCreateRoom(
      resident.id,
      listing.sellerId,
    );
    if (!context.mounted || room == null) return;

    final draft =
        'Hi — I\'m interested in your listing "${listing.title}".';
    context.push(
      dmPath(room['id'] as String, draft: draft),
    );
  }

  Future<void> _purchase() async {
    if (listing.coinPrice == null) return;
    setState(() => _purchasing = true);
    try {
      final result = await MarketplaceService.purchaseListing(listing.id);
      if (!mounted) return;
      if (result['success'] == true) {
        await ref.read(residentProvider.notifier).loadResident();
        widget.onPurchased();
        Navigator.of(context).pop();
        AnalyticsService.logEvent(
          AnalyticsEvents.marketplacePurchase,
          parameters: {
            'world_id': widget.worldId,
            'listing_id': listing.id,
            'coin_price': listing.coinPrice ?? 0,
          },
        );
        final buyerRep = result['buyer_rep_delta'];
        final msg = buyerRep is num
            ? 'Purchased for ${listing.coinPrice} coins · +${buyerRep.toInt()} rep'
            : 'Purchased for ${listing.coinPrice} coins';
        VFeedback.showMessage(context, msg);
      } else {
        VFeedback.showError(
          context,
          result['error']?.toString() ?? 'Purchase failed',
        );
      }
    } catch (e) {
      if (mounted) {
        VFeedback.showError(context, 'Purchase failed: $e');
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final resident = ref.watch(residentProvider).resident;
    final world = ref.watch(worldProvider).worlds[widget.worldId];
    final isOwner = resident?.id == listing.sellerId;
    final canBuy = widget.isMember &&
        !isOwner &&
        listing.status == ListingStatus.active &&
        listing.coinPrice != null &&
        listing.coinPrice! > 0;
    final balance = resident?.sovereignCoins ?? 0;
    final taxRate = world?.taxRate ?? 0;
    final tax = canBuy ? (listing.coinPrice! * taxRate / 100).floor() : 0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? VColors.surfaceContainerDark : VColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(VRadius.xl)),
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
                  const Icon(
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
            if (listing.coinPrice != null && listing.coinPrice! > 0) ...[
              const SizedBox(height: VSpacing.sm),
              Row(
                children: [
                  const Icon(
                    Icons.monetization_on,
                    size: VIconSize.sm,
                    color: VColors.warning,
                  ),
                  const SizedBox(width: VSpacing.xs),
                  Text(
                    '${listing.coinPrice} sovereign coins',
                    style: const TextStyle(
                      fontSize: VFontSize.bodyMd,
                      fontWeight: VFontWeight.bold,
                      color: VColors.warning,
                    ),
                  ),
                ],
              ),
              if (taxRate > 0)
                Text(
                  'Includes $tax coin tax to world treasury ($taxRate%)',
                  style: theme.textTheme.bodySmall?.copyWith(
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
            if (canBuy) ...[
              Text(
                'Your balance: $balance coins',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: VSpacing.sm),
              FilledButton.icon(
                onPressed: _purchasing || balance < listing.coinPrice!
                    ? null
                    : _purchase,
                icon: _purchasing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.shopping_cart_checkout),
                label: Text('Buy for ${listing.coinPrice} coins'),
              ),
              const SizedBox(height: VSpacing.sm),
            ],
            if (listing.status == ListingStatus.active && !isOwner)
              Semantics(
                button: true,
                label: 'Contact seller about ${listing.title}',
                child: FilledButton.icon(
                  onPressed: _contactSeller,
                  icon: const Icon(VIcons.message),
                  label: const Text('Contact Seller'),
                  style: FilledButton.styleFrom(
                    foregroundColor: VColors.onPrimary,
                    backgroundColor: VColors.primary,
                  ),
                ),
              ),
            if (isOwner && listing.status == ListingStatus.active)
              OutlinedButton.icon(
                onPressed: () async {
                  final success = await MarketplaceService.cancelListing(
                    listing.id,
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    if (success) {
                      VFeedback.showMessage(context, 'Listing cancelled');
                    } else {
                      VFeedback.showError(context, 'Failed to cancel listing');
                    }
                  }
                },
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel Listing'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: VColors.error,
                  side: const BorderSide(color: VColors.error),
                ),
              ),
            if (listing.status == ListingStatus.sold)
              Container(
                padding: const EdgeInsets.all(VSpacing.md),
                decoration: BoxDecoration(
                  color: VColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(VRadius.md),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(VIcons.badgeCheck, color: VColors.success),
                    SizedBox(width: VSpacing.sm),
                    Text(
                      'SOLD',
                      style: TextStyle(
                        color: VColors.success,
                        fontWeight: VFontWeight.bold,
                        fontSize: VFontSize.bodyLg,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: VSpacing.md),
          ],
        ),
      ),
    );
  }
}
