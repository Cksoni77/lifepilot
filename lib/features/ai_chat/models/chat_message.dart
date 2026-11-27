class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.content,
    required this.fromUser,
    required this.timestamp,
    this.action,
  });

  final String id;
  final String content;
  final bool fromUser;
  final DateTime timestamp;
  final ChatAction? action;
}

class ChatAction {
  const ChatAction({required this.label, required this.description});

  final String label;
  final String description;
}
