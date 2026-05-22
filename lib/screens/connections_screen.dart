import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:forui/forui.dart';

import '../forui/v_hub_page.dart';
import '../models/ally.dart';
import '../models/resident.dart';
import '../state/ally_provider.dart';
import '../state/resident_provider.dart';
import '../state/world_provider.dart';
import '../services/world_service.dart';
import '../theme/v_colors.dart';
import '../theme/v_tokens.dart';
import '../widgets/core/fade_in.dart';
import '../widgets/profile/cosmetic_avatar.dart';
import '../ui/icons/v_icons.dart';

enum ConnectionsMode { following, allies }

/// Dedicated list for people you follow or allied residents (not generic search).
class ConnectionsScreen extends ConsumerStatefulWidget {
  final ConnectionsMode mode;

  const ConnectionsScreen({super.key, required this.mode});

  @override
  ConsumerState<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class FollowingScreen extends StatelessWidget {
  const FollowingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ConnectionsScreen(mode: ConnectionsMode.following);
  }
}

class AlliesScreen extends StatelessWidget {
  const AlliesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ConnectionsScreen(mode: ConnectionsMode.allies);
  }
}

class _ResidentRow {
  final Resident resident;
  final String? worldName;

  const _ResidentRow({required this.resident, this.worldName});
}

class _ConnectionsScreenState extends ConsumerState<ConnectionsScreen> {
  List<_ResidentRow> _rows = [];
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    final resident = ref.read(residentProvider).resident;
    if (resident == null) {
      setState(() {
        _loading = false;
        _loadError = 'Sign in to view your network.';
      });
      return;
    }

    if (widget.mode == ConnectionsMode.allies) {
      await ref.read(allyProvider.notifier).loadAll(resident.id);
      final allyErr = ref.read(allyProvider).loadError;
      if (allyErr != null) {
        setState(() {
          _loading = false;
          _loadError = allyErr;
        });
        return;
      }
    }

    try {
      final worldState = ref.read(worldProvider);
      final allMembers = <String, _ResidentRow>{};

      for (final world in worldState.worlds.values) {
        try {
          final members = await WorldService.getMembers(world.id);
          for (final m in members) {
            final id = m['resident_id'] as String?;
            final name = m['resident_name'] as String?;
            if (id == null || name == null || allMembers.containsKey(id)) {
              continue;
            }
            allMembers[id] = _ResidentRow(
              resident: Resident(
                id: id,
                name: name,
                tier: ResidentTier.fromValue(m['standing'] as int? ?? 1),
                profession: m['profession'] as String?,
                avatarUrl: m['avatar_url'] as String? ?? '',
              ),
              worldName: world.name,
            );
          }
        } catch (_) {}
      }

      List<_ResidentRow> rows;
      if (widget.mode == ConnectionsMode.following) {
        final followingIds = resident.following.toSet();
        rows = allMembers.values
            .where((e) => followingIds.contains(e.resident.id))
            .toList()
          ..sort((a, b) => a.resident.name.compareTo(b.resident.name));
      } else {
        final allies = ref.read(allyProvider).allies;
        final allyIds = <String>{};
        for (final a in allies) {
          allyIds.add(
            a.requesterId == resident.id ? a.receiverId : a.requesterId,
          );
        }
        rows = allMembers.values
            .where((e) => allyIds.contains(e.resident.id))
            .toList()
          ..sort((a, b) => a.resident.name.compareTo(b.resident.name));
      }

      if (mounted) {
        setState(() {
          _rows = rows;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = 'Could not load residents. Pull to refresh.';
        });
      }
    }
  }

  String get _title =>
      widget.mode == ConnectionsMode.following ? 'Following' : 'Allies';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final resident = ref.watch(residentProvider).resident;
    final allyState = ref.watch(allyProvider);

    return VHubPage(
      title: _title,
      showBack: true,
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(VSpacing.md),
                children: [
                  if (_loadError != null) ...[
                    Material(
                      color: isDark
                          ? VColors.errorContainerDark
                          : VColors.errorContainer,
                      borderRadius: BorderRadius.circular(VRadius.lg),
                      child: Padding(
                        padding: const EdgeInsets.all(VSpacing.md),
                        child: Text(
                          _loadError!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? VColors.onErrorContainerDark
                                : VColors.onErrorContainer,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: VSpacing.md),
                  ],
                  if (widget.mode == ConnectionsMode.allies &&
                      allyState.pendingRequests.isNotEmpty) ...[
                    Text(
                      'PENDING REQUESTS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: VFontWeight.bold,
                        letterSpacing: 0.5,
                        color: VColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: VSpacing.sm),
                    ...allyState.pendingRequests.map(
                      (a) => _PendingAllyTile(ally: a, residentId: resident?.id),
                    ),
                    const SizedBox(height: VSpacing.lg),
                  ],
                  if (_rows.isEmpty && _loadError == null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Column(
                          children: [
                            Icon(
                              widget.mode == ConnectionsMode.following
                                  ? Icons.people_outline
                                  : Icons.handshake_outlined,
                              size: 48,
                              color: VColors.outline,
                            ),
                            const SizedBox(height: VSpacing.md),
                            Text(
                              widget.mode == ConnectionsMode.following
                                  ? 'Not following anyone yet'
                                  : 'No allies yet',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: VSpacing.sm),
                            Text(
                              widget.mode == ConnectionsMode.following
                                  ? 'Find residents from world feeds or search.'
                                  : 'Send allegiance requests from resident profiles.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: VColors.onSurfaceVariant,
                              ),
                            ),
                            if (widget.mode == ConnectionsMode.allies) ...[
                              const SizedBox(height: VSpacing.lg),
                              FButton(
                                onPress: () => context.push('/search'),
                                child: const Text('Find residents'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  else
                    ..._rows.map((row) => _PersonTile(row: row)),
                ],
              ),
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  final _ResidentRow row;

  const _PersonTile({required this.row});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final resident = row.resident;

    return FadeIn(
      delayMs: 30,
      child: Padding(
        padding: const EdgeInsets.only(bottom: VSpacing.sm),
        child: Material(
          color: isDark
              ? VColors.surfaceContainerDark
              : VColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(VRadius.lg),
          child: InkWell(
            onTap: () => context.push('/residents/${resident.id}'),
            borderRadius: BorderRadius.circular(VRadius.lg),
            child: ListTile(
              leading: CosmeticAvatar(
                imageUrl: resident.avatarUrl,
                seed: resident.id,
                size: 40,
              ),
              title: Text(
                resident.name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: VFontWeight.bold,
                ),
              ),
              subtitle: Text(
                [
                  if (resident.profession != null) resident.profession!,
                  if (row.worldName != null) row.worldName!,
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(VIcons.chevronRight),
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingAllyTile extends ConsumerWidget {
  final Ally ally;
  final String? residentId;

  const _PendingAllyTile({required this.ally, required this.residentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isIncoming = ally.receiverId == residentId;

    return Card(
      margin: const EdgeInsets.only(bottom: VSpacing.sm),
      child: ListTile(
        title: Text(
          isIncoming ? 'Incoming allegiance request' : 'Outgoing request',
          style: theme.textTheme.bodyMedium,
        ),
        trailing: isIncoming
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: VColors.primary),
                    onPressed: () => ref
                        .read(allyProvider.notifier)
                        .acceptRequest(ally.id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: VColors.error),
                    onPressed: () => ref
                        .read(allyProvider.notifier)
                        .declineRequest(ally.id),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
