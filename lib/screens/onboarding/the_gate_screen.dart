import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/professions.dart';
import '../../router/world_navigation.dart';
import '../../models/resident.dart';
import '../../models/world.dart';
import '../../services/invite_navigation.dart';
import '../../state/resident_provider.dart';
import '../../state/achievement_provider.dart';
import '../../state/world_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/world_assets.dart';
import '../../ui/icons/v_icons.dart';
import '../../utils/world_foundations.dart';
import 'package:vertiege/ui/ui.dart';

/// Key used to track whether the resident has completed The Gate.
const gateCompletedKey = 'the_gate_completed';

/// Synchronously accessible cache of gate completion status.
/// Initialized at app startup and updated when The Gate is completed.
bool gateCompletedCache = false;

/// Loads the gate completion status from persistent storage on app startup.
Future<void> loadGateCompletionStatus() async {
  final prefs = await SharedPreferences.getInstance();
  gateCompletedCache = prefs.getBool(gateCompletedKey) ?? false;
}

/// Marks The Gate as complete — persists to storage, Supabase, and updates cache.
Future<void> markGateCompleted() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(gateCompletedKey, true);
  gateCompletedCache = true;
}

// ── Interest type ──────────────────────────────────────────────────

enum _GateInterest { execute, foundation, craft, capital, governance }

extension _GateInterestX on _GateInterest {
  String get label {
    switch (this) {
      case _GateInterest.execute:
        return 'Move fast';
      case _GateInterest.foundation:
        return 'Build habits';
      case _GateInterest.craft:
        return 'Master craft';
      case _GateInterest.capital:
        return 'Study capital';
      case _GateInterest.governance:
        return 'Lead worlds';
    }
  }

  IconData get icon {
    switch (this) {
      case _GateInterest.execute:
        return Icons.bolt;
      case _GateInterest.foundation:
        return Icons.spa;
      case _GateInterest.craft:
        return Icons.workspace_premium;
      case _GateInterest.capital:
        return Icons.diamond;
      case _GateInterest.governance:
        return Icons.shield;
    }
  }

  Color get glowColor {
    switch (this) {
      case _GateInterest.execute:
        return VColors.primary;
      case _GateInterest.capital:
        return VColors.tertiary;
      case _GateInterest.craft:
        return const Color(0xFF7C6FFD);
      case _GateInterest.foundation:
        return VColors.success;
      case _GateInterest.governance:
        return VColors.secondary;
    }
  }

  String get description {
    switch (this) {
      case _GateInterest.execute:
        return 'Hustle, tools, first wins';
      case _GateInterest.foundation:
        return 'Clarity, money habits, clean starts';
      case _GateInterest.craft:
        return 'Professional rooms and proof';
      case _GateInterest.capital:
        return 'Markets, leverage, reputation';
      case _GateInterest.governance:
        return 'Rules, roles, stewardship';
    }
  }
}

// ── Goal type ──────────────────────────────────────────────────────

enum _GateGoal { readCharter, learnStandard, firstSignal }

extension _GateGoalX on _GateGoal {
  String get label {
    switch (this) {
      case _GateGoal.readCharter:
        return 'Read the world charter';
      case _GateGoal.learnStandard:
        return 'Learn roles and rules';
      case _GateGoal.firstSignal:
        return 'Post your first signal';
    }
  }

  String get description {
    switch (this) {
      case _GateGoal.readCharter:
        return 'Start in #info before joining the room.';
      case _GateGoal.learnStandard:
        return 'Understand #rules and #roles before status matters.';
      case _GateGoal.firstSignal:
        return 'Enter #general with context, proof, or a useful ask.';
    }
  }

  int get xp {
    switch (this) {
      case _GateGoal.readCharter:
        return 10;
      case _GateGoal.learnStandard:
        return 20;
      case _GateGoal.firstSignal:
        return 30;
    }
  }

  IconData get icon {
    switch (this) {
      case _GateGoal.readCharter:
        return Icons.article_outlined;
      case _GateGoal.learnStandard:
        return Icons.verified_user_outlined;
      case _GateGoal.firstSignal:
        return Icons.forum_outlined;
    }
  }

  String get achievementId {
    switch (this) {
      case _GateGoal.readCharter:
        return 'pioneer-poster';
      case _GateGoal.learnStandard:
        return 'explorer';
      case _GateGoal.firstSignal:
        return 'wayfarer';
    }
  }
}

// ═════════════════════════════════════════════════════════════════════
// The Gate Screen
// ═════════════════════════════════════════════════════════════════════

class TheGateScreen extends ConsumerStatefulWidget {
  const TheGateScreen({super.key});

  @override
  ConsumerState<TheGateScreen> createState() => _TheGateScreenState();
}

class _TheGateScreenState extends ConsumerState<TheGateScreen>
    with SingleTickerProviderStateMixin {
  int _stage = 0;
  static const _totalStages = 4;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  final Set<_GateInterest> _selectedInterests = {};
  _GateGoal? _selectedGoal;
  bool _completing = false;
  String? _joinedStarterWorldId;

  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStage() {
    if (_stage < _totalStages - 1) {
      setState(() => _stage++);
      _pageController.animateToPage(
        _stage,
        duration: VAnimation.normal,
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStage() {
    if (_stage > 0) {
      setState(() => _stage--);
      _pageController.animateToPage(
        _stage,
        duration: VAnimation.normal,
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _complete() async {
    if (_completing) return;
    setState(() => _completing = true);

    final resident = ref.read(residentProvider).resident;
    final name = resident?.name ?? 'traveler';

    // Award the Gatekeeper badge
    if (resident != null) {
      final updatedDecorations = [...resident.decorations];
      if (!updatedDecorations.contains('gatekeeper')) {
        updatedDecorations.add('gatekeeper');
      }
      ref
          .read(residentProvider.notifier)
          .setResident(
            resident.copyWith(
              decorations: updatedDecorations,
              gateCompleted: true,
            ),
          );

      // Award 100 XP
      ref.read(achievementProvider.notifier).addDirectXp(100);

      // If a goal was selected, submit the corresponding achievement
      if (_selectedGoal != null) {
        final goalAchievementId = _selectedGoal!.achievementId;
        if (goalAchievementId.isNotEmpty) {
          ref
              .read(achievementProvider.notifier)
              .submitAchievement(goalAchievementId, const []);
        }
      }
    }

    // Mark The Gate as completed
    await markGateCompleted();

    if (mounted) {
      // Show welcome toast
      VFeedback.showMessage(
        context,
        'The Realm welcomes you, $name',
        duration: const Duration(seconds: 3),
      );

      final fallback = _joinedStarterWorldId == null
          ? '/'
          : exploreWorldPath(_joinedStarterWorldId!);
      final route = await routeAfterAuth(
        ref,
        fallback: fallback,
        feedbackContext: context,
      );
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? VColors.surfaceDark : VColors.surface,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Decorative shapes ────────────────────────────
            ..._buildParticles(),

            // ── Page content ─────────────────────────────────
            PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStage1(),
                _buildStage2(),
                _buildStage3(),
                _buildStage4(),
              ],
            ),

            // ── Progress indicator ───────────────────────────
            if (_stage > 0 && _stage < _totalStages - 1)
              Positioned(
                top: VSpacing.md,
                left: 0,
                right: 0,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_totalStages - 1, (i) {
                      return AnimatedContainer(
                        duration: VAnimation.fast,
                        width: i <= _stage - 1 ? 24 : 8,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i <= _stage - 1
                              ? VColors.tertiary
                              : (Theme.of(context).colorScheme.outlineVariant),
                          borderRadius: BorderRadius.circular(VRadius.sm),
                        ),
                      );
                    }),
                  ),
                ),
              ),

            // ── Back button ─────────────────────────────────
            if (_stage > 0 && !_completing)
              Positioned(
                top: VSpacing.sm,
                left: VSpacing.sm,
                child: IconButton(
                  icon: const Icon(VIcons.chevronRight, size: 20),
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  onPressed: _prevStage,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Stage 1: Welcome (Gate entrance)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildStage1() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(VSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // ── Animated Vertiege logo ────────────────────────
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnim.value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [VColors.tertiary, VColors.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: VColors.tertiary.withValues(
                          alpha: 0.45 * _pulseAnim.value,
                        ),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.public,
                    size: 56,
                    color: VColors.onTertiary,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: VSpacing.xxl),

          // ── Title ─────────────────────────────────────────
          Text(
            'Welcome to\nthe Realm',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: VFontSize.displayXl,
              fontWeight: VFontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
              height: VLineHeight.display,
            ),
          ),
          const SizedBox(height: VSpacing.lg),

          // ── Subtitle ──────────────────────────────────────
          Text(
            'Your sovereign journey begins',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: VFontSize.bodyLg,
              color: VColors.tertiary,
            ),
          ),
          const SizedBox(height: VSpacing.xs),
          Text(
            'A guided rite of passage into\nthe tier-gated social universe.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: VFontSize.bodyMd,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: VLineHeight.body,
            ),
          ),

          const Spacer(flex: 2),

          VGateCta(
            label: 'ENTER THE GATE',
            size: VGateCtaSize.tall,
            icon: const Icon(VIcons.chevronRight),
            onPressed: _nextStage,
          ),

          const Spacer(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Stage 2: Choose Your Signal
  // ═══════════════════════════════════════════════════════════════

  Widget _buildStage2() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.lg,
        VSpacing.xxl,
        VSpacing.lg,
        VSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────────
          Text(
            'Choose your\nfirst signal',
            style: TextStyle(
              fontSize: VFontSize.headlineLg,
              fontWeight: VFontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
              height: VLineHeight.headline,
            ),
          ),
          const SizedBox(height: VSpacing.sm),
          Text(
            'Pick 1-2 signals so Vertiege can route your first world with intent.',
            style: TextStyle(
              fontSize: VFontSize.bodyMd,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: VSpacing.xl),

          // ── Bento grid of interest cards ──────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: VSpacing.sm,
                runSpacing: VSpacing.sm,
                children: _GateInterest.values.map((interest) {
                  final isSelected = _selectedInterests.contains(interest);
                  return _InterestCard(
                    interest: interest,
                    isSelected: isSelected,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        if (isSelected) {
                          _selectedInterests.remove(interest);
                        } else {
                          if (_selectedInterests.length < 2) {
                            _selectedInterests.add(interest);
                          }
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: VSpacing.lg),

          VGateCta(
            label: 'CONTINUE',
            icon: const Icon(VIcons.arrowLeft),
            onPressed: _selectedInterests.isEmpty ? null : _nextStage,
          ),
          const SizedBox(height: VSpacing.sm),
          Center(
            child: Text(
              '${_selectedInterests.length}/2 selected',
              style: TextStyle(
                fontSize: VFontSize.labelSm,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Stage 3: Your First World
  // ═══════════════════════════════════════════════════════════════

  Widget _buildStage3() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Pick the first selected interest, or default to build
    final interest = _selectedInterests.isNotEmpty
        ? _selectedInterests.first
        : _GateInterest.execute;
    final world = _recommendedWorldFor(
      interest,
      ref.read(residentProvider).resident,
    );
    final foundation = foundationForWorld(world);
    final imagePath = WorldAssets.imageForWorld(world.assetKey);
    final accent = WorldAssets.accentForWorld(world.assetKey);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.lg,
        VSpacing.xxl,
        VSpacing.lg,
        VSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────────
          Text(
            'Your first\nworld foundation',
            style: TextStyle(
              fontSize: VFontSize.headlineLg,
              fontWeight: VFontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: VSpacing.sm),
          Text(
            'This is not a random recommendation. It is your first room, with a charter, roles, rules, and a live general channel.',
            style: TextStyle(
              fontSize: VFontSize.bodyMd,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: VSpacing.xl),

          // ── World card preview ────────────────────────────
          _Card(
            padding: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(VRadius.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(VRadius.md),
                  ),
                  child: SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: imagePath == null
                        ? ColoredBox(color: accent.withValues(alpha: 0.18))
                        : Image.asset(
                            imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => ColoredBox(
                              color: accent.withValues(alpha: 0.18),
                            ),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(VSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(VRadius.lg),
                            ),
                            child: Icon(
                              WorldAssets.iconForWorld(world.assetKey),
                              size: 24,
                              color: accent,
                            ),
                          ),
                          const SizedBox(width: VSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  world.name,
                                  style: TextStyle(
                                    fontSize: VFontSize.headlineMd,
                                    fontWeight: VFontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  _accessLabel(world),
                                  style: TextStyle(
                                    fontSize: VFontSize.labelSm,
                                    color: accent,
                                    fontWeight: VFontWeight.semiBold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: VSpacing.md),
                      Text(
                        foundation.premise,
                        style: TextStyle(
                          fontSize: VFontSize.bodyMd,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: VLineHeight.body,
                        ),
                      ),
                      const SizedBox(height: VSpacing.md),
                      Wrap(
                        spacing: VSpacing.xs,
                        runSpacing: VSpacing.xs,
                        children:
                            const ['#info', '#rules', '#roles', '#general']
                                .map(
                                  (channel) => _GatePill(
                                    label: channel,
                                    color: VColors.tertiary,
                                  ),
                                )
                                .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          VGateCta(
            label: world.id.isEmpty ? 'LOADING WORLD' : 'ENTER THIS WORLD',
            icon: const Icon(VIcons.logOut),
            onPressed: world.id.isEmpty
                ? null
                : () async {
                    final resident = ref.read(residentProvider).resident;
                    if (resident != null &&
                        world.id.isNotEmpty &&
                        !resident.joinedWorldIds.contains(world.id)) {
                      await ref
                          .read(residentProvider.notifier)
                          .joinWorld(world.id);
                      if (!mounted) return;
                      final joined = ref
                          .read(residentProvider)
                          .resident
                          ?.joinedWorldIds
                          .contains(world.id);
                      if (joined != true) {
                        VFeedback.showMessage(
                          context,
                          'World entry is still syncing. Try again.',
                        );
                        return;
                      }
                    }
                    _joinedStarterWorldId = world.id;
                    _nextStage();
                  },
          ),
          const SizedBox(height: VSpacing.sm),
          VGateCta(
            label: 'EXPLORE FIRST',
            variant: VGateCtaVariant.outlined,
            icon: const Icon(VIcons.globe),
            onPressed: _nextStage,
          ),
          const SizedBox(height: VSpacing.md),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Stage 4: Set Your First Rite
  // ═══════════════════════════════════════════════════════════════

  Widget _buildStage4() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.lg,
        VSpacing.xxl,
        VSpacing.lg,
        VSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────────
          Text(
            'Choose your\nfirst rite',
            style: TextStyle(
              fontSize: VFontSize.headlineLg,
              fontWeight: VFontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
              height: VLineHeight.headline,
            ),
          ),
          const SizedBox(height: VSpacing.sm),
          Text(
            'Pick the first orientation action you want waiting after The Gate.',
            style: TextStyle(
              fontSize: VFontSize.bodyMd,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: VSpacing.xl),

          // ── Goal cards ────────────────────────────────────
          Expanded(
            child: ListView(
              children: _GateGoal.values.map((goal) {
                final isSelected = _selectedGoal == goal;
                return Padding(
                  padding: const EdgeInsets.only(bottom: VSpacing.md),
                  child: _GoalCard(
                    goal: goal,
                    isSelected: isSelected,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _selectedGoal = isSelected ? null : goal;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: VSpacing.lg),

          VGateCta(
            label: _completing ? 'Entering Realm...' : 'OPEN THE REALM',
            size: VGateCtaSize.tall,
            icon: const Icon(VIcons.trophy),
            isLoading: _completing,
            onPressed: _completing ? null : _complete,
          ),
          const SizedBox(height: VSpacing.sm),
          Center(
            child: Text(
              _selectedGoal != null
                  ? 'Rite: ${_selectedGoal!.label} (+${_selectedGoal!.xp} XP)'
                  : 'Select a rite above',
              style: TextStyle(
                fontSize: VFontSize.labelSm,
                color: _selectedGoal != null
                    ? VColors.tertiary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: VSpacing.md),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Particle decorations
  // ═══════════════════════════════════════════════════════════════

  String _accessLabel(World world) {
    if (world.requiredProfession != null) {
      return '${world.requiredProfession} gate';
    }
    return 'Tier ${world.requiredTier ?? 1} open world';
  }

  World _recommendedWorldFor(_GateInterest interest, Resident? resident) {
    final professionWorlds = professionGateWorldSlug;

    String slug;
    switch (interest) {
      case _GateInterest.execute:
        slug = 'neon-district';
      case _GateInterest.foundation:
        slug = 'crystal-shore';
      case _GateInterest.craft:
        slug = professionWorlds[resident?.profession] ?? 'neon-district';
      case _GateInterest.capital:
        slug = resident != null && resident.tier.value >= 2
            ? 'azure-coast'
            : 'crystal-shore';
      case _GateInterest.governance:
        slug = resident != null && resident.tier.value >= 3
            ? 'sovereign-city'
            : 'neon-district';
    }

    final worlds = ref.read(worldProvider).worlds.values;
    final defaultWorlds = worlds.where((w) => w.isDefault).toList();
    final fallbackWorld = defaultWorlds.isNotEmpty
        ? defaultWorlds.first
        : const World(
            id: '',
            slug: 'neon-district',
            name: 'Neon District',
            type: WorldType.wealth,
            description: 'The entry point to the digital realm.',
            sovereignId: '',
            sovereignName: 'Vertiege',
            icon: 'neon',
            requiredTier: 1,
          );

    return worlds.firstWhere(
      (world) => world.slug == slug,
      orElse: () => fallbackWorld,
    );
  }

  List<Widget> _buildParticles() {
    final random = math.Random(42); // Fixed seed for consistent layout
    final particles = <Widget>[];

    for (int i = 0; i < 12; i++) {
      final x = random.nextDouble() * 0.9 + 0.05;
      final y = random.nextDouble() * 0.9 + 0.05;
      final size = random.nextDouble() * 4 + 2;
      final opacity = random.nextDouble() * 0.06 + 0.02;

      particles.add(
        Positioned(
          left: MediaQuery.of(context).size.width * x,
          top: MediaQuery.of(context).size.height * y,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: VColors.tertiary.withValues(alpha: opacity),
            ),
          ),
        ),
      );
    }

    return particles;
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
        color: isDark
            ? VColors.surfaceContainerDark
            : VColors.surfaceContainerLow,
        borderRadius: borderRadius ?? BorderRadius.circular(VRadius.lg),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: child,
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// Interest Card (Stage 2)
// ═════════════════════════════════════════════════════════════════════

class _GatePill extends StatelessWidget {
  final String label;
  final Color color;

  const _GatePill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.sm,
        vertical: VSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(VRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: VFontSize.labelMd,
          fontWeight: VFontWeight.semiBold,
        ),
      ),
    );
  }
}

class _InterestCard extends StatelessWidget {
  final _GateInterest interest;
  final bool isSelected;
  final VoidCallback onTap;

  const _InterestCard({
    required this.interest,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - VSpacing.lg * 2 - VSpacing.sm) / 2;
    final glow = interest.glowColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: VAnimation.fast,
        width: cardWidth,
        height: cardWidth * 0.85,
        decoration: BoxDecoration(
          color: isSelected
              ? glow.withValues(alpha: 0.12)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(VRadius.md),
          border: Border.all(
            color: isSelected
                ? glow.withValues(alpha: 0.5)
                : Theme.of(context).colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: glow.withValues(alpha: 0.15),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(VSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? glow.withValues(alpha: 0.25)
                      : glow.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(VRadius.lg),
                ),
                child: Icon(
                  interest.icon,
                  size: 22,
                  color: isSelected ? glow : glow.withValues(alpha: 0.6),
                ),
              ),
              const Spacer(),
              // Label
              Text(
                interest.label,
                style: TextStyle(
                  fontSize: VFontSize.bodyMd,
                  fontWeight: isSelected
                      ? VFontWeight.bold
                      : VFontWeight.semiBold,
                  color: isSelected
                      ? glow
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: VSpacing.xs),
              Text(
                interest.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: VFontSize.labelMd,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.2,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(height: VSpacing.xs),
                Icon(VIcons.badgeCheck, size: 16, color: glow),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// Goal Card (Stage 4)
// ═════════════════════════════════════════════════════════════════════

class _GoalCard extends StatelessWidget {
  final _GateGoal goal;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.goal,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: VAnimation.fast,
        padding: const EdgeInsets.all(VSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? VColors.tertiary.withValues(alpha: 0.12)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(VRadius.lg),
          border: Border.all(
            color: isSelected
                ? VColors.tertiary.withValues(alpha: 0.5)
                : Theme.of(context).colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: VColors.tertiary.withValues(
                  alpha: isSelected ? 0.25 : 0.08,
                ),
                borderRadius: BorderRadius.circular(VRadius.lg),
              ),
              child: Icon(goal.icon, size: 22, color: VColors.tertiary),
            ),
            const SizedBox(width: VSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.label,
                    style: TextStyle(
                      fontSize: VFontSize.bodyMd,
                      fontWeight: isSelected
                          ? VFontWeight.bold
                          : VFontWeight.semiBold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: VSpacing.xs),
                  Text(
                    '+${goal.xp} XP bonus',
                    style: TextStyle(
                      fontSize: VFontSize.labelSm,
                      color: VColors.tertiary.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: VSpacing.xs),
                  Text(
                    goal.description,
                    style: TextStyle(
                      fontSize: VFontSize.labelMd,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(VIcons.badgeCheck, size: 22, color: VColors.tertiary),
          ],
        ),
      ),
    );
  }
}
