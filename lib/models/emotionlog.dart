class EmotionLog {
  final int? id;
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
      'id': id,
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
}