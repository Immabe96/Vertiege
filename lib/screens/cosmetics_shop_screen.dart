import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../theme/design_system.dart';
import '../state/resident_provider.dart';
import '../widgets/core/glass_panel.dart';
import '../widgets/core/fade_in.dart';

class CosmeticsShopScreen extends ConsumerStatefulWidget {
  const CosmeticsShopScreen({super.key});

  @override
  ConsumerState<CosmeticsShopScreen> createState() => _CosmeticsShopScreenState();
}

class _CosmeticsShopScreenState extends ConsumerState<CosmeticsShopScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final List<_ShopItem> _frames = const [
    _ShopItem('Violet Halo', 'Glowing violet border', 30, Icons.circle_outlined, AppColors.primary),
    _ShopItem('Gold Trim', 'Golden prestige border', 50, Icons.circle_outlined, AppColors.tertiary),
    _ShopItem('Obsidian', 'Dark obsidian frame', 25, Icons.circle_outlined, AppColors.inkMuted),
    _ShopItem('Crimson Edge', 'Red warning border', 40, Icons.circle_outlined, AppColors.error),
    _ShopItem('Mystic Blue', 'Ocean-blue glow', 35, Icons.circle_outlined, AppColors.tierHighRoller),
  ];

  final List<_ShopItem> _colors = const [
    _ShopItem('Gold Name', 'Golden name color', 60, Icons.palette, AppColors.tertiary),
    _ShopItem('Violet Ink', 'Violet name color', 45, Icons.palette, AppColors.primary),
    _ShopItem('Crimson Ink', 'Crimson name color', 40, Icons.palette, AppColors.error),
    _ShopItem('Mystic Ink', 'Mystic blue name color', 35, Icons.palette, AppColors.mysticBlue),
    _ShopItem('Blue Ink', 'Eel blue name color', 50, Icons.palette, AppColors.eelBlue),
  ];

  final List<_ShopItem> _banners = const [
    _ShopItem('Cosmic Banner', 'Starry space pattern', 80, Icons.auto_awesome, AppColors.primary),
    _ShopItem('Forge Banner', 'Molten gold pattern', 100, Icons.auto_awesome, AppColors.tertiary),
    _ShopItem('Nature Banner', 'Emerald forest pattern', 70, Icons.auto_awesome, AppColors.success),
    _ShopItem('Crimson Banner', 'Crimson flame pattern', 65, Icons.auto_awesome, AppColors.error),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resident = ref.watch(residentProvider).resident;
    final coins = resident?.sovereignCoins ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sovereign Regalia'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Spacing.md),
            child: GlassPanel(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on, size: IconSizes.sm, color: AppColors.tertiary),
                  const SizedBox(width: Spacing.xs),
                  Text(
                    '$coins',
                    style: const TextStyle(
                      fontSize: FontSizes.bodyMd,
                      fontWeight: FontWeights.bold,
                      color: AppColors.tertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: Spacing.sm),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppColors.tertiary,
            unselectedLabelColor: AppColors.inkMuted,
            labelStyle: const TextStyle(
              fontSize: FontSizes.labelSm,
              fontWeight: FontWeights.semiBold,
              letterSpacing: LetterSpacing.label,
            ),
            tabs: const [
              Tab(text: 'PROFILE FRAMES'),
              Tab(text: 'NAME COLORS'),
              Tab(text: 'WORLD BANNERS'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildShopGrid(_frames, coins),
                _buildShopGrid(_colors, coins),
                _buildShopGrid(_banners, coins),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopGrid(List<_ShopItem> items, int coins) {
    return GridView.builder(
      padding: const EdgeInsets.all(Spacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.9,
        crossAxisSpacing: Spacing.sm,
        mainAxisSpacing: Spacing.sm,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final canAfford = coins >= item.price;
        return FadeIn(
          delayMs: index * 50,
          child: GlassPanel(
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(RadiusTokens.xl),
                    border: Border.all(color: item.color.withValues(alpha: 0.3)),
                  ),
                  child: Icon(item.icon, size: IconSizes.lg, color: item.color),
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: FontSizes.headlineMd,
                    fontWeight: FontWeights.semiBold,
                    color: AppColors.ink,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: const TextStyle(
                    fontSize: FontSizes.labelSm,
                    color: AppColors.inkMuted,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.monetization_on, size: IconSizes.xs, color: AppColors.tertiary),
                    const SizedBox(width: 2),
                    Text(
                      '${item.price}',
                      style: const TextStyle(
                        fontSize: FontSizes.labelSm,
                        fontWeight: FontWeights.bold,
                        color: AppColors.tertiary,
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    SizedBox(
                      height: 28,
                      child: FilledButton(
                        onPressed: canAfford
                            ? () => _buyItem(item)
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.tertiary,
                          foregroundColor: AppColors.onTertiary,
                          padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: const TextStyle(fontSize: FontSizes.labelSm),
                        ),
                        child: Text(canAfford ? 'BUY' : 'LOCKED'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _buyItem(_ShopItem item) {
    final notifier = ref.read(residentProvider.notifier);
    final success = notifier.addDecoration(item.name) && notifier.spendCoins(item.price);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} purchased!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}

class _ShopItem {
  final String name;
  final String description;
  final int price;
  final IconData icon;
  final Color color;

  const _ShopItem(this.name, this.description, this.price, this.icon, this.color);
}
