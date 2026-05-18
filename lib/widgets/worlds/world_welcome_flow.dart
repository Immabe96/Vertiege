import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/resident.dart';
import '../../models/world.dart';
import '../../services/world_service.dart';
import '../../state/resident_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/icons/v_icons.dart';
import '../../ui/buttons/v_button.dart';

class WorldWelcomeFlow extends ConsumerStatefulWidget {
  final World world;
  final VoidCallback onComplete;

  const WorldWelcomeFlow({
    super.key,
    required this.world,
    required this.onComplete,
  });

  @override
  ConsumerState<WorldWelcomeFlow> createState() => _WorldWelcomeFlowState();
}

class _WorldWelcomeFlowState extends ConsumerState<WorldWelcomeFlow> {
  int _step = 0;
  bool _rulesAcknowledged = false;
  bool _isLoading = false;

  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 2) {
      setState(() => _step++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  Future<void> _complete() async {
    setState(() => _isLoading = true);
    await WorldService.updateWorld(
      worldId: widget.world.id,
      welcomeMessage: widget.world.welcomeMessage,
    );
    if (mounted) {
      setState(() => _isLoading = false);
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final resident = ref.watch(residentProvider).resident;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        padding: const EdgeInsets.all(VSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? VColors.surfaceContainerDark : VColors.surface,
          borderRadius: BorderRadius.circular(VRadius.xl),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'Welcome to ${widget.world.name}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: VFontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(VIcons.x),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: VSpacing.sm),
            Row(
              children: List.generate(3, (i) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i <= _step ? VColors.primary : VColors.outline.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(VRadius.xxs),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: VSpacing.lg),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _WelcomeStep(world: widget.world, isDark: isDark),
                  _RulesStep(
                    world: widget.world,
                    acknowledged: _rulesAcknowledged,
                    onChanged: (v) => setState(() => _rulesAcknowledged = v),
                    isDark: isDark,
                  ),
                  _RoleStep(world: widget.world, resident: resident, isDark: isDark),
                ],
              ),
            ),
            const SizedBox(height: VSpacing.lg),
            VButton(
              label: _step < 2 ? 'Continue' : 'Enter World',
              onPressed: _next,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  final World world;
  final bool isDark;

  const _WelcomeStep({required this.world, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: VColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(VRadius.lg),
            ),
            child: Icon(
              world.dominionType != null
                  ? _dominionIcon(world.dominionType!)
                  : Icons.public,
              size: VIconSize.xl,
              color: VColors.primary,
            ),
          ),
          const SizedBox(height: VSpacing.lg),
          Text(
            world.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: VFontWeight.bold,
            ),
          ),
          if (world.motto.isNotEmpty) ...[
            const SizedBox(height: VSpacing.xs),
            Text(
              '"${world.motto}"',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: VSpacing.lg),
          Text(
            world.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
            ),
          ),
          if (world.lore.isNotEmpty) ...[
            const SizedBox(height: VSpacing.md),
            Container(
              padding: const EdgeInsets.all(VSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? VColors.surfaceDark : VColors.surfaceContainer,
                borderRadius: BorderRadius.circular(VRadius.md),
              ),
              child: Row(
                children: [
                  Icon(VIcons.sparkles, size: VIconSize.sm, color: VColors.warning),
                  const SizedBox(width: VSpacing.sm),
                  Expanded(
                    child: Text(
                      world.lore,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _dominionIcon(DominionType type) {
    switch (type) {
      case DominionType.marketplace:
        return Icons.storefront;
      case DominionType.academy:
        return Icons.school;
      case DominionType.sanctuary:
        return Icons.self_improvement;
      case DominionType.archive:
        return Icons.menu_book;
    }
  }
}

class _RulesStep extends StatelessWidget {
  final World world;
  final bool acknowledged;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const _RulesStep({
    required this.world,
    required this.acknowledged,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rules & Guidelines',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: VFontWeight.bold,
            ),
          ),
          const SizedBox(height: VSpacing.md),
          Container(
            padding: const EdgeInsets.all(VSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? VColors.surfaceDark : VColors.surfaceContainer,
              borderRadius: BorderRadius.circular(VRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RuleItem(icon: Icons.handshake, text: 'Treat all residents with respect'),
                _RuleItem(icon: Icons.no_adult_content, text: 'Keep content appropriate for all'),
                _RuleItem(icon: Icons.shield, text: 'Follow the sovereign\'s guidance'),
                _RuleItem(icon: Icons.report, text: 'Report violations to moderators'),
              ],
            ),
          ),
          const SizedBox(height: VSpacing.lg),
          CheckboxListTile(
            title: Text(
              'I have read and agree to follow the rules',
              style: theme.textTheme.bodyMedium,
            ),
            value: acknowledged,
            onChanged: (v) => onChanged(v ?? false),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _RuleItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _RuleItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: VIconSize.sm, color: VColors.primary),
          const SizedBox(width: VSpacing.sm),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _RoleStep extends StatelessWidget {
  final World world;
  final Resident? resident;
  final bool isDark;

  const _RoleStep({required this.world, required this.resident, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Get Started',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: VFontWeight.bold,
            ),
          ),
          const SizedBox(height: VSpacing.md),
          _ActionCard(
            icon: Icons.person_outline,
            title: 'Introduce Yourself',
            subtitle: 'Say hello in the general channel',
            onTap: () {},
          ),
          const SizedBox(height: VSpacing.sm),
          _ActionCard(
            icon: Icons.explore,
            title: 'Explore Channels',
            subtitle: 'Browse the available channels',
            onTap: () {},
          ),
          const SizedBox(height: VSpacing.sm),
          _ActionCard(
            icon: Icons.people_outline,
            title: 'Meet Residents',
            subtitle: 'Connect with other members',
            onTap: () {},
          ),
          if (world.dominionType == DominionType.sanctuary) ...[
            const SizedBox(height: VSpacing.sm),
            _ActionCard(
              icon: Icons.self_improvement,
              title: 'Check Your Tier',
              subtitle: 'See your current tier and perks',
              onTap: () {},
            ),
          ],
          if (world.dominionType == DominionType.marketplace) ...[
            const SizedBox(height: VSpacing.sm),
            _ActionCard(
              icon: Icons.storefront,
              title: 'Browse Marketplace',
              subtitle: 'See what\'s available for trade',
              onTap: () {},
            ),
          ],
          if (world.dominionType == DominionType.academy) ...[
            const SizedBox(height: VSpacing.sm),
            _ActionCard(
              icon: Icons.school,
              title: 'View Courses',
              subtitle: 'Enroll in available courses',
              onTap: () {},
            ),
          ],
          if (world.dominionType == DominionType.archive) ...[
            const SizedBox(height: VSpacing.sm),
            _ActionCard(
              icon: Icons.menu_book,
              title: 'Browse Documents',
              subtitle: 'Explore the knowledge base',
              onTap: () {},
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(VSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? VColors.surfaceDark : VColors.surfaceContainer,
          borderRadius: BorderRadius.circular(VRadius.md),
        ),
        child: Row(
          children: [
            Icon(icon, size: VIconSize.md, color: VColors.primary),
            const SizedBox(width: VSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: VFontWeight.semiBold),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: VFontSize.labelSm,
                      color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(VIcons.chevronRight),
          ],
        ),
      ),
    );
  }
}
