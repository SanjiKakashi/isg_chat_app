/// Domain entity for a single chat message. No framework imports.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.ownerId,
    required this.message,
    required this.timestamp,
    required this.createdAt,
    required this.status,
  });

  final String id;
  final String conversationId;

  /// Either the user's uid or [AppConstants.aiOwnerId].
  final String ownerId;

  final String message;
  final DateTime timestamp;
  final DateTime createdAt;

  /// One of: sent | generating | done | cancelled.
  final String status;

  bool get isAi => ownerId == 'ai';
  bool get isGenerating => status == 'generating';
  bool get isCancelled => status == 'cancelled';
}

