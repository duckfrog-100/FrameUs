import 'package:cloud_firestore/cloud_firestore.dart';

class Shot {
  const Shot({
    required this.title,
    required this.photoUrl,
    required this.memo,
    required this.shotAt,
  });

  factory Shot.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? <String, dynamic>{};

    return Shot(
      title: data['title'] as String? ?? '촬영 기록',
      photoUrl: data['photoUrl'] as String? ?? '',
      memo: data['memo'] as String? ?? '',
      shotAt: data['shotAt'] as Timestamp?,
    );
  }

  final String title;
  final String photoUrl;
  final String memo;
  final Timestamp? shotAt;
}
