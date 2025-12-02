import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String? id;
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final String? emotionContext;

  ChatMessage({
    this.id,
    required this.message,
    required this.isUser,
    required this.timestamp,
    this.emotionContext,
  });

  Map<String, dynamic> toMap() {
    return {
      // 不存储 id 字段到 Firestore，因为它是文档ID本身
      'message': message,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'emotionContext': emotionContext,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      message: map['message'],
      isUser: map['isUser'] ?? false,
      timestamp: DateTime.parse(map['timestamp']),
      emotionContext: map['emotionContext'],
    );
  }

  // 添加 Firestore 工厂构造函数
  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id, // 使用 Firestore 文档ID
      message: data['message'],
      isUser: data['isUser'] ?? false,
      timestamp: DateTime.parse(data['timestamp']),
      emotionContext: data['emotionContext'],
    );
  }
}
