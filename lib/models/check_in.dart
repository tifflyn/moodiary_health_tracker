import 'package:cloud_firestore/cloud_firestore.dart';

class CheckIn {
  final String? id; // 改为 String? 以存储 Firestore 文档ID
  final String emoji;
  final String? diary;
  final String? title; // Add this line
  final String aiResponse;
  final DateTime timestamp;
  final String emotion;

  CheckIn({
    this.id,
    required this.emoji,
    this.diary,
    this.title, // Add this line
    required this.aiResponse,
    required this.timestamp,
    required this.emotion,
  });

  Map<String, dynamic> toMap() {
    return {
      // 不存储 id 字段到 Firestore，因为它是文档ID本身
      'emoji': emoji,
      'diary': diary,
      'title': title, // Add this line
      'aiResponse': aiResponse,
      'timestamp': timestamp.toIso8601String(),
      'emotion': emotion,
    };
  }

  factory CheckIn.fromMap(Map<String, dynamic> map) {
    return CheckIn(
      id: map['id'],
      emoji: map['emoji'],
      diary: map['diary'],
      title: map['title'], // Add this line
      aiResponse: map['aiResponse'],
      timestamp: DateTime.parse(map['timestamp']),
      emotion: map['emotion'] ?? 'neutral',
    );
  }

  // 添加一个辅助方法，用于从 Firestore 文档创建 CheckIn
  factory CheckIn.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CheckIn(
      id: doc.id, // 使用 Firestore 文档ID
      emoji: data['emoji'],
      diary: data['diary'],
      title: data['title'],
      aiResponse: data['aiResponse'],
      timestamp: DateTime.parse(data['timestamp']),
      emotion: data['emotion'] ?? 'neutral',
    );
  }
}
