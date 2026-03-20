import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isg_chat_app/core/constants/app_constants.dart';
import 'package:isg_chat_app/domain/entities/chat_message.dart';

/// Firestore-serialisable message document. Serialisation only.
class MessageModel {
  const MessageModel({
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
  final String ownerId;
  final String message;
  final Timestamp timestamp;
  final Timestamp createdAt;
  final String status;

  factory MessageModel.fromJson(
    String id,
    String conversationId,
    Map<String, dynamic> json,
  ) =>
      MessageModel(
        id: id,
        conversationId: conversationId,
        ownerId: json[AppConstants.fieldOwnerId] as String,
        message: json[AppConstants.fieldMessage] as String? ?? '',
        timestamp: json[AppConstants.fieldTimestamp] as Timestamp,
        createdAt: json[AppConstants.fieldCreatedAt] as Timestamp,
        status: json[AppConstants.fieldStatus] as String? ?? AppConstants.statusDone,
      );

  Map<String, dynamic> toJson() => {
        AppConstants.fieldOwnerId: ownerId,
        AppConstants.fieldMessage: message,
        AppConstants.fieldTimestamp: timestamp,
        AppConstants.fieldCreatedAt: createdAt,
        AppConstants.fieldStatus: status,
      };

  ChatMessage toEntity() => ChatMessage(
        id: id,
        conversationId: conversationId,
        ownerId: ownerId,
        message: message,
        timestamp: timestamp.toDate(),
        createdAt: createdAt.toDate(),
        status: status,
      );
}

