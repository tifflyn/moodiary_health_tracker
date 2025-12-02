import 'package:cloud_firestore/cloud_firestore.dart';

class DailyRecommendation {
  final String? id; // 改为 String? 以存储 Firestore 文档ID
  final String title;
  final String description;
  final String category; // nature, art, food, music, exercise
  final String imageUrl;
  final DateTime date;
  final bool completed;

  DailyRecommendation({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.date,
    this.completed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'date': date.toIso8601String(),
      'completed': completed,
    };
  }

  factory DailyRecommendation.fromMap(Map<String, dynamic> map) {
    return DailyRecommendation(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      category: map['category'],
      imageUrl: map['imageUrl'],
      date: DateTime.parse(map['date']),
      completed: map['completed'] ?? false,
    );
  }

  // 添加 Firestore 工厂构造函数
  factory DailyRecommendation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyRecommendation(
      id: doc.id,
      title: data['title'],
      description: data['description'],
      category: data['category'],
      imageUrl: data['imageUrl'],
      date: DateTime.parse(data['date']),
      completed: data['completed'] ?? false,
    );
  }
}
