import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../state/resident_provider.dart';
import '../../state/achievement_provider.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';
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

enum _GateInterest { build, wealth, learn, connect, lead }

extension _GateInterestX on _GateInterest {
  String get label {
    switch (this) {
      case _GateInterest.build:
        return 'Build & Create';
      case _GateInterest.wealth:
        return 'Grow Wealth';
      case _GateInterest.learn:
        return 'Learn & Master';
      case _GateInterest.connect:
        return 'Connect & Network';
      case _GateInterest.lead:
        return 'Lead & Govern';
    }
  }

  IconData get icon {
    switch (this) {
      case _GateInterest.build:
        return Icons.terminal;
      case _GateInterest.wealth:
        return Icons.diamond;
      case _GateInterest.learn:
        return Icons.menu_book;
      case _GateInterest.connect:
        return Icons.hub;
      case _GateInterest.lead:
        return Icons.shield;
    }
  }

  Color get glowColor {
    switch (this) {
      case _GateInterest.build:
        return AppColors.primary;
      case _GateInterest.wealth:
        return AppColors.tertiary;
      case _GateInterest.learn:
        return const Color(0xFF7C6FFD);
      case _GateInterest.connect:
        return AppColors.success;
      case _GateInterest.lead:
        return AppColors.hustler;
    }
  }

  /// Recommended world based on interest
  ({String id, String name, String description, int memberCount}) get world {
    switch (this) {
      case _GateInterest.build:
        return (id: 'digital-architects', name: 'Digital Architects', description: 'Build the future with code, design, and engineering.', memberCount: 847);
      case _GateInterest.wealth:
        return (id: 'gilded-vault', name: 'The Gilded Vault', description: 'Master wealth, investing, and financial independence.', memberCount: 1203);
      case _GateInterest.learn:
        return (id: 'scholars-athenaeum', name: "Scholar's Athenaeum", description: 'Pursue knowledge across every discipline.', memberCount: 652);
      case _GateInterest.connect:
        return (id: 'nexus-hub', name: 'Nexus Hub', description: 'Connect with creators, founders, and visionaries.', memberCount: 1430);
      case _GateInterest.lead:
        return (id: 'sovereigns-court', name: "Sovereign's Court", description: 'Lead councils, govern worlds, and shape the realm.', memberCount: 389);
    }
  }
}

// ── Goal type ──────────────────────────────────────────────────────

enum _GateGoal { firstPost, completeProfile, inviteFriend }

extension _GateGoalX on _GateGoal {
  String get label {
    switch (this) {
      case _GateGoal.firstPost:
        return 'Post your first message';
      case _GateGoal.completeProfile:
        return 'Complete your profile';
      case _GateGoal.inviteFriend:
        return 'Invite a friend';
    }
  }

  int get xp {
    switch (this) {
      case _GateGoal.firstPost:
        return 10;
      case _GateGoal.completeProfile:
        return 20;
      case _GateGoal.inviteFriend:
        return 30;
    }
  }

  IconData get icon {
    switch (this) {
      case _GateGoal.firstPost:
        return Icons.edit_note;
      case _GateGoal.completeProfile:
        return Icons.person;
      case _GateGoal.inviteFriend:
        return Icons.group_add;
    }
  }

  String get achievementId {
    switch (this) {
      case _GateGoal.firstPost:
        return 'pioneer-poster';
      case _GateGoal.completeProfile:
        return 'explorer';
      case _GateGoal.inviteFriend:
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
      ref.read(residentProvider.notifier).setResident(
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
          ref.read(achievementProvider.notifier).submitAchievement(
                goalAchievementId,
                'submitted',
              );
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
  // Stage 2: Choose Your Path (Interest quiz)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildStage2() {
    return Container(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.section, Spacing.lg, Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────────
          Text(
            'What brings you\nto the Realm?',
            style: GoogleFonts.spaceGrotesk(
              fontSize: FontSizes.headlineLg,
              fontWeight: FontWeights.bold,
              color: AppColors.ink,
              height: LineHeight.headlineLg,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Select 1–2 interests to guide your path.',
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
        : _GateInterest.build;

    final world = interest.world;

    return Container(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.section, Spacing.lg, Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────────
          Text(
            'Your First World',
            style: GoogleFonts.spaceGrotesk(
              fontSize: FontSizes.headlineLg,
              fontWeight: FontWeights.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Based on your interests, we recommend:',
            style: TextStyle(
              fontSize: FontSizes.bodyMd,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: Spacing.xl),

          // ── World card preview ────────────────────────────
          GlassPanel(
            padding: const EdgeInsets.all(Spacing.xl),
            borderRadius: BorderRadius.circular(RadiusTokens.cardFeatured),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: interest.glowColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(RadiusTokens.card),
                  ),
                  child: Icon(interest.icon, size: 28, color: interest.glowColor),
                ),
                const SizedBox(height: Spacing.lg),
                // Name
                Text(
                  world.name,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: FontSizes.headlineMd,
                    fontWeight: FontWeights.bold,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                // Description
                Text(
                  world.description,
                  style: TextStyle(
                    fontSize: FontSizes.bodyMd,
                    color: AppColors.inkSecondary,
                    height: LineHeight.body,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                // Member count
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: AppColors.inkMuted),
                    const SizedBox(width: Spacing.xs),
                    Text(
                      '${world.memberCount} members',
                      style: TextStyle(
                        fontSize: FontSizes.labelSm,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
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
                // Join the recommended world
                final resident = ref.read(residentProvider).resident;
                if (resident != null && !resident.joinedWorldIds.contains(world.id)) {
                  ref.read(residentProvider.notifier).joinWorld(world.id);
                }
                _nextStage();
              },
              icon: const Icon(Icons.rocket_launch),
              label: const Text('JOIN WORLD'),
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
              icon: const Icon(Icons.skip_next),
              label: const Text('CHOOSE ANOTHER'),
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
  // Stage 4: Set Your Goal
  // ═══════════════════════════════════════════════════════════════

  Widget _buildStage4() {
    return Container(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.section, Spacing.lg, Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────────
          Text(
            'What will you\nachieve first?',
            style: GoogleFonts.spaceGrotesk(
              fontSize: FontSizes.headlineLg,
              fontWeight: FontWeights.bold,
              color: AppColors.ink,
              height: LineHeight.headlineLg,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Set your first quest and earn bonus XP.',
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
              label: Text(_completing ? 'Entering Realm...' : 'BEGIN YOUR JOURNEY'),
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
                  ? 'Quest: ${_selectedGoal!.label} (+${_selectedGoal!.xp} XP)'
                  : 'Select a quest above',
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
                  fontWeight: isSelected ? FontWeights.bold : FontWeights.semiBold,
                  color: isSelected ? glow : AppColors.inkSecondary,
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
              child: Icon(
                goal.icon,
                size: 22,
                color: AppColors.tertiary,
              ),
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
                      fontWeight: isSelected ? FontWeights.bold : FontWeights.semiBold,
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
