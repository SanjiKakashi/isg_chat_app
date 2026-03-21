import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isg_chat_app/core/constants/app_constants.dart';
import 'package:isg_chat_app/domain/entities/conversation.dart';

/// Firestore-serialisable conversation document. Serialisation only.
class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.lastMessageAt,
  });

  final String id;
  final String userId;
  final Timestamp createdAt;
  final Timestamp lastMessageAt;

  factory ConversationModel.fromJson(String id, Map<String, dynamic> json) =>
      ConversationModel(
        id: id,
        userId: json[AppConstants.fieldUid] as String? ?? '',
        createdAt: json[AppConstants.fieldCreatedAt] as Timestamp? ?? Timestamp.now(),
        lastMessageAt: json[AppConstants.fieldLastMessageAt] as Timestamp? ?? Timestamp.now(),
      );

  Conversation toEntity() => Conversation(
        id: id,
        userId: userId,
        createdAt: createdAt.toDate(),
        lastMessageAt: lastMessageAt.toDate(),
      );
}
