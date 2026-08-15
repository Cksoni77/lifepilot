import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({required this.message, required this.fromUser, super.key});
  final String message;
  final bool fromUser;

  @override
  Widget build(BuildContext context) => Align(
    alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
    child: Card(
      child: Padding(padding: const EdgeInsets.all(12), child: Text(message)),
    ),
  );
}
