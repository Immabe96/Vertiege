import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/resident_provider.dart';
import '../services/chat_service.dart';
import '../utils/date_format.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String roomId;

  const ChatRoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _controller = TextEditingController();
  final _messages = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadMessages();
    ChatService.subscribeToMessages(widget.roomId, (message) {
      setState(() => _messages.add(message));
    });
  }

  Future<void> _loadMessages() async {
    final msgs = await ChatService.getMessages(widget.roomId);
    setState(() => _messages.addAll(msgs));
  }

  void _send() {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    final resident = ref.read(residentProvider).resident;
    if (resident == null) return;

    ChatService.sendMessage(roomId: widget.roomId, senderId: resident.id, content: content);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(child: Text('No messages yet', style: theme.textTheme.bodyLarge))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['sender_id'] == ref.read(residentProvider).resident?.id;
                      final timestamp = DateTime.tryParse(msg['created_at'] ?? '')?.millisecondsSinceEpoch ?? 0;

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(msg['content'] ?? ''),
                              const SizedBox(height: 2),
                              Text(formatTimestamp(timestamp), style: theme.textTheme.labelSmall),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Message...', border: OutlineInputBorder(), isDense: true),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: _send),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
