import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/frame.dart';
import '../models/shot.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _framesCollection =>
      _firestore.collection('frames');

  Stream<List<Frame>> watchFrames() {
    return _framesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Frame.fromSnapshot).toList());
  }

  Stream<Frame?> watchFrame(String frameId) {
    return _framesCollection.doc(frameId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      return Frame.fromSnapshot(snapshot);
    });
  }

  Stream<List<Shot>> watchShots(String frameId) {
    return _framesCollection
        .doc(frameId)
        .collection('shots')
        .orderBy('shotAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Shot.fromSnapshot).toList());
  }

  Future<String> createFrame({
    required String name,
    required String type,
    required String shootingCycle,
    required String guide,
  }) async {
    final frameRef = await _framesCollection.add({
      'name': name,
      'type': type,
      'shootingCycle': shootingCycle,
      'guide': guide,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'photoCount': 0,
      'memberCount': 1,
    });

    return frameRef.id;
  }

  Future<void> addShot({
    required String frameId,
    required String title,
    required String photoUrl,
    required String memo,
  }) {
    final frameRef = _framesCollection.doc(frameId);

    return _firestore.runTransaction((transaction) async {
      final shotRef = frameRef.collection('shots').doc();
      transaction.set(shotRef, {
        'title': title,
        'photoUrl': photoUrl,
        'memo': memo,
        'shotAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(frameRef, {
        'photoCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> deleteFrame(String frameId) async {
    final frameRef = _framesCollection.doc(frameId);
    final shots = await frameRef.collection('shots').get();
    final batch = _firestore.batch();

    for (final shot in shots.docs) {
      batch.delete(shot.reference);
    }

    batch.delete(frameRef);
    await batch.commit();
  }
}
