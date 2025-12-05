import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class EmotionLog {
  String? id;   //make sure this is nullable
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

  factory EmotionLog.fromFirestore(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // 处理 dateTime 字段 - 它可能是字符串或 Timestamp
    DateTime parsedDateTime;
    
    try {
      if (data['dateTime'] is Timestamp) {
        // 如果是 Firestore Timestamp
        parsedDateTime = (data['dateTime'] as Timestamp).toDate();
      } else if (data['dateTime'] is String) {
        // 如果是 ISO 字符串
        parsedDateTime = DateTime.parse(data['dateTime'] as String);
      } else {
        // 如果都不是，使用当前时间
        parsedDateTime = DateTime.now();
        if (kDebugMode) {
        debugPrint('⚠️  Unexpected dateTime format: ${data['dateTime']}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
      print('❌ Error parsing dateTime: $e, using current time');
      }
      parsedDateTime = DateTime.now();
    }
    
    return EmotionLog(
      id: doc.id, // 使用 Firestore 文档ID
      emotion: data['emotion'] as String,
      intensity: data['intensity'] as int,
      note: data['note'] as String,
      dateTime: parsedDateTime,
    );
  }

  // 可选: 添加 toString() 方法用于调试
  @override
  String toString() {
    return 'EmotionLog{id: $id, emotion: $emotion, intensity: $intensity, note: $note, dateTime: $dateTime}';
  }

}
