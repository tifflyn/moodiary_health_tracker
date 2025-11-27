class DailyRecommendation {
  final int? id;
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
      'completed': completed ? 1 : 0,
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
      completed: map['completed'] == 1,
    );
  }
}