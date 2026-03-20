import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isg_chat_app/core/constants/app_constants.dart';
import 'package:isg_chat_app/core/utils/app_logger.dart';
import 'package:isg_chat_app/data/models/user_model.dart';
import 'package:isg_chat_app/data/sources/remote/firestore_service.dart';

/// Handles all Firestore reads/writes for the users collection and
/// the conversations sub-collection.
class UserRemoteSource {
  const UserRemoteSource({required FirestoreService firestoreService})
      : _firestore = firestoreService;

  final FirestoreService _firestore;

  /// Creates or updates the user doc.
  /// First login: writes full payload + bootstraps conversations/_metadata.
  /// Returning login: merge-writes mutable fields only.
  Future<void> saveOrUpdateUser(UserModel model) async {
    final isNew = !(await _firestore.documentExists(
      collection: AppConstants.usersCollection,
      docId: model.uid,
    ));

    if (isNew) {
      AppLogger.instance.i('First login — creating user ${model.uid}');
      await _writeNewUser(model);
    } else {
      AppLogger.instance.i('Returning login — updating user ${model.uid}');
      await _updateReturningUser(model);
    }
  }

  /// Writes the full user doc + conversations/_metadata in a single batch.
  Future<void> _writeNewUser(UserModel model) async {
    final usersCol = _firestore.collection(AppConstants.usersCollection);
    final batch = usersCol.firestore.batch();

    batch.set(usersCol.doc(model.uid), model.toJson(), SetOptions(merge: true));

    await batch.commit();
    AppLogger.instance.i('User + conversations/_metadata created for ${model.uid}');
  }

  /// Merge-writes only the fields that change on each login.
  Future<void> _updateReturningUser(UserModel model) async {
    await _firestore.setDocument(
      collection: AppConstants.usersCollection,
      docId: model.uid,
      data: {
        AppConstants.fieldDisplayName: model.displayName,
        AppConstants.fieldEmail: model.email,
        AppConstants.fieldPhotoUrl: model.photoUrl,
        AppConstants.fieldLastLoginAt: model.lastLoginAt,
        AppConstants.fieldIsActive: true,
      },
    );
  }

  /// Returns the [UserModel] for [uid], or null.
  Future<UserModel?> fetchUser(String uid) async {
    final data = await _firestore.getDocument(
      collection: AppConstants.usersCollection,
      docId: uid,
    );
    if (data == null) return null;
    try {
      return UserModel.fromJson(data);
    } on Exception catch (e) {
      AppLogger.instance.e('fetchUser parse error', error: e);
      return null;
    }
  }
}
