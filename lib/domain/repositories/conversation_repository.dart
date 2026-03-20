import 'package:isg_chat_app/domain/entities/chat_message.dart';

/// Abstract contract for conversation and message operations.
abstract class ConversationRepository {
  /// Returns a live stream of messages for [conversationId], ordered by timestamp.
  Stream<List<ChatMessage>> watchMessages(String userId, String conversationId);

  /// Adds a message document and returns its generated ID.
  Future<String> addMessage({
    required String userId,
    required String conversationId,
    required String ownerId,
    required String message,
    required String status,
  });

  /// Updates [status] (and optionally [message]) of an existing message.
  Future<void> updateMessage({
    required String userId,
    required String conversationId,
    required String messageId,
    required String status,
    String? message,
  });

  /// Creates a new conversation document and returns the new conversationId.
  Future<String> createConversation(String userId);
}

