/// Domain entity for a conversation thread. No framework imports.
class Conversation {
  const Conversation({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.lastMessageAt,
  });

  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime lastMessageAt;
}

