import 'package:flutter/material.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text('No conversations yet', style: theme.textTheme.bodyLarge),
            Text('Connect with other residents to start chatting', style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
