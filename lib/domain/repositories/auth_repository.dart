import 'package:isg_chat_app/core/errors/failures.dart';
import 'package:isg_chat_app/domain/entities/user_profile.dart';

/// Abstract auth contract — implemented by [AuthRepositoryImpl].
abstract class AuthRepository {
  /// Signs in with Google. Returns [CancelledFailure] on dismiss.
  Future<({UserProfile? profile, Failure? failure})> signInWithGoogle();

  /// Signs in with Apple (iOS only). Returns [CancelledFailure] on dismiss.
  Future<({UserProfile? profile, Failure? failure})> signInWithApple();

  /// Signs in anonymously (guest mode).
  Future<({UserProfile? profile, Failure? failure})> signInAnonymously();

  /// Links a guest account to Google, migrating chat history.
  Future<({UserProfile? profile, Failure? failure})> linkWithGoogle({
    required String guestUid,
  });

  /// Links a guest account to Apple (iOS only), migrating chat history.
  Future<({UserProfile? profile, Failure? failure})> linkWithApple({
    required String guestUid,
  });

  /// Returns the current user session, or null.
  Future<UserProfile?> getCurrentUser();

  /// Signs out from Firebase.
  Future<void> signOut();
}
