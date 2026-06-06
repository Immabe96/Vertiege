import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/channel.dart';
import '../../models/resident.dart';
import '../../models/world.dart';
import '../../router/world_navigation.dart';
import '../../services/world_nav_prefs.dart';
import '../../state/channel_provider.dart';
import '../../state/resident_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/buttons/v_button.dart';
import '../../ui/icons/v_icons.dart';

/// Shows the world welcome modal on first join (DCX-084).
Future<void> showWorldWelcomeFlow(
  BuildContext context,
  WidgetRef ref, {
  required World world,
}) async {
  if (await WorldNavPrefs.hasSeenWelcome(world.id)) return;
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => WorldWelcomeFlow(
      world: world,
      onComplete: () async {
        await WorldNavPrefs.markWelcomeSeen(world.id);
        if (ctx.mounted) Navigator.of(ctx).pop();
      },
    ),
  );
}

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

  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    ref.read(channelProvider.notifier).loadChannels(widget.world.id);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _canContinue {
    if (_step == 1) return _rulesAcknowledged;
    return true;
  }

  void _next() {
    if (!_canContinue) return;
    if (_step < 2) {
      setState(() => _step++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final resident = ref.watch(residentProvider).resident;
    final channels =
        ref.watch(channelProvider).channelsByWorld[widget.world.id] ?? [];

    return Dialog(
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
                Expanded(
                  child: Text(
                    'Welcome to ${widget.world.name}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: VFontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(VIcons.x),
                  onPressed: widget.onComplete,
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
                      color: i <= _step
                          ? VColors.primary
                          : VColors.outline.withValues(alpha: 0.2),
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
                  _ChannelPicksStep(
                    world: widget.world,
                    resident: resident,
                    channels: channels,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: VSpacing.lg),
            VButton(
              label: _step < 2 ? 'Continue' : 'Enter world',
              onPressed: _canContinue ? _next : null,
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
                color: isDark
                    ? VColors.onSurfaceVariantDark
                    : VColors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: VSpacing.lg),
          Text(
            world.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? VColors.onSurfaceVariantDark
                  : VColors.onSurfaceVariant,
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
                  const Icon(
                    VIcons.sparkles,
                    size: VIconSize.sm,
                    color: VColors.warning,
                  ),
                  const SizedBox(width: VSpacing.sm),
                  Expanded(
                    child: Text(
                      world.lore,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? VColors.onSurfaceVariantDark
                            : VColors.onSurfaceVariant,
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
            'Rules & guidelines',
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
                const _RuleItem(
                  icon: Icons.handshake,
                  text: 'Treat all residents with respect',
                ),
                const _RuleItem(
                  icon: Icons.no_adult_content,
                  text: 'Keep content appropriate for all',
                ),
                const _RuleItem(
                  icon: Icons.shield,
                  text: 'Follow the sovereign\'s guidance',
                ),
                const _RuleItem(
                  icon: Icons.report,
                  text: 'Report violations to moderators',
                ),
                if (world.welcomeMessage.isNotEmpty) ...[
                  const Divider(height: VSpacing.lg),
                  Text(
                    world.welcomeMessage,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
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

class _ChannelPicksStep extends StatelessWidget {
  final World world;
  final Resident? resident;
  final List<WorldChannel> channels;
  final bool isDark;

  const _ChannelPicksStep({
    required this.world,
    required this.resident,
    required this.channels,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textChannels = channels
        .where((c) => c.channelType != ChannelType.voice)
        .take(6)
        .toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick channel picks',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: VFontWeight.bold,
            ),
          ),
          const SizedBox(height: VSpacing.xs),
          Text(
            'Jump into a channel to get started.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? VColors.onSurfaceVariantDark
                  : VColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: VSpacing.md),
          if (textChannels.isEmpty)
            Text(
              'Channels will appear here once the world is set up.',
              style: theme.textTheme.bodyMedium,
            )
          else
            ...textChannels.map(
              (ch) => Padding(
                padding: const EdgeInsets.only(bottom: VSpacing.sm),
                child: _ActionCard(
                  icon: Icons.tag,
                  title: '#${ch.name}',
                  subtitle: ch.description?.isNotEmpty == true
                      ? ch.description!
                      : 'Text channel',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push(
                      worldChannelDestinationPath(
                        world.id,
                        ch,
                        worldName: world.name,
                      ),
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: VSpacing.sm),
          _ActionCard(
            icon: Icons.people_outline,
            title: 'Meet residents',
            subtitle: 'Browse who\'s in this world',
            onTap: () {
              Navigator.of(context).pop();
              context.push('/worlds/${world.id}/members');
            },
          ),
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
                      color: isDark
                          ? VColors.onSurfaceVariantDark
                          : VColors.onSurfaceVariant,
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
