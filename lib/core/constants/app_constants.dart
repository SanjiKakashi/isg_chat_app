/// App-wide string constants — Firestore keys, routes, assets.
class AppConstants {
  AppConstants._();

  static const String usersCollection = 'users';

  /// users/{uid}/conversations/{conversationId}
  static const String conversationsCollection = 'conversations';

  /// users/{uid}/conversations/{id}/messages/{messageId}
  static const String messagesCollection = 'messages';

  // User document fields
  static const String fieldUid = 'uid';
  static const String fieldDisplayName = 'displayName';
  static const String fieldEmail = 'email';
  static const String fieldPhotoUrl = 'photoUrl';
  static const String fieldProvider = 'provider';
  static const String fieldCreatedAt = 'createdAt';
  static const String fieldLastLoginAt = 'lastLoginAt';
  static const String fieldIsActive = 'isActive';
  static const String fieldTotalConversations = 'totalConversations';
  static const String fieldInitialisedAt = 'initialisedAt';
  static const String fieldSchemaVersion = 'schemaVersion';

  // Message document fields
  static const String fieldOwnerId = 'ownerId';
  static const String fieldMessage = 'message';
  static const String fieldTimestamp = 'timestamp';
  static const String fieldStatus = 'status';

  static const String fieldLastMessageAt = 'lastMessageAt';

  // Message status values
  static const String statusSent = 'sent';
  static const String statusGenerating = 'generating';
  static const String statusDone = 'done';
  static const String statusCancelled = 'cancelled';

  /// Fixed ownerId for all AI messages.
  static const String aiOwnerId = 'ai';

  static const String providerGoogle = 'google';
  static const String providerApple = 'apple';
  static const String providerAnonymous = 'anonymous';

  static const String configCollection = 'config';
  static const String configOpenAiDoc = 'openai';
  static const String fieldApiKey = 'apiKey';
}
