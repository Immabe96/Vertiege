import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/chat_provider.dart';
import '../../state/resident_provider.dart';
import '../../theme/design_system.dart';
import '../../utils/time_ago.dart';
import '../../widgets/core/fade_in.dart';
import '../../widgets/core/status_dot.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final residentId =
        ref.watch(residentProvider.select((s) => s.resident?.id));
    final chatState = ref.watch(chatProvider);

    // Trigger initial load once when resident is available and rooms
    // have not been fetched yet.
    if (residentId != null &&
        chatState.dmRooms.isEmpty &&
        !chatState.isLoadingRooms) {
      Future.microtask(() {
        final id = ref.read(residentProvider).resident?.id;
        if (id != null) {
          ref.read(chatProvider.notifier).loadDmRooms(id);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: _buildBody(context, theme, residentId, chatState),
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
      return _buildLoadingState(theme);
    }

    if (chatState.dmRooms.isEmpty) {
      return _buildEmptyState(theme);
    }

    return _buildRoomList(theme, chatState.dmRooms, residentId);
  }

  Widget _buildLoadingState(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      itemCount: 8,
      itemBuilder: (context, index) => Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 6),
        child: Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
            title: FractionallySizedBox(
              widthFactor: 0.4 + (index % 4) * 0.1,
              child: Container(
                height: 14,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: theme.colorScheme.outlineVariant,
          ),
          const SizedBox(height: 20),
          Text(
            'No conversations yet',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: Spacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'When you connect with other residents, your conversations will appear here. Start by joining a world and saying hello!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomList(
    ThemeData theme,
    List<Map<String, dynamic>> rooms,
    String residentId,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: Spacing.sm),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        final roomId = room['id'] as String? ?? '';

        return _RoomTile(
          key: ValueKey(roomId),
          room: room,
          currentResidentId: residentId,
          onTap: () => context.go('/chat/$roomId'),
          index: index,
        );
      },
    );
  }
}

class _RoomTile extends StatelessWidget {
  final Map<String, dynamic> room;
  final String currentResidentId;
  final VoidCallback onTap;
  final int index;

  const _RoomTile({
    super.key,
    required this.room,
    required this.currentResidentId,
    required this.onTap,
    this.index = 0,
  });

  /// Returns the display name for the other participant in this DM room.
  String _otherResidentName() {
    final ids = (room['resident_ids'] as List?)?.cast<String>() ?? [];
    final otherId = ids.firstWhere(
      (id) => id != currentResidentId,
      orElse: () => ids.isNotEmpty ? ids.first : '',
    );
    if (otherId.isEmpty) return 'Unknown';

    final names = room['names'] as Map<String, dynamic>?;
    if (names != null && names[otherId] is String) {
      return names[otherId] as String;
    }

    final direct = room['other_name'];
    if (direct is String && direct.isNotEmpty) return direct;

    return otherId;
  }

  /// Returns the other resident's avatar URL, if available.
  String? _otherResidentAvatar() {
    final avatar = room['other_avatar'];
    if (avatar is String && avatar.isNotEmpty) return avatar;
    return null;
  }

  String _lastMessagePreview() {
    final msg = room['last_message'];
    if (msg == null || msg.toString().isEmpty) return 'No messages yet';
    final text = msg.toString();
    if (text.length > 50) return '${text.substring(0, 50)}...';
    return text;
  }

  /// Returns a compact relative time label like "2m", "1h", "3d".
  String _relativeTime() {
    final lastMessageAt = room['last_message_at'];
    if (lastMessageAt == null) return '';
    try {
      final dt = DateTime.parse(lastMessageAt.toString());
      // timeAgo returns "5m ago" etc — strip " ago" for compact display
      final label = timeAgo(dt);
      if (label == 'just now') return 'now';
      return label.replaceAll(' ago', '');
    } catch (_) {
      return '';
    }
  }

  /// Unread count badge value, if any.
  int _unreadCount() {
    final count = room['unread_count'];
    if (count is int) return count;
    if (count is String) return int.tryParse(count) ?? 0;
    return 0;
  }

  /// Derives presence from the room's last_message_at timestamp.
  /// If the last message was within the last 5 minutes, show online.
  Presence _presence() {
    final lastMessageAt = room['last_message_at'];
    if (lastMessageAt == null) return Presence.offline;
    try {
      final dt = DateTime.parse(lastMessageAt.toString());
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 5) return Presence.online;
      return Presence.offline;
    } catch (_) {
      return Presence.offline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = _otherResidentName();
    final avatar = _otherResidentAvatar();
    final unread = _unreadCount();
    final hasUnread = unread > 0;

    return FadeIn(
      delayMs: index * 50,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 4),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage:
                  avatar != null ? NetworkImage(avatar) : null,
              child: avatar == null
                  ? Text(
                      name.isNotEmpty
                          ? name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize: FontSizes.bodyLarge,
                      ),
                    )
                  : null,
            ),
            Positioned(
              right: -1,
              bottom: -1,
              child: StatusDot(
                presence: _presence(),
                size: 10,
                borderWidth: 2,
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _relativeTime(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: hasUnread
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                _lastMessagePreview(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: hasUnread
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.outline,
                  fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasUnread) ...[
              const SizedBox(width: Spacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(RadiusTokens.round),
                ),
                child: Text(
                  unread > 99 ? '99+' : unread.toString(),
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: FontSizes.caption - 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
