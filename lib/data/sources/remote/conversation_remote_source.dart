import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isg_chat_app/core/constants/app_constants.dart';
import 'package:isg_chat_app/core/utils/app_logger.dart';
import 'package:isg_chat_app/data/models/conversation_model.dart';
import 'package:isg_chat_app/data/models/message_model.dart';
import 'package:isg_chat_app/data/sources/remote/firestore_service.dart';
import 'package:uuid/uuid.dart';

/// Firestore reads/writes for conversations and messages.
class ConversationRemoteSource {
  ConversationRemoteSource({required FirestoreService firestoreService})
      : _firestore = firestoreService;

  final FirestoreService _firestore;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> _conversationsRef(String userId) =>
      _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.conversationsCollection);

  CollectionReference<Map<String, dynamic>> _messagesRef(
    String userId,
    String conversationId,
  ) =>
      _conversationsRef(userId)
          .doc(conversationId)
          .collection(AppConstants.messagesCollection);

  /// Live stream of all conversations for [userId], newest first.
  /// Sorted client-side to avoid a composite Firestore index requirement.
  Stream<List<ConversationModel>> watchConversations(String userId) =>
      _conversationsRef(userId).snapshots().map(
            (snap) {
              final docs = snap.docs
                  .map((doc) => ConversationModel.fromJson(doc.id, doc.data()))
                  .toList();
              docs.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
              return docs;
            },
          );

  /// Live stream of messages for [conversationId], ordered by timestamp.
  Stream<List<MessageModel>> watchMessages(
          String userId, String conversationId) =>
      _messagesRef(userId, conversationId)
          .orderBy(AppConstants.fieldTimestamp)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map((doc) =>
                    MessageModel.fromJson(doc.id, conversationId, doc.data()))
                .toList(),
          );

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
    await _conversationsRef(userId)
        .doc(conversationId)
        .update({AppConstants.fieldLastMessageAt: now});
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

  /// One-shot fetch of all conversations, newest first.
  Future<List<ConversationModel>> fetchConversations(String userId) async {
    final snap = await _conversationsRef(userId).get();
    final docs = snap.docs
        .map((doc) => ConversationModel.fromJson(doc.id, doc.data()))
        .toList();
    docs.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return docs;
  }

  /// Creates a conversation document and returns its ID.
  Future<String> createConversation(String userId) async {
    final conversationId = _uuid.v4();
    final now = Timestamp.now();
    await _conversationsRef(userId).doc(conversationId).set({
      AppConstants.fieldCreatedAt: now,
      AppConstants.fieldLastMessageAt: now,
      AppConstants.fieldUid: userId,
    });
    AppLogger.instance.i('Conversation created: $conversationId');
    return conversationId;
  }
}
