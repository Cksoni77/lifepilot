import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/chat_message.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});
  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _controller = TextEditingController();
  final _messages = <ChatMessage>[
    ChatMessage(
      id: 'welcome',
      content:
          'Good afternoon! You have 2 tasks left and a workout habit pending. Want me to reshuffle your evening?',
      fromUser: false,
      timestamp: DateTime(2026, 8, 8),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().toIso8601String(),
          content: text,
          fromUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _messages.add(
        ChatMessage(
          id: '${DateTime.now().microsecondsSinceEpoch}-reply',
          content: 'Done - I can help turn that into a clear next step.',
          fromUser: false,
          timestamp: DateTime.now(),
        ),
      );
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Row(
        children: [
          const CircleAvatar(
            radius: 17,
            backgroundColor: AppColors.accentPurpleTint,
            child: Icon(
              Icons.auto_awesome,
              color: AppColors.accentPurple,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('AI Co-pilot'),
              Text(
                '● Online',
                style: TextStyle(color: AppColors.primary, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.more_horiz),
          tooltip: 'More options',
        ),
      ],
    ),
    body: Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return _Bubble(message: message);
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: 'Ask LifePilot anything...',
                      prefixIcon: Icon(Icons.add),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _send,
                  icon: const Icon(Icons.mic_none),
                  tooltip: 'Send message',
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) => Align(
    alignment: message.fromUser ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      constraints: const BoxConstraints(maxWidth: 310),
      decoration: BoxDecoration(
        color: message.fromUser ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(message.fromUser ? 16 : 4),
          bottomRight: Radius.circular(message.fromUser ? 4 : 16),
        ),
        border: message.fromUser ? null : Border.all(color: AppColors.border),
      ),
      child: Text(
        message.content,
        style: TextStyle(
          color: message.fromUser ? Colors.white : AppColors.textPrimary,
        ),
      ),
    ),
  );
}
