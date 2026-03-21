import 'package:isg_chat_app/core/errors/failures.dart';
import 'package:isg_chat_app/domain/entities/user_profile.dart';
import 'package:isg_chat_app/domain/repositories/auth_repository.dart';
import 'package:isg_chat_app/domain/repositories/user_repository.dart';

/// Links a guest account to Google and persists the named user profile.
class LinkWithGoogleUseCase {
  const LinkWithGoogleUseCase({
    required AuthRepository authRepository,
    required UserRepository userRepository,
  })  : _auth = authRepository,
        _user = userRepository;

  final AuthRepository _auth;
  final UserRepository _user;

  Future<({UserProfile? profile, Failure? failure})> execute({
    required String guestUid,
  }) async {
    final result = await _auth.linkWithGoogle(guestUid: guestUid);
    if (result.profile != null) {
      await _user.saveOrUpdateUser(result.profile!);
    }
    return result;
  }
}

