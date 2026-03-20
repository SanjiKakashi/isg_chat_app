import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isg_chat_app/core/constants/app_constants.dart';
import 'package:isg_chat_app/core/utils/app_logger.dart';
import 'package:isg_chat_app/data/models/message_model.dart';
import 'package:isg_chat_app/data/sources/remote/firestore_service.dart';
import 'package:uuid/uuid.dart';

/// Firestore reads/writes for conversations and messages.
class ConversationRemoteSource {
  ConversationRemoteSource({required FirestoreService firestoreService})
      : _firestore = firestoreService;

  final FirestoreService _firestore;
  final _uuid = const Uuid();

  /// Returns a [CollectionReference] for messages under [conversationId].
  CollectionReference<Map<String, dynamic>> _messagesRef(
    String userId,
    String conversationId,
  ) =>
      _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.conversationsCollection)
          .doc(conversationId)
          .collection(AppConstants.messagesCollection);

  /// Returns a live-updating stream of messages ordered by timestamp.
  Stream<List<MessageModel>> watchMessages(
    String userId,
    String conversationId,
  ) {
    return _messagesRef(userId, conversationId)
        .orderBy(AppConstants.fieldTimestamp)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => MessageModel.fromJson(doc.id, conversationId, doc.data()),
              )
              .toList(),
        );
  }

  /// Adds a message document and returns its new ID.
  Future<String> addMessage({
    required String userId,
    required String conversationId,
    required String ownerId,
    required String message,
    required String status,
  }) async {
    final now = Timestamp.now();
    final model = MessageModel(
      id: '',
      conversationId: conversationId,
      ownerId: ownerId,
      message: message,
      timestamp: now,
      createdAt: now,
      status: status,
    );
    final ref = await _messagesRef(userId, conversationId).add(model.toJson());
    AppLogger.instance.i('Message added: ${ref.id}');
    return ref.id;
  }

  /// Updates [status] and optionally [message] of an existing document.
  Future<void> updateMessage({
    required String userId,
    required String conversationId,
    required String messageId,
    required String status,
    String? message,
  }) async {
    final data = <String, dynamic>{AppConstants.fieldStatus: status};
    if (message != null) data[AppConstants.fieldMessage] = message;
    await _messagesRef(userId, conversationId).doc(messageId).update(data);
  }

  /// Creates a conversation document under users/{userId}/conversations.
  Future<String> createConversation(String userId) async {
    final conversationId = _uuid.v4();
    final now = Timestamp.now();
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.conversationsCollection)
        .doc(conversationId)
        .set({
      AppConstants.fieldCreatedAt: now,
      AppConstants.fieldLastLoginAt: now,
      AppConstants.fieldUid: userId,
    });
    AppLogger.instance.i('Conversation created: $conversationId');
    return conversationId;
  }
}

