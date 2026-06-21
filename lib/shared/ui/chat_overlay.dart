import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rang_adda/shared/models/chat_message.dart';
import 'package:rang_adda/shared/services/firestore_service.dart';
import 'package:rang_adda/shared/services/auth_service.dart';
import 'package:rang_adda/shared/ui/theme.dart';

class ChatOverlay extends StatelessWidget {
  final List<ChatMessage> messages;
  const ChatOverlay({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    // Only show messages from the last 15 seconds
    final recentMessages = messages.where((m) {
      return DateTime.now().difference(m.timestamp).inSeconds < 15;
    }).toList();

    if (recentMessages.isEmpty) return const SizedBox.shrink();

    return Positioned(
      bottom: 100,
      left: 16,
      right: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: recentMessages.map((m) {
          return _ChatMessageToast(message: m);
        }).toList(),
      ),
    );
  }
}

class _ChatMessageToast extends StatelessWidget {
  final ChatMessage message;
  const _ChatMessageToast({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "${message.senderName}: ",
              style: const TextStyle(
                color: AppTheme.surface,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: message.text,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatInputModal extends ConsumerStatefulWidget {
  final String gameId;
  const ChatInputModal({super.key, required this.gameId});

  @override
  ConsumerState<ChatInputModal> createState() => _ChatInputModalState();
}

class _ChatInputModalState extends ConsumerState<ChatInputModal> {
  final TextEditingController _controller = TextEditingController();
  final List<String> emojis = ["😂", "😡", "😱", "🥳", "👍", "👎", "🔥", "💯"];

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    
    final user = ref.read(userProvider).value;
    if (user == null) return;

    final msg = ChatMessage(
      senderId: user.uid,
      senderName: user.displayName ?? "Player",
      text: _controller.text.trim(),
      timestamp: DateTime.now(),
    );

    ref.read(firestoreServiceProvider).sendChatMessage(widget.gameId, msg);
    _controller.clear();
    Navigator.of(context).pop();
  }

  void _sendEmoji(String emoji) {
    final user = ref.read(userProvider).value;
    if (user == null) return;
    
    ref.read(firestoreServiceProvider).sendEmoji(widget.gameId, user.uid, emoji);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Emoji Picker
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: emojis.length,
              itemBuilder: (context, index) {
                return IconButton(
                  icon: Text(emojis[index], style: const TextStyle(fontSize: 24)),
                  onPressed: () => _sendEmoji(emojis[index]),
                );
              },
            ),
          ),
          const Divider(color: Colors.white24),
          // Text Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Send a message...",
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: AppTheme.accentPrimary),
                onPressed: _sendMessage,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
