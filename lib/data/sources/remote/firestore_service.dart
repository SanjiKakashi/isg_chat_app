import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isg_chat_app/core/utils/app_logger.dart';

/// Singleton Firestore gateway. All raw [FirebaseFirestore] calls go here.
class FirestoreService {
  FirestoreService._internal() : _db = FirebaseFirestore.instance;

  static final FirestoreService _instance = FirestoreService._internal();
  static FirestoreService get instance => _instance;

  final FirebaseFirestore _db;

  /// Merge-writes [data] to [collection]/[docId].
  Future<void> setDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _db.collection(collection).doc(docId).set(data, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      AppLogger.instance.e('setDocument failed', error: e);
      rethrow;
    }
  }

  /// Returns the document map, or null if it does not exist.
  Future<Map<String, dynamic>?> getDocument({
    required String collection,
    required String docId,
  }) async {
    try {
      final snap = await _db.collection(collection).doc(docId).get();
      return snap.exists ? snap.data() : null;
    } on FirebaseException catch (e) {
      AppLogger.instance.e('getDocument failed', error: e);
      rethrow;
    }
  }

  /// Returns true if the document exists (metadata-only server read).
  Future<bool> documentExists({
    required String collection,
    required String docId,
  }) async {
    try {
      final snap = await _db
          .collection(collection)
          .doc(docId)
          .get(const GetOptions(source: Source.server));
      return snap.exists;
    } on FirebaseException catch (e) {
      AppLogger.instance.e('documentExists failed', error: e);
      rethrow;
    }
  }

  /// Merge-writes [data] to [collection]/[docId]/[subCollection]/[subDocId].
  Future<void> setSubDocument({
    required String collection,
    required String docId,
    required String subCollection,
    required String subDocId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _db
          .collection(collection)
          .doc(docId)
          .collection(subCollection)
          .doc(subDocId)
          .set(data, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      AppLogger.instance.e('setSubDocument failed', error: e);
      rethrow;
    }
  }

  /// Returns a [CollectionReference] for advanced queries.
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _db.collection(path);
}

