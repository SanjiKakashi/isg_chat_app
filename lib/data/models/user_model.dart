import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isg_chat_app/core/constants/app_constants.dart';
import 'package:isg_chat_app/domain/entities/user_profile.dart';

/// Firestore-serialisable user document. Serialisation only — no business logic.
class UserModel {
  const UserModel({
    required this.uid,
    required this.provider,
    required this.createdAt,
    required this.lastLoginAt,
    this.displayName,
    this.email,
    this.photoUrl,
    this.isActive = true,
    this.totalConversations = 0,
  });

  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final String provider;
  final Timestamp createdAt;
  final Timestamp lastLoginAt;
  final bool isActive;
  final int totalConversations;

  /// Deserialises a Firestore document map.
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        uid: json[AppConstants.fieldUid] as String,
        displayName: json[AppConstants.fieldDisplayName] as String?,
        email: json[AppConstants.fieldEmail] as String?,
        photoUrl: json[AppConstants.fieldPhotoUrl] as String?,
        provider: json[AppConstants.fieldProvider] as String,
        createdAt: json[AppConstants.fieldCreatedAt] as Timestamp,
        lastLoginAt: json[AppConstants.fieldLastLoginAt] as Timestamp,
        isActive: (json[AppConstants.fieldIsActive] as bool?) ?? true,
        totalConversations:
            (json[AppConstants.fieldTotalConversations] as int?) ?? 0,
      );

  /// Serialises to a Firestore document map.
  Map<String, dynamic> toJson() => {
        AppConstants.fieldUid: uid,
        AppConstants.fieldDisplayName: displayName,
        AppConstants.fieldEmail: email,
        AppConstants.fieldPhotoUrl: photoUrl,
        AppConstants.fieldProvider: provider,
        AppConstants.fieldCreatedAt: createdAt,
        AppConstants.fieldLastLoginAt: lastLoginAt,
        AppConstants.fieldIsActive: isActive,
        AppConstants.fieldTotalConversations: totalConversations,
      };

  /// Converts to the domain entity.
  UserProfile toEntity() => UserProfile(
        uid: uid,
        displayName: displayName,
        email: email,
        photoUrl: photoUrl,
        provider: provider,
        createdAt: createdAt.toDate(),
        lastLoginAt: lastLoginAt.toDate(),
        isActive: isActive,
        totalConversations: totalConversations,
      );

  /// Creates from the domain entity.
  factory UserModel.fromEntity(UserProfile profile) => UserModel(
        uid: profile.uid,
        displayName: profile.displayName,
        email: profile.email,
        photoUrl: profile.photoUrl,
        provider: profile.provider,
        createdAt: Timestamp.fromDate(profile.createdAt),
        lastLoginAt: Timestamp.fromDate(profile.lastLoginAt),
        isActive: profile.isActive,
        totalConversations: profile.totalConversations,
      );
}
