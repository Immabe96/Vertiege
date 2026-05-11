import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/chat_provider.dart';
import '../../state/resident_provider.dart';
import '../../theme/design_system.dart';
import '../../theme/colors.dart';
import '../../utils/time_ago.dart';
import '../../widgets/core/fade_in.dart';
import '../../widgets/core/glass_panel.dart';
import '../../widgets/core/status_dot.dart';
import '../../widgets/profile/cosmetic_avatar.dart';
import '../../widgets/core/screen_loading.dart';
import '../../widgets/core/empty_state.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  bool _didTriggerLoad = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final residentId =
        ref.watch(residentProvider.select((s) => s.resident?.id));
    final chatState = ref.watch(chatProvider);

    // Trigger initial load once per screen lifetime
    if (residentId != null && !_didTriggerLoad) {
      _didTriggerLoad = true;
      Future.microtask(() {
        final id = ref.read(residentProvider).resident?.id;
        if (id != null) {
          ref.read(chatProvider.notifier).loadDmRooms(id);
        }
      });
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AppBar(
              toolbarHeight: 56,
              elevation: 0,
              backgroundColor: AppColors.surface.withAlpha(204),
              title: const Text('Chats'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_square, color: AppColors.inkSecondary),
                  tooltip: 'New Chat',
                  onPressed: () => context.push('/search'),
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final id = ref.read(residentProvider.select((s) => s.resident?.id));
          if (id != null) {
            await ref.read(chatProvider.notifier).loadDmRooms(id);
          }
        },
        child: _buildBody(context, theme, residentId, chatState),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    String? residentId,
    ChatState chatState,
  ) {
    if (residentId == null) {
      return Center(
        child: Text('Sign in to view chats', style: theme.textTheme.bodyLarge),
      );
    }

    if (chatState.isLoadingRooms) {
      return const ScreenLoading.list();
    }

    if (chatState.dmRooms.isEmpty) {
      return _buildEmptyState(theme);
    }

    return _buildRoomList(theme, chatState.dmRooms, residentId);
  }

  Widget _buildEmptyState(ThemeData theme) {
    return AppEmptyState(
      title: 'No messages yet',
      description: 'Join a world and start connecting with the community',
      icon: Icons.chat_bubble_outline,
      variant: EmptyStateVariant.default_,
      actionLabel: 'Explore Worlds',
      onAction: () => context.go('/explore'),
    );
  }

  Widget _buildRoomList(
    ThemeData theme,
    List<Map<String, dynamic>> rooms,
    String currentUserId,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: Spacing.sm),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        final otherName = _otherName(room, currentUserId);
        final otherAvatar = _otherAvatar(room);
        final lastMessage = room['last_message'] as String? ?? '';
        final lastMessageAt = room['last_message_at'] as String?;
        final unreadCount = room['unread_count'] as int? ?? 0;

        return FadeIn(
          delayMs: index * 40,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xs),
            child: GlassPanel(
              padding: const EdgeInsets.all(Spacing.md),
              borderRadius: BorderRadius.circular(RadiusTokens.xl),
              child: InkWell(
                onTap: () => context.push('/chat/${room['id']}'),
                borderRadius: BorderRadius.circular(RadiusTokens.xl),
                child: Row(
                  children: [
                    CosmeticAvatar(imageUrl: otherAvatar, size: 48),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  otherName.isNotEmpty ? otherName : 'Unknown',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeights.bold,
                                    color: AppColors.ink,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (lastMessageAt != null)
                                Text(
                                  _timeLabel(lastMessageAt),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  lastMessage.isNotEmpty ? lastMessage : 'No messages yet',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: unreadCount > 0
                                        ? AppColors.ink
                                        : AppColors.inkMuted,
                                    fontWeight: unreadCount > 0
                                        ? FontWeights.semiBold
                                        : FontWeights.regular,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (unreadCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.tertiary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$unreadCount',
                                    style: const TextStyle(
                                      color: AppColors.onTertiary,
                                      fontSize: 11,
                                      fontWeight: FontWeights.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    StatusDot(
                      presence: _presence(room),
                      size: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _otherName(Map<String, dynamic> room, String currentId) {
    final ids = (room['resident_ids'] as List?)?.cast<String>() ?? [];
    final otherId = ids.firstWhere(
      (id) => id != currentId,
      orElse: () => ids.isNotEmpty ? ids.first : '',
    );
    if (otherId.isEmpty) return '';
    final names = room['names'] as Map<String, dynamic>?;
    if (names != null && names[otherId] is String) return names[otherId] as String;
    final direct = room['other_name'];
    if (direct is String && direct.isNotEmpty) return direct;
    return otherId;
  }

  String? _otherAvatar(Map<String, dynamic> room) {
    final avatar = room['other_avatar'];
    if (avatar is String && avatar.isNotEmpty) return avatar;
    return null;
  }

  Presence _presence(Map<String, dynamic> room) {
    final lastAt = room['last_message_at'] as String?;
    if (lastAt == null) return Presence.offline;
    final last = DateTime.tryParse(lastAt);
    if (last == null) return Presence.offline;
    return DateTime.now().difference(last).inMinutes < 5
        ? Presence.online
        : Presence.offline;
  }

  String _timeLabel(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return timeAgo(dt);
  }
}
