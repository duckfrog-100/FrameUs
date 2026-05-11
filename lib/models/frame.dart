import 'package:cloud_firestore/cloud_firestore.dart';

class Frame {
  const Frame({
    required this.id,
    required this.name,
    required this.type,
    required this.shootingCycle,
    required this.guide,
    required this.photoCount,
    required this.memberCount,
  });

  factory Frame.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? <String, dynamic>{};

    return Frame(
      id: snapshot.id,
      name: data['name'] as String? ?? '이름 없는 프레임',
      type: data['type'] as String? ?? '개인',
      shootingCycle: data['shootingCycle'] as String? ?? '직접 설정',
      guide: data['guide'] as String? ?? '',
      photoCount: data['photoCount'] as int? ?? 0,
      memberCount: data['memberCount'] as int? ?? 1,
    );
  }

  final String id;
  final String name;
  final String type;
  final String shootingCycle;
  final String guide;
  final int photoCount;
  final int memberCount;
}
