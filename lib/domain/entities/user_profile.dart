/// Domain entity for an authenticated user. No framework imports.
class UserProfile {
  const UserProfile({
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
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isActive;

  /// Incremented by the Chat feature; initialised to 0 on first login.
  final int totalConversations;

  /// True when the user is signed in anonymously.
  bool get isGuest => provider == 'anonymous';

  /// Display name with fallback.
  String get nameOrFallback => isGuest ? 'Guest' : (displayName ?? 'User');

  @override
  String toString() =>
      'UserProfile(uid: $uid, email: $email, provider: $provider)';
}
