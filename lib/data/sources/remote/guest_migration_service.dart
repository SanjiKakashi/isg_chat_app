import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isg_chat_app/core/constants/app_constants.dart';
import 'package:isg_chat_app/core/utils/app_logger.dart';
import 'package:isg_chat_app/data/sources/remote/firestore_service.dart';

/// A single Firestore document: its ID and field map.
typedef GuestDoc = ({String id, Map<String, dynamic> fields});

/// Pre-flight snapshot of a guest's chat data, captured before Auth changes.
class GuestDataSnapshot {
  const GuestDataSnapshot({
    required this.conversations,
    required this.messages,
  });

  final List<GuestDoc> conversations;

  /// conversationId → list of message documents.
  final Map<String, List<GuestDoc>> messages;

  bool get isEmpty => conversations.isEmpty;
}

/// Reads and batch-writes Firestore data during guest-to-named account linking.
class GuestMigrationService {
  GuestMigrationService({required FirestoreService firestoreService})
      : _firestore = firestoreService;

  final FirestoreService _firestore;

  static const int _batchLimit = 499;

  CollectionReference<Map<String, dynamic>> _conversationsRef(String uid) =>
      _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection(AppConstants.conversationsCollection);

  CollectionReference<Map<String, dynamic>> _messagesRef(
    String uid,
    String conversationId,
  ) =>
      _conversationsRef(uid)
          .doc(conversationId)
          .collection(AppConstants.messagesCollection);

  /// Reads all conversations and their messages for [guestUid].
  /// Must be called while the Firebase session is still anonymous.
  Future<GuestDataSnapshot> fetchGuestData(String guestUid) async {
    final convSnap = await _conversationsRef(guestUid).get();
    final conversations =
        convSnap.docs.map((d) => (id: d.id, fields: d.data())).toList();

    final messages = <String, List<GuestDoc>>{};
    for (final conv in conversations) {
      final msgSnap = await _messagesRef(guestUid, conv.id).get();
      messages[conv.id] =
          msgSnap.docs.map((d) => (id: d.id, fields: d.data())).toList();
    }

    AppLogger.instance.i(
      'fetchGuestData: ${conversations.length} conversations, '
      '${messages.values.fold(0, (s, l) => s + l.length)} messages',
    );

    return GuestDataSnapshot(conversations: conversations, messages: messages);
  }

  /// Batch-copies [guestData] to [newUid]; best-effort deletes [guestUid] docs.
  Future<void> migrate({
    required String guestUid,
    required String newUid,
    required GuestDataSnapshot guestData,
  }) async {
    if (guestData.isEmpty) {
      AppLogger.instance.i('migrate: no guest data — skipping');
      return;
    }

    final db =
        _firestore.collection(AppConstants.usersCollection).firestore;

    // ── Write phase ───────────────────────────────────────────────────────────
    var batch = db.batch();
    var opCount = 0;

    Future<void> flushIfNeeded() async {
      if (opCount >= _batchLimit) {
        await batch.commit();
        batch = db.batch();
        opCount = 0;
      }
    }

    for (final conv in guestData.conversations) {
      batch.set(_conversationsRef(newUid).doc(conv.id), conv.fields);
      opCount++;
      await flushIfNeeded();

      for (final msg in guestData.messages[conv.id] ?? <GuestDoc>[]) {
        batch.set(_messagesRef(newUid, conv.id).doc(msg.id), msg.fields);
        opCount++;
        await flushIfNeeded();
      }
    }

    if (opCount > 0) await batch.commit();

    AppLogger.instance.i(
      'migrate: wrote ${guestData.conversations.length} conversations '
      'and ${guestData.messages.values.fold(0, (s, l) => s + l.length)} messages '
      'to $newUid',
    );

    // ── Delete phase (best-effort) ────────────────────────────────────────────
    try {
      var delBatch = db.batch();
      var delCount = 0;

      Future<void> flushDelIfNeeded() async {
        if (delCount >= _batchLimit) {
          await delBatch.commit();
          delBatch = db.batch();
          delCount = 0;
        }
      }

      for (final conv in guestData.conversations) {
        for (final msg in guestData.messages[conv.id] ?? <GuestDoc>[]) {
          delBatch.delete(_messagesRef(guestUid, conv.id).doc(msg.id));
          delCount++;
          await flushDelIfNeeded();
        }
        delBatch.delete(_conversationsRef(guestUid).doc(conv.id));
        delCount++;
        await flushDelIfNeeded();
      }

      delBatch.delete(
        _firestore.collection(AppConstants.usersCollection).doc(guestUid),
      );
      delCount++;

      if (delCount > 0) await delBatch.commit();
      AppLogger.instance.i('migrate: cleaned up guest docs for $guestUid');
    } on Exception catch (e) {
      AppLogger.instance
          .w('migrate: delete phase failed (non-critical)', error: e);
    }
  }
}

