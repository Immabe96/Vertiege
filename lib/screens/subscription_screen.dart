import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/subscription_service.dart';
import '../services/store_service.dart';
import '../state/resident_provider.dart';
import '../theme/v_colors.dart';
import '../forui/v_hub_page.dart';
import '../theme/v_tokens.dart';
import '../widgets/core/screen_loading.dart';
import '../ui/icons/v_icons.dart';
import '../ui/buttons/v_button.dart';
import '../widgets/core/v_feedback.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  SubscriptionTier _currentTier = SubscriptionTier.resident;
  bool _loading = true;
  bool _purchasing = false;
  String? _purchaseMessage;

  @override
  void initState() {
    super.initState();
    _loadTier();
  }

  Future<void> _loadTier() async {
    final resident = ref.read(residentProvider).resident;
    if (resident != null) {
      final tier = await SubscriptionService.getTier(resident.id);
      if (mounted) {
        setState(() {
          _currentTier = tier;
          _loading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _purchase(SubscriptionTier tier) async {
    setState(() {
      _purchasing = true;
      _purchaseMessage = null;
    });

    try {
      final productId = tier == SubscriptionTier.patrician
          ? SubscriptionService.patricianProductId
          : SubscriptionService.sovereignEliteProductId;
      final result = await StoreService.buyProduct(productId);
      if (result != StorePurchaseState.purchased) {
        throw StateError('Purchase was not completed.');
      }

      final token = StoreService.lastPurchaseToken;
      if (token == null || token.isEmpty) {
        throw StateError('Missing purchase receipt.');
      }

      final resident = ref.read(residentProvider).resident;
      if (resident == null) {
        throw StateError('Sign in required.');
      }

      final verifyError = await SubscriptionService.verifyPurchase(
        productId: productId,
        purchaseToken: token,
      );
      if (verifyError != null) {
        throw StateError(verifyError);
      }

      if (mounted) {
        await _loadTier();
        setState(() {
          _purchasing = false;
          _purchaseMessage = 'Subscription active. Cosmetic perks unlocked.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _purchasing = false;
          _purchaseMessage = null;
        });
        VFeedback.showMessage(context, 'Purchase failed. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return VHubPage(
      title: 'The Vault',
      showBack: true,
      body: _loading
          ? const ScreenLoading.list()
          : ListView(
              padding: const EdgeInsets.all(VSpacing.lg),
              children: [
                // ── Header ────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: VColors.tertiary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            VRadius.md,
                          ),
                        ),
                        child: const Icon(
                          Icons.diamond_outlined,
                          size: 36,
                          color: VColors.tertiary,
                        ),
                      ),
                      const SizedBox(height: VSpacing.md),
                      Text(
                        'The Vault',
                        style: TextStyle(
                          fontSize: VFontSize.headlineLg,
                          fontWeight: VFontWeight.bold,
                          color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: VSpacing.xs),
                      Text(
                        'Unlock sovereign privileges',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isDark
                              ? VColors.onSurfaceVariantDark
                              : VColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: VSpacing.xl),

                // ── Purchase confirmation message ────────────────
                if (_purchaseMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(VSpacing.md),
                    margin: const EdgeInsets.only(bottom: VSpacing.lg),
                    decoration: BoxDecoration(
                      color: VColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(VRadius.lg),
                      border: Border.all(
                        color: VColors.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: VColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: VSpacing.sm),
                        Expanded(
                          child: Text(
                            _purchaseMessage!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: VColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Tier Cards ───────────────────────────────────
                ...SubscriptionTier.values.map((tier) {
                  final benefits = SubscriptionService.getBenefits(tier);
                  final isActive = tier == _currentTier;
                  final price = tier == SubscriptionTier.resident
                      ? 'Free'
                      : tier == SubscriptionTier.patrician
                      ? '\$4.99'
                      : '\$14.99';
                  final pricePeriod = tier == SubscriptionTier.resident
                      ? ''
                      : '/month';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: VSpacing.md),
                    child: _TierCard(
                      tierName: benefits['label'] as String,
                      tierColor:
                          (benefits['color'] as Color?) ??
                          (isDark
                              ? VColors.onSurfaceVariantDark
                              : VColors.onSurfaceVariant),
                      price: price,
                      pricePeriod: pricePeriod,
                      isActive: isActive,
                      isLoading: _purchasing && !isActive,
                      features: _buildFeatures(benefits),
                      onUpgrade: isActive || _purchasing
                          ? null
                          : () => _purchase(tier),
                    ),
                  );
                }),

                const SizedBox(height: VSpacing.xl),

                // ── Footer ────────────────────────────────────────
                Center(
                  child: Text(
                    'All subscriptions support the Vertiege realm.\nCancel anytime.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? VColors.onSurfaceVariantDark
                          : VColors.onSurfaceVariant,
                      height: VLineHeight.body,
                    ),
                  ),
                ),
                const SizedBox(height: VSpacing.lg),

                // ── Restore purchases ────────────────────────────
                Center(
                  child: VButton(
                    label: 'Restore Purchases',
                    onPressed: () async {
                      await StoreService.restorePurchases();
                      await _loadTier();
                      if (mounted) {
                        VFeedback.showMessage(context, 'Purchases restored');
                      }
                    },
                    variant: ButtonVariant.text,
                  ),
                ),
                const SizedBox(height: VSpacing.xxl),
              ],
            ),
    );
  }

  List<_TierFeature> _buildFeatures(Map<String, dynamic> benefits) {
    final features = <_TierFeature>[];

    final cosmeticSlots = benefits['extraCosmeticSlots'] as int;
    final priorityV = benefits['priorityReviewVisibility'] as bool;
    final goldN = benefits['goldName'] as bool;
    final customFrame = benefits['customFrame'] as bool;
    final analytics = benefits['analytics'] as bool;
    final savedDrafts = benefits['savedDrafts'] as int;

    features.add(
      _TierFeature(
        label: cosmeticSlots > 0
            ? '+$cosmeticSlots equipped cosmetic slots'
            : 'Standard cosmetic slots',
        included: true,
      ),
    );

    features.add(
      _TierFeature(
        label: 'Up to $savedDrafts saved drafts',
        included: true,
      ),
    );

    features.add(
      const _TierFeature(label: 'Gold profile frame', included: true),
    );

    features.add(_TierFeature(
      label: 'Review queue status visibility',
      included: priorityV,
    ));

    features.add(_TierFeature(label: 'Gold name treatment', included: goldN));

    features.add(_TierFeature(label: 'Custom profile frame', included: customFrame));

    features.add(
      _TierFeature(label: 'Analytics dashboard', included: analytics),
    );

    features.add(_TierFeature(label: 'Early access features', included: goldN));

    features.add(
      const _TierFeature(label: 'Exclusive tier badge', included: true),
    );

    return features;
  }
}

class _TierFeature {
  final String label;
  final bool included;

  const _TierFeature({required this.label, required this.included});
}

class _TierCard extends StatelessWidget {
  final String tierName;
  final Color tierColor;
  final String price;
  final String pricePeriod;
  final bool isActive;
  final bool isLoading;
  final List<_TierFeature> features;
  final VoidCallback? onUpgrade;

  const _TierCard({
    required this.tierName,
    required this.tierColor,
    required this.price,
    required this.pricePeriod,
    required this.isActive,
    required this.isLoading,
    required this.features,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return _Card(
      padding: const EdgeInsets.all(VSpacing.xl),
      borderRadius: BorderRadius.circular(VRadius.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Tier name + active badge ────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tierName,
                style: TextStyle(
                  fontSize: VFontSize.headlineMd,
                  fontWeight: VFontWeight.bold,
                  color: tierColor,
                ),
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VSpacing.md,
                    vertical: VSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: tierColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(VRadius.pill),
                    border: Border.all(color: tierColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'CURRENT',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: tierColor,
                      fontWeight: VFontWeight.bold,
                      letterSpacing: 0,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: VSpacing.lg),

          // ── Price ───────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: TextStyle(
                  fontSize: VFontSize.displayXl,
                  fontWeight: VFontWeight.bold,
                  color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
                ),
              ),
              if (pricePeriod.isNotEmpty) ...[
                const SizedBox(width: VSpacing.xs),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    pricePeriod,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? VColors.onSurfaceVariantDark
                              .withValues(alpha: 0.5)
                          : VColors.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: VSpacing.lg),

          // ── Divider ─────────────────────────────────────────
          Container(
            height: 1,
            color: isDark ? VColors.glassBorderDark : VColors.glassBorder,
          ),
          const SizedBox(height: VSpacing.lg),

          // ── Features ────────────────────────────────────────
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: VSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    feature.included
                        ? Icons.check_circle
                        : Icons.remove_circle_outline,
                    size: 18,
                    color: feature.included
                        ? VColors.success
                        : (isDark
                            ? VColors.onSurfaceVariantDark
                            : VColors.onSurfaceVariant).withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: VSpacing.sm),
                  Expanded(
                    child: Text(
                      feature.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: feature.included
                            ? (isDark
                                ? VColors.onSurfaceVariantDark
                                : VColors.onSurfaceVariant)
                            : (isDark
                                ? VColors.onSurfaceVariantDark
                                : VColors.onSurfaceVariant).withValues(
                                alpha: 0.5,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: VSpacing.lg),

          // ── Upgrade button ──────────────────────────────────
          if (onUpgrade != null)
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: isLoading ? null : onUpgrade,
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: FCircularProgress(),
                      )
                    : const Icon(VIcons.sparkles),
                label: Text(isLoading ? 'Activating...' : 'UPGRADE'),
                style: FilledButton.styleFrom(
                  backgroundColor: VColors.tertiary,
                  foregroundColor: VColors.onTertiary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(VRadius.lg),
                  ),
                ),
              ),
            )
          else if (isActive)
            VButton(
              label: 'ACTIVE',
              onPressed: null,
              variant: ButtonVariant.outlined,
            ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;

  const _Card({required this.child, this.padding, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding ?? const EdgeInsets.all(VSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? VColors.surfaceContainerDark : VColors.surfaceContainerLow,
        borderRadius: borderRadius ?? BorderRadius.circular(VRadius.lg),
        border: Border.all(
          color: isDark ? VColors.outlineVariantDark : VColors.outlineVariant,
        ),
      ),
      child: child,
    );
  }
}
