import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../router/world_navigation.dart';
import '../services/chat_service.dart';
import 'package:vertiege/ui/ui.dart';
import '../models/ally.dart';
import '../models/resident.dart';
import '../state/ally_provider.dart';
import '../state/resident_provider.dart';
import '../state/world_provider.dart';
import '../services/world_service.dart';
import '../theme/v_colors.dart';
import '../theme/v_tokens.dart';
import '../widgets/core/empty_state.dart';
import '../widgets/core/fade_in.dart';
import '../widgets/core/screen_loading.dart';
import '../widgets/profile/cosmetic_avatar.dart';

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
  late ConnectionsMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = widget.mode;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _setMode(ConnectionsMode mode) async {
    if (mode == _mode) return;
    setState(() => _mode = mode);
    await _load();
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

    if (_mode == ConnectionsMode.allies) {
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
      if (_mode == ConnectionsMode.following) {
        final followingIds = resident.following.toSet();
        rows =
            allMembers.values
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
        rows =
            allMembers.values
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resident = ref.watch(residentProvider).resident;
    final allyState = ref.watch(allyProvider);

    return VHubPage(
      title: 'Connections',
      showBack: true,
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: const [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: ScreenLoading.list(),
                  ),
                ],
              )
            : _loadError != null && _rows.isEmpty
            ? CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(VSpacing.md),
                    sliver: SliverToBoxAdapter(
                      child: AppErrorState(message: _loadError, onRetry: _load),
                    ),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(VSpacing.md),
                child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: SegmentedButton<ConnectionsMode>(
                      segments: const [
                        ButtonSegment(
                          value: ConnectionsMode.allies,
                          label: Text('Allies'),
                          icon: Icon(Icons.handshake_outlined, size: 18),
                        ),
                        ButtonSegment(
                          value: ConnectionsMode.following,
                          label: Text('Following'),
                          icon: Icon(Icons.people_outline, size: 18),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (next) {
                        if (next.isEmpty) return;
                        unawaited(_setMode(next.first));
                      },
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: VSpacing.md),
                  ),
                  SliverToBoxAdapter(
                    child: Text(
                      _mode == ConnectionsMode.following
                          ? 'One-way follows boost Nexus feed priority. Not the same as allies.'
                          : 'Mutual allegiance — both residents accepted. Stronger than a follow.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: VSpacing.lg),
                  ),
                  if (_mode == ConnectionsMode.allies &&
                      allyState.pendingRequests.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Text(
                        'PENDING REQUESTS',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: VFontWeight.bold,
                          letterSpacing: 0.5,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: VSpacing.sm),
                    ),
                    SliverList.builder(
                      itemCount: allyState.pendingRequests.length,
                      itemBuilder: (context, index) => _PendingAllyTile(
                        ally: allyState.pendingRequests[index],
                        residentId: resident?.id,
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: VSpacing.lg),
                    ),
                  ],
                  if (_rows.isEmpty && _loadError == null)
                    SliverToBoxAdapter(
                      child: AppEmptyState(
                        icon: _mode == ConnectionsMode.following
                            ? Icons.people_outline
                            : Icons.handshake_outlined,
                        title: _mode == ConnectionsMode.following
                            ? 'Not following anyone yet'
                            : 'No allies yet',
                        description: _mode == ConnectionsMode.following
                            ? 'Follow from profiles to prioritize their Nexus moments.'
                            : 'Send allegiance requests from resident profiles — both must accept.',
                        actionLabel: 'Find residents',
                        onAction: () => context.push('/search'),
                      ),
                    )
                  else
                    SliverList.builder(
                      itemCount: _rows.length,
                      itemBuilder: (context, index) => _PersonTile(
                        row: _rows[index],
                        showMessageAction: _mode == ConnectionsMode.allies,
                      ),
                    ),
                ],
              ),
            ),
      ),
    );
  }
}

class _PersonTile extends ConsumerWidget {
  final _ResidentRow row;
  final bool showMessageAction;

  const _PersonTile({
    required this.row,
    this.showMessageAction = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            onTap: () => context.push(residentProfilePath(resident.id)),
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
              trailing: showMessageAction
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(VIcons.message),
                          tooltip: 'Message',
                          onPressed: () async {
                            final currentId =
                                ref.read(residentProvider).resident?.id;
                            if (currentId == null) return;
                            final room = await ChatService.getOrCreateRoom(
                              currentId,
                              row.resident.id,
                            );
                            if (room == null) {
                              if (context.mounted) {
                                VFeedback.showMessage(
                                  context,
                                  'Could not open chat.',
                                );
                              }
                              return;
                            }
                            if (!context.mounted) return;
                            context.push(
                              chatRoomPath(room['id'] as String),
                            );
                          },
                        ),
                        const Icon(VIcons.chevronRight),
                      ],
                    )
                  : const Icon(VIcons.chevronRight),
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
                    icon: Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
                    onPressed: () =>
                        ref.read(allyProvider.notifier).acceptRequest(ally.id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: VColors.error),
                    onPressed: () =>
                        ref.read(allyProvider.notifier).declineRequest(ally.id),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
