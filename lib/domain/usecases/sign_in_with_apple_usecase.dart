import 'package:isg_chat_app/core/errors/failures.dart';
import 'package:isg_chat_app/domain/entities/user_profile.dart';
import 'package:isg_chat_app/domain/repositories/auth_repository.dart';
import 'package:isg_chat_app/domain/repositories/user_repository.dart';

/// Coordinates Apple sign-in and user profile persistence.
class SignInWithAppleUseCase {
  const SignInWithAppleUseCase({
    required AuthRepository authRepository,
    required UserRepository userRepository,
  })  : _auth = authRepository,
        _user = userRepository;

  final AuthRepository _auth;
  final UserRepository _user;

  /// Runs sign-in then saves the user. Firestore failure is non-blocking.
  Future<({UserProfile? profile, Failure? failure})> execute() async {
    final result = await _auth.signInWithApple();
    if (result.failure != null) return result;
    final profile = result.profile!;
    final saveFailure = await _user.saveOrUpdateUser(profile);
    return (profile: profile, failure: saveFailure);
  }
}
