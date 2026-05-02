import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/chat_provider.dart';
import '../../state/resident_provider.dart';
import '../../utils/date_format.dart';
import '../../widgets/core/fade_in.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final residentId =
        ref.watch(residentProvider.select((s) => s.resident?.id));
    final chatState = ref.watch(chatProvider);

    // Trigger initial load once when resident is available and rooms
    // have not been fetched yet. The guard on isLoadingRooms inside
    // loadDmRooms prevents duplicate in-flight calls, and this outer
    // check on dmRooms.isEmpty prevents re-fetching after success.
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 8,
      itemBuilder: (context, index) => Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
          const SizedBox(height: 8),
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
      padding: const EdgeInsets.only(top: 8),
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
  ///
  /// Filters `resident_ids` to remove the current user, then checks for a
  /// backend-supplied name via [names] map or [other_name] key. Falls back
  /// to the raw ID when no display name is available.
  String _otherResidentName() {
    final ids = (room['resident_ids'] as List?)?.cast<String>() ?? [];
    final otherId = ids.firstWhere(
      (id) => id != currentResidentId,
      orElse: () => ids.isNotEmpty ? ids.first : '',
    );
    if (otherId.isEmpty) return 'Unknown';

    // Backend may supply a names map keyed by resident ID.
    final names = room['names'] as Map<String, dynamic>?;
    if (names != null && names[otherId] is String) {
      return names[otherId] as String;
    }

    // Backend may supply a single other_name field.
    final direct = room['other_name'];
    if (direct is String && direct.isNotEmpty) return direct;

    return otherId;
  }

  String _lastMessagePreview() {
    final msg = room['last_message'];
    if (msg == null) return 'No messages yet';
    final text = msg.toString();
    if (text.isEmpty) return 'No messages yet';
    return text.length > 50 ? '${text.substring(0, 50)}...' : text;
  }

  String _relativeTime() {
    final lastMessageAt = room['last_message_at'];
    if (lastMessageAt == null) return '';
    try {
      final dt = DateTime.parse(lastMessageAt.toString());
      return formatTimestamp(dt.millisecondsSinceEpoch);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = _otherResidentName();

    return FadeIn(
      delayMs: index * 50,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            name.substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        title: Text(
          name,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _lastMessagePreview(),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          _relativeTime(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
