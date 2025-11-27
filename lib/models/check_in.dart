class CheckIn {
  final int? id;
  final String emoji;
  final String? diary;
  final String? title; // Add this line
  final String aiResponse;
  final DateTime timestamp;

  CheckIn({
    this.id,
    required this.emoji,
    this.diary,
    this.title, // Add this line
    required this.aiResponse,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'emoji': emoji,
      'diary': diary,
      'title': title, // Add this line
      'aiResponse': aiResponse,
      'timestamp': timestamp.toIso8601String(),
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
    );
  }
}