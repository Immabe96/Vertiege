import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/resident.dart';
import '../../models/world.dart';
import '../../state/resident_provider.dart';
import '../../state/achievement_provider.dart';
import '../../state/world_provider.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';
import '../../utils/world_assets.dart';
import '../../utils/world_foundations.dart';
import '../../widgets/core/glass_panel.dart';

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
        return AppColors.primary;
      case _GateInterest.capital:
        return AppColors.tertiary;
      case _GateInterest.craft:
        return const Color(0xFF7C6FFD);
      case _GateInterest.foundation:
        return AppColors.success;
      case _GateInterest.governance:
        return AppColors.hustler;
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
        duration: AnimDurations.normal,
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStage() {
    if (_stage > 0) {
      setState(() => _stage--);
      _pageController.animateToPage(
        _stage,
        duration: AnimDurations.normal,
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
              .submitAchievement(goalAchievementId, 'submitted');
        }
      }
    }

    // Mark The Gate as completed
    await markGateCompleted();

    if (mounted) {
      // Show welcome toast
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('The Realm welcomes you, $name'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.tertiary,
          duration: const Duration(seconds: 3),
        ),
      );

      // Navigate to Nexus (home feed)
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
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
                top: Spacing.md,
                left: 0,
                right: 0,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_totalStages - 1, (i) {
                      return AnimatedContainer(
                        duration: AnimDurations.fast,
                        width: i <= _stage - 1 ? 24 : 8,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i <= _stage - 1
                              ? AppColors.tertiary
                              : AppColors.glassBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ),
              ),

            // ── Back button ─────────────────────────────────
            if (_stage > 0 && !_completing)
              Positioned(
                top: Spacing.sm,
                left: Spacing.sm,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 20),
                  color: AppColors.inkMuted,
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
    return Container(
      padding: const EdgeInsets.all(Spacing.xl),
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
                      colors: [AppColors.tertiary, AppColors.tertiaryFixedDim],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.tertiary.withValues(
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
                    color: AppColors.onTertiary,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: Spacing.xxl),

          // ── Title ─────────────────────────────────────────
          Text(
            'Welcome to\nthe Realm',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: FontSizes.displayXl,
              fontWeight: FontWeights.bold,
              color: AppColors.ink,
              height: LineHeight.display,
            ),
          ),
          const SizedBox(height: Spacing.lg),

          // ── Subtitle ──────────────────────────────────────
          Text(
            'Your sovereign journey begins',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: FontSizes.bodyLg,
              color: AppColors.tertiary,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            'A guided rite of passage into\nthe tier-gated social universe.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: FontSizes.bodyMd,
              color: AppColors.inkMuted,
              height: LineHeight.body,
            ),
          ),

          const Spacer(flex: 2),

          // ── ENTER THE GATE button ─────────────────────────
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: _nextStage,
              icon: const Icon(Icons.keyboard_double_arrow_right),
              label: const Text('ENTER THE GATE'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.tertiary,
                foregroundColor: AppColors.onTertiary,
                textStyle: GoogleFonts.spaceGrotesk(
                  fontSize: FontSizes.bodyMd,
                  fontWeight: FontWeights.bold,
                  letterSpacing: LetterSpacing.label,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RadiusTokens.card),
                ),
              ),
            ),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.section,
        Spacing.lg,
        Spacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────────
          Text(
            'Choose your\nfirst signal',
            style: GoogleFonts.spaceGrotesk(
              fontSize: FontSizes.headlineLg,
              fontWeight: FontWeights.bold,
              color: AppColors.ink,
              height: LineHeight.headlineLg,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Pick 1-2 signals so Vertiege can route your first world with intent.',
            style: TextStyle(
              fontSize: FontSizes.bodyMd,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: Spacing.xl),

          // ── Bento grid of interest cards ──────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: Spacing.sm,
                runSpacing: Spacing.sm,
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

          const SizedBox(height: Spacing.lg),

          // ── CONTINUE button ───────────────────────────────
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: _selectedInterests.isEmpty ? null : _nextStage,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('CONTINUE'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.tertiary,
                foregroundColor: AppColors.onTertiary,
                disabledBackgroundColor: AppColors.surfaceOverlay,
                textStyle: GoogleFonts.spaceGrotesk(
                  fontSize: FontSizes.bodyMd,
                  fontWeight: FontWeights.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RadiusTokens.card),
                ),
              ),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Center(
            child: Text(
              '${_selectedInterests.length}/2 selected',
              style: TextStyle(
                fontSize: FontSizes.labelSm,
                color: AppColors.inkMuted,
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
        Spacing.lg,
        Spacing.section,
        Spacing.lg,
        Spacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────────
          Text(
            'Your first\nworld foundation',
            style: GoogleFonts.spaceGrotesk(
              fontSize: FontSizes.headlineLg,
              fontWeight: FontWeights.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'This is not a random recommendation. It is your first room, with a charter, roles, rules, and a live general channel.',
            style: TextStyle(
              fontSize: FontSizes.bodyMd,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: Spacing.xl),

          // ── World card preview ────────────────────────────
          GlassPanel(
            padding: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(RadiusTokens.cardFeatured),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(RadiusTokens.cardFeatured),
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
                  padding: const EdgeInsets.all(Spacing.lg),
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
                              borderRadius: BorderRadius.circular(
                                RadiusTokens.card,
                              ),
                            ),
                            child: Icon(
                              WorldAssets.iconForWorld(world.assetKey),
                              size: 24,
                              color: accent,
                            ),
                          ),
                          const SizedBox(width: Spacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  world.name,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: FontSizes.headlineMd,
                                    fontWeight: FontWeights.bold,
                                    color: AppColors.ink,
                                  ),
                                ),
                                Text(
                                  _accessLabel(world),
                                  style: TextStyle(
                                    fontSize: FontSizes.labelSm,
                                    color: accent,
                                    fontWeight: FontWeights.semiBold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.md),
                      Text(
                        foundation.premise,
                        style: TextStyle(
                          fontSize: FontSizes.bodyMd,
                          color: AppColors.inkSecondary,
                          height: LineHeight.body,
                        ),
                      ),
                      const SizedBox(height: Spacing.md),
                      Wrap(
                        spacing: Spacing.xs,
                        runSpacing: Spacing.xs,
                        children:
                            const ['#info', '#rules', '#roles', '#general']
                                .map(
                                  (channel) => _GatePill(
                                    label: channel,
                                    color: AppColors.tertiary,
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

          // ── JOIN WORLD button ──────────────────────────────
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: () {
                final resident = ref.read(residentProvider).resident;
                if (resident != null &&
                    world.id.isNotEmpty &&
                    !resident.joinedWorldIds.contains(world.id)) {
                  ref.read(residentProvider.notifier).joinWorld(world.id);
                }
                _nextStage();
              },
              icon: const Icon(Icons.login),
              label: const Text('ENTER THIS WORLD'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.tertiary,
                foregroundColor: AppColors.onTertiary,
                textStyle: GoogleFonts.spaceGrotesk(
                  fontSize: FontSizes.bodyMd,
                  fontWeight: FontWeights.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RadiusTokens.card),
                ),
              ),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          // CHOOSE ANOTHER button
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _nextStage,
              icon: const Icon(Icons.travel_explore),
              label: const Text('EXPLORE FIRST'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.inkSecondary,
                side: const BorderSide(color: AppColors.glassBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RadiusTokens.card),
                ),
              ),
            ),
          ),
          const SizedBox(height: Spacing.md),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Stage 4: Set Your First Rite
  // ═══════════════════════════════════════════════════════════════

  Widget _buildStage4() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.section,
        Spacing.lg,
        Spacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────────
          Text(
            'Choose your\nfirst rite',
            style: GoogleFonts.spaceGrotesk(
              fontSize: FontSizes.headlineLg,
              fontWeight: FontWeights.bold,
              color: AppColors.ink,
              height: LineHeight.headlineLg,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Pick the first orientation action you want waiting after The Gate.',
            style: TextStyle(
              fontSize: FontSizes.bodyMd,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: Spacing.xl),

          // ── Goal cards ────────────────────────────────────
          Expanded(
            child: ListView(
              children: _GateGoal.values.map((goal) {
                final isSelected = _selectedGoal == goal;
                return Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.md),
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

          const SizedBox(height: Spacing.lg),

          // ── BEGIN YOUR JOURNEY button ─────────────────────
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: _completing ? null : _complete,
              icon: _completing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onTertiary,
                      ),
                    )
                  : const Icon(Icons.flag),
              label: Text(_completing ? 'Entering Realm...' : 'OPEN THE REALM'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.tertiary,
                foregroundColor: AppColors.onTertiary,
                textStyle: GoogleFonts.spaceGrotesk(
                  fontSize: FontSizes.bodyMd,
                  fontWeight: FontWeights.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RadiusTokens.card),
                ),
              ),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Center(
            child: Text(
              _selectedGoal != null
                  ? 'Rite: ${_selectedGoal!.label} (+${_selectedGoal!.xp} XP)'
                  : 'Select a rite above',
              style: TextStyle(
                fontSize: FontSizes.labelSm,
                color: _selectedGoal != null
                    ? AppColors.tertiary
                    : AppColors.inkMuted,
              ),
            ),
          ),
          const SizedBox(height: Spacing.md),
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
    final professionWorlds = <String, String>{
      'Aviation': 'aviation-heights',
      'Medical': 'medical-nexus',
      'Finance': 'financial-district',
      'Legal': 'legal-plaza',
      'Technology': 'tech-sprawl',
      'Engineering': 'quantum-core',
      'Arts': 'arts-pavilion',
    };

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
    return worlds.firstWhere(
      (world) => world.slug == slug,
      orElse: () => worlds.firstWhere(
        (world) => world.slug == 'neon-district',
        orElse: () => const World(
          id: '',
          slug: 'neon-district',
          name: 'Neon District',
          type: WorldType.wealth,
          description: 'The entry point to the digital realm.',
          sovereignId: '',
          sovereignName: 'Vertiege',
          icon: 'neon',
          requiredTier: 1,
        ),
      ),
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
              color: AppColors.tertiary.withValues(alpha: opacity),
            ),
          ),
        ),
      );
    }

    return particles;
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
        horizontal: Spacing.sm,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(RadiusTokens.pill),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: FontSizes.caption,
          fontWeight: FontWeights.semiBold,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - Spacing.lg * 2 - Spacing.sm) / 2;
    final glow = interest.glowColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AnimDurations.fast,
        width: cardWidth,
        height: cardWidth * 0.85,
        decoration: BoxDecoration(
          color: isSelected
              ? glow.withValues(alpha: 0.12)
              : AppColors.glassBackground,
          borderRadius: BorderRadius.circular(RadiusTokens.cardFeatured),
          border: Border.all(
            color: isSelected
                ? glow.withValues(alpha: 0.5)
                : AppColors.glassBorder,
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
          padding: const EdgeInsets.all(Spacing.md),
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
                  borderRadius: BorderRadius.circular(RadiusTokens.card),
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
                  fontSize: FontSizes.bodyMd,
                  fontWeight: isSelected
                      ? FontWeights.bold
                      : FontWeights.semiBold,
                  color: isSelected ? glow : AppColors.inkSecondary,
                ),
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                interest.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: FontSizes.caption,
                  color: AppColors.inkMuted,
                  height: 1.2,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(height: Spacing.xs),
                Icon(Icons.check_circle, size: 16, color: glow),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AnimDurations.fast,
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.tertiary.withValues(alpha: 0.12)
              : AppColors.glassBackground,
          borderRadius: BorderRadius.circular(RadiusTokens.card),
          border: Border.all(
            color: isSelected
                ? AppColors.tertiary.withValues(alpha: 0.5)
                : AppColors.glassBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.tertiary.withValues(
                  alpha: isSelected ? 0.25 : 0.08,
                ),
                borderRadius: BorderRadius.circular(RadiusTokens.card),
              ),
              child: Icon(goal.icon, size: 22, color: AppColors.tertiary),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.label,
                    style: TextStyle(
                      fontSize: FontSizes.bodyMd,
                      fontWeight: isSelected
                          ? FontWeights.bold
                          : FontWeights.semiBold,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    '+${goal.xp} XP bonus',
                    style: TextStyle(
                      fontSize: FontSizes.labelSm,
                      color: AppColors.tertiary.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    goal.description,
                    style: TextStyle(
                      fontSize: FontSizes.caption,
                      color: AppColors.inkMuted,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, size: 22, color: AppColors.tertiary),
          ],
        ),
      ),
    );
  }
}
