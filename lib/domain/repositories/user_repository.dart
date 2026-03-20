import 'package:isg_chat_app/core/errors/failures.dart';
import 'package:isg_chat_app/domain/entities/user_profile.dart';

/// Abstract user-persistence contract — implemented by [UserRepositoryImpl].
abstract class UserRepository {
  /// Creates or updates the user document. Never overwrites [createdAt].
  Future<Failure?> saveOrUpdateUser(UserProfile profile);

  /// Fetches the user for [uid], or null if not found.
  Future<UserProfile?> fetchUser(String uid);
}
