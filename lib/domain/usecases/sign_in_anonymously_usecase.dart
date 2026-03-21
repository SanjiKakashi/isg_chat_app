import 'package:isg_chat_app/core/errors/failures.dart';
import 'package:isg_chat_app/domain/entities/user_profile.dart';
import 'package:isg_chat_app/domain/repositories/auth_repository.dart';
import 'package:isg_chat_app/domain/repositories/user_repository.dart';

/// Signs in anonymously and persists the guest user document.
class SignInAnonymouslyUseCase {
  const SignInAnonymouslyUseCase({
    required AuthRepository authRepository,
    required UserRepository userRepository,
  })  : _auth = authRepository,
        _user = userRepository;

  final AuthRepository _auth;
  final UserRepository _user;

  Future<({UserProfile? profile, Failure? failure})> execute() async {
    final result = await _auth.signInAnonymously();
    if (result.profile != null) {
      await _user.saveOrUpdateUser(result.profile!);
    }
    return result;
  }
}

