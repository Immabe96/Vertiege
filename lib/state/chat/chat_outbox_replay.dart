import '../../services/chat_service.dart';
import '../../services/mutation_outbox_service.dart';

/// Replays queued chat/channel message mutations from the offline outbox.
mixin ChatOutboxReplay {
  Future<void> replayQueuedChatMutations() async {
    await MutationOutboxService.replayWhere(
      (mutation) =>
          mutation.type == 'chat.message' ||
          mutation.type == 'channel.message' ||
          mutation.type == 'chat.message.edit' ||
          mutation.type == 'chat.message.delete' ||
          mutation.type == 'channel.message.edit' ||
          mutation.type == 'channel.message.delete',
      (mutation) async {
        switch (mutation.type) {
          case 'chat.message':
            final payload = mutation.payload;
            await ChatService.sendMessage(
              messageId: payload['messageId'] as String,
              roomId: payload['roomId'] as String,
              senderId: payload['senderId'] as String,
              senderName: payload['senderName'] as String,
              senderAvatar: payload['senderAvatar'] as String?,
              content: payload['content'] as String,
              imageUrl: payload['imageUrl'] as String?,
              autoDeleteAfterSeconds: payload['autoDeleteAfterSeconds'] as int?,
              replyToMessageId: payload['replyToMessageId'] as String?,
              replyToSenderId: payload['replyToSenderId'] as String?,
              replyToSenderName: payload['replyToSenderName'] as String?,
              replyToContent: payload['replyToContent'] as String?,
            );
            return;
          case 'channel.message':
            final payload = mutation.payload;
            await ChatService.sendChannelMessage(
              messageId: payload['messageId'] as String,
              worldId: payload['worldId'] as String,
              channelId: payload['channelId'] as String,
              senderId: payload['senderId'] as String,
              senderName: payload['senderName'] as String,
              senderAvatar: payload['senderAvatar'] as String?,
              content: payload['content'] as String,
              imageUrl: payload['imageUrl'] as String?,
            );
            return;
          case 'chat.message.edit':
            final payload = mutation.payload;
            await ChatService.editMessage(
              messageId: payload['messageId'] as String,
              newContent: payload['newContent'] as String,
            );
            return;
          case 'chat.message.delete':
            await ChatService.deleteMessage(
              messageId: mutation.payload['messageId'] as String,
            );
            return;
          case 'channel.message.edit':
            final payload = mutation.payload;
            await ChatService.editMessage(
              messageId: payload['messageId'] as String,
              newContent: payload['newContent'] as String,
            );
            return;
          case 'channel.message.delete':
            await ChatService.deleteMessage(
              messageId: mutation.payload['messageId'] as String,
            );
            return;
          default:
            return;
        }
      },
    );
  }
}
