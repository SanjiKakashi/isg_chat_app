import 'package:isg_chat_app/core/utils/app_logger.dart';
import 'package:isg_chat_app/data/sources/remote/conversation_remote_source.dart';
import 'package:isg_chat_app/domain/entities/chat_message.dart';
import 'package:isg_chat_app/domain/repositories/conversation_repository.dart';

/// Firestore implementation of [ConversationRepository].
class ConversationRepositoryImpl implements ConversationRepository {
  ConversationRepositoryImpl({required ConversationRemoteSource remoteSource})
      : _remote = remoteSource;

  final ConversationRemoteSource _remote;

  @override
  Stream<List<ChatMessage>> watchMessages(
    String userId,
    String conversationId,
  ) =>
      _remote
          .watchMessages(userId, conversationId)
          .map((models) => models.map((m) => m.toEntity()).toList());

  @override
  Future<String> addMessage({
    required String userId,
    required String conversationId,
    required String ownerId,
    required String message,
    required String status,
  }) =>
      _remote.addMessage(
        userId: userId,
        conversationId: conversationId,
        ownerId: ownerId,
        message: message,
        status: status,
      );

  @override
  Future<void> updateMessage({
    required String userId,
    required String conversationId,
    required String messageId,
    required String status,
    String? message,
  }) =>
      _remote.updateMessage(
        userId: userId,
        conversationId: conversationId,
        messageId: messageId,
        status: status,
        message: message,
      );

  @override
  Future<String> createConversation(String userId) async {
    try {
      return await _remote.createConversation(userId);
    } on Exception catch (e) {
      AppLogger.instance.e('createConversation failed', error: e);
      rethrow;
    }
  }
}

