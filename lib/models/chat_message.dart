class ChatMessage {
  final int? id;
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
      'id': id,
      'message': message,
      'isUser': isUser ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
      'emotionContext': emotionContext,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      message: map['message'],
      isUser: map['isUser'] == 1,
      timestamp: DateTime.parse(map['timestamp']),
      emotionContext: map['emotionContext'],
    );
  }
}