import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/subscription_service.dart';
import '../services/store_service.dart';
import '../state/resident_provider.dart';
import '../theme/colors.dart';
import '../theme/design_system.dart';
import '../utils/navigation.dart';
import '../widgets/core/glass_panel.dart';
import '../widgets/core/loading_state.dart';

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
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _purchasing = true;
      _purchaseMessage = null;
    });

    try {
      await StoreService.buyWealthTier(
        tier == SubscriptionTier.patrician ? 2 : 3,
      );

      if (mounted) {
        final resident = ref.read(residentProvider).resident;
        if (resident != null) {
          await SubscriptionService.setTier(resident.id, tier);
        }
        setState(() {
          _currentTier = tier;
          _purchasing = false;
          _purchaseMessage =
              'Subscription activated! Welcome to ${SubscriptionService.getBenefits(tier)['label']}.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _purchasing = false;
          _purchaseMessage = null;
        });
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Purchase failed. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('The Vault'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => safeBack(context),
        ),
      ),
      body: _loading
          ? const SafeArea(child: GlassLoadingList(itemCount: 3))
          : ListView(
              padding: const EdgeInsets.all(Spacing.lg),
              children: [
                // ── Header ────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.tertiary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            RadiusTokens.cardFeatured,
                          ),
                        ),
                        child: const Icon(
                          Icons.diamond_outlined,
                          size: 36,
                          color: AppColors.tertiary,
                        ),
                      ),
                      const SizedBox(height: Spacing.md),
                      Text(
                        'The Vault',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: FontSizes.headlineLg,
                          fontWeight: FontWeights.bold,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        'Unlock sovereign privileges',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.xl),

                // ── Purchase confirmation message ────────────────
                if (_purchaseMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(Spacing.md),
                    margin: const EdgeInsets.only(bottom: Spacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(RadiusTokens.card),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: Spacing.sm),
                        Expanded(
                          child: Text(
                            _purchaseMessage!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.success,
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
                    padding: const EdgeInsets.only(bottom: Spacing.md),
                    child: _TierCard(
                      tierName: benefits['label'] as String,
                      tierColor:
                          (benefits['color'] as Color?) ??
                          AppColors.inkSecondary,
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

                const SizedBox(height: Spacing.xl),

                // ── Footer ────────────────────────────────────────
                Center(
                  child: Text(
                    'All subscriptions support the Vertiege realm.\nCancel anytime.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.inkMuted,
                      height: LineHeight.body,
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.lg),

                // ── Restore purchases ────────────────────────────
                Center(
                  child: TextButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await StoreService.restorePurchases();
                      await _loadTier();
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Purchases restored'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'Restore Purchases',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.xxl),
              ],
            ),
    );
  }

  List<_TierFeature> _buildFeatures(Map<String, dynamic> benefits) {
    final features = <_TierFeature>[];

    final worldLimit = benefits['worldLimit'] as int;
    final shields = benefits['streakShieldsPerMonth'] as int;
    final priorityV = benefits['priorityVerification'] as bool;
    final goldN = benefits['goldName'] as bool;
    final customBg = benefits['customBackground'] as bool;
    final analytics = benefits['analytics'] as bool;

    features.add(
      _TierFeature(
        label: worldLimit >= 999
            ? 'Create unlimited worlds'
            : 'Create up to $worldLimit worlds',
        included: true,
      ),
    );

    features.add(
      _TierFeature(
        label: shields > 0
            ? '$shields streak shield${shields > 1 ? "s" : ""}/month'
            : 'No streak shields',
        included: shields > 0,
      ),
    );

    features.add(
      const _TierFeature(label: 'Gold profile frame', included: true),
    );

    features.add(
      _TierFeature(label: 'Priority verification queue', included: priorityV),
    );

    features.add(_TierFeature(label: 'Gold name treatment', included: goldN));

    features.add(
      _TierFeature(label: 'Custom profile background', included: customBg),
    );

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

    return GlassPanel(
      padding: const EdgeInsets.all(Spacing.xl),
      borderRadius: BorderRadius.circular(RadiusTokens.cardFeatured),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Tier name + active badge ────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tierName,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: FontSizes.headlineMd,
                  fontWeight: FontWeights.bold,
                  color: tierColor,
                ),
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: Spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: tierColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(RadiusTokens.pill),
                    border: Border.all(color: tierColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'CURRENT',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: tierColor,
                      fontWeight: FontWeights.bold,
                      letterSpacing: LetterSpacing.label,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Spacing.lg),

          // ── Price ───────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: FontSizes.displayXl,
                  fontWeight: FontWeights.bold,
                  color: AppColors.ink,
                ),
              ),
              if (pricePeriod.isNotEmpty) ...[
                const SizedBox(width: Spacing.xs),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    pricePeriod,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: Spacing.lg),

          // ── Divider ─────────────────────────────────────────
          Container(height: 1, color: AppColors.glassBorder),
          const SizedBox(height: Spacing.lg),

          // ── Features ────────────────────────────────────────
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    feature.included
                        ? Icons.check_circle
                        : Icons.remove_circle_outline,
                    size: 18,
                    color: feature.included
                        ? AppColors.success
                        : AppColors.inkMuted.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      feature.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: feature.included
                            ? AppColors.inkSecondary
                            : AppColors.inkMuted.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: Spacing.lg),

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
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.ink,
                        ),
                      )
                    : const Icon(Icons.star),
                label: Text(isLoading ? 'Activating...' : 'UPGRADE'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.tertiary,
                  foregroundColor: AppColors.onTertiary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(RadiusTokens.card),
                  ),
                ),
              ),
            )
          else if (isActive)
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: tierColor,
                  side: BorderSide(color: tierColor.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(RadiusTokens.card),
                  ),
                ),
                child: const Text('ACTIVE'),
              ),
            ),
        ],
      ),
    );
  }
}
