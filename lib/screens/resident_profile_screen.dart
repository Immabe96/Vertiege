import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/resident.dart';
import '../state/resident_provider.dart';
import '../state/achievement_provider.dart';
import 'package:go_router/go_router.dart';
import '../services/profile_service.dart';
import '../services/chat_service.dart';
import '../widgets/core/fade_in.dart';
import '../widgets/profile/cosmetic_avatar.dart';
import '../widgets/profile/name_banner.dart';
import '../widgets/profile/badge_display.dart';
import '../widgets/shared/tier_icon.dart';

class ResidentProfileScreen extends ConsumerStatefulWidget {
  final String residentId;

  const ResidentProfileScreen({super.key, required this.residentId});

  @override
  ConsumerState<ResidentProfileScreen> createState() => _ResidentProfileScreenState();
}

class _ResidentProfileScreenState extends ConsumerState<ResidentProfileScreen> {
  Resident? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final currentResident = ref.read(residentProvider).resident;
    if (currentResident?.id == widget.residentId) {
      setState(() { _profile = currentResident; _loading = false; });
      return;
    }
    try {
      final fetched = await ProfileService.getProfile(widget.residentId);
      setState(() { _profile = fetched; _loading = false; _error = fetched == null ? 'Resident not found' : null; });
    } catch (_) {
      setState(() { _loading = false; _error = 'Failed to load profile'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final achievements = ref.watch(achievementProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_profile?.name ?? 'Resident')),
      body: _buildBody(theme, achievements),
    );
  }

  Widget _buildBody(ThemeData theme, dynamic achievements) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null || _profile == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off, size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(_error ?? 'Resident not found', style: theme.textTheme.bodyLarge),
          ],
        ),
      );
    }
    final resident = _profile!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Hero(
            tag: 'avatar-${resident.id}',
            child: CosmeticAvatar(totalXp: achievements.totalXp, size: 80, imageUrl: resident.avatarUrl),
          ),
        ),
        const SizedBox(height: 12),
        FadeIn(
          delayMs: 60,
          child: Center(child: NameBanner(profession: resident.profession, name: resident.name)),
        ),
        const SizedBox(height: 8),
        FadeIn(
          delayMs: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TierIcon(tier: resident.tier.value),
              const SizedBox(width: 8),
              Text(resident.tier.label, style: theme.textTheme.titleMedium),
            ],
          ),
        ),
        const SizedBox(height: 4),
        FadeIn(
          delayMs: 100,
          child: Center(child: Text('${achievements.totalXp} XP', style: theme.textTheme.headlineSmall)),
        ),
        if (resident.bio.isNotEmpty) ...[
          const SizedBox(height: 12),
          FadeIn(
            delayMs: 120,
            child: Text(resident.bio, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
          ),
        ],
        const SizedBox(height: 12),
        FadeIn(
          delayMs: 140,
          child: Center(child: Text('Streak: ${resident.streakCount} days', style: theme.textTheme.bodyMedium)),
        ),
        if (resident.id != ref.watch(residentProvider).resident?.id) ...[
          const SizedBox(height: 16),
          FadeIn(
            delayMs: 160,
            child: Center(
              child: FilledButton.icon(
                onPressed: () async {
                  final currentId = ref.read(residentProvider).resident?.id;
                  if (currentId == null) return;
                  final room = await ChatService.getOrCreateRoom(currentId, resident.id);
                  if (room != null && context.mounted) {
                    context.push('/chat/${room['id']}');
                  }
                },
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Message'),
              ),
            ),
          ),
        ],
        if (resident.decorations.isNotEmpty) ...[
          const SizedBox(height: 16),
          FadeIn(delayMs: 180, child: BadgeDisplay(earnedBadgeIds: resident.decorations)),
        ],
      ],
    );
  }
}
