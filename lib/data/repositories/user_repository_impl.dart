import 'package:isg_chat_app/core/errors/failures.dart';
import 'package:isg_chat_app/core/utils/app_logger.dart';
import 'package:isg_chat_app/data/models/user_model.dart';
import 'package:isg_chat_app/data/sources/remote/user_remote_source.dart';
import 'package:isg_chat_app/domain/entities/user_profile.dart';
import 'package:isg_chat_app/domain/repositories/user_repository.dart';

/// Firestore implementation of [UserRepository].
class UserRepositoryImpl implements UserRepository {
  const UserRepositoryImpl({required UserRemoteSource remoteSource})
      : _remote = remoteSource;

  final UserRemoteSource _remote;

  @override
  Future<Failure?> saveOrUpdateUser(UserProfile profile) async {
    try {
      await _remote.saveOrUpdateUser(UserModel.fromEntity(profile));
      return null;
    } on Exception catch (e) {
      AppLogger.instance.e('saveOrUpdateUser failed', error: e);
      return const FirestoreFailure(
        'Could not save your profile. Your chat will still work.',
      );
    }
  }

  @override
  Future<UserProfile?> fetchUser(String uid) async {
    try {
      final model = await _remote.fetchUser(uid);
      return model?.toEntity();
    } on Exception catch (e) {
      AppLogger.instance.e('fetchUser failed', error: e);
      return null;
    }
  }
}
