import 'package:isg_chat_app/domain/entities/user_profile.dart';
import 'package:isg_chat_app/domain/repositories/auth_repository.dart';

/// Returns the current session user, or null.
class GetCurrentUserUseCase {
  const GetCurrentUserUseCase({required AuthRepository authRepository})
      : _auth = authRepository;

  final AuthRepository _auth;

  Future<UserProfile?> execute() => _auth.getCurrentUser();
}

