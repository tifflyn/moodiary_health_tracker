import 'package:cloud_firestore/cloud_firestore.dart';

class EmotionLog {
  final String? id;
  final String emotion;
  final int intensity;
  final String note;
  final DateTime dateTime;

  EmotionLog({
    this.id,
    required this.emotion,
    required this.intensity,
    required this.note,
    required this.dateTime,
  });

  // Convert EmotionLog to Map for database
  Map<String, dynamic> toMap() {
    return {
      // 不存储 id 字段到 Firestore，因为它是文档ID本身
      'emotion': emotion,
      'intensity': intensity,
      'note': note,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  // Convert Map to EmotionLog
  factory EmotionLog.fromMap(Map<String, dynamic> map) {
    return EmotionLog(
      id: map['id'],
      emotion: map['emotion'],
      intensity: map['intensity'],
      note: map['note'],
      dateTime: DateTime.parse(map['dateTime']),
    );
  }

  // 添加一个辅助方法，用于从 Firestore 文档创建 EmotionLog
  factory EmotionLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EmotionLog(
      id: doc.id, // 使用 Firestore 文档ID
      emotion: data['emotion'],
      intensity: data['intensity'],
      note: data['note'],
      dateTime: DateTime.parse(data['dateTime']),
    );
  }
}
