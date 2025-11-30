class UserModel {
  final String id;
  final String email;
  final String nickname;
  final String gender;
  final String avatar;
  final int age;
  final DateTime createdAt;

  // 保持向后兼容的 uid getter
  String get uid => id;

  UserModel({
    required this.id,
    required this.email,
    required this.nickname,
    required this.age,
    this.gender = 'Prefer not to say',
    this.avatar = 'default',
    required this.createdAt,
  });

  // 向后兼容的构造函数
  factory UserModel.fromLegacy({
    required String uid,
    required String nickname,
    int age = 0,
    String gender = 'Not specified',
    String avatar = 'default',
  }) {
    return UserModel(
      id: uid,
      email: '', // 空 email
      nickname: nickname,
      age: age,
      gender: gender,
      avatar: avatar,
      createdAt: DateTime.now(),
    );
  }

  // Empty user factory
  factory UserModel.empty() {
    return UserModel(
      id: '',
      email: '',
      nickname: '',
      age: 0,
      gender: 'Prefer not to say',
      avatar: 'default',
      createdAt: DateTime.now(),
    );
  }

  // Copy with method
  UserModel copyWith({
    String? id,
    String? email,
    String? nickname,
    int? age,
    String? gender,
    String? avatar,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // To map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'nickname': nickname,
      'age': age,
      'gender': gender,
      'avatar': avatar,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // From map for Firestore
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      nickname: map['nickname'] ?? '',
      age: map['age'] ?? 0,
      gender: map['gender'] ?? 'Prefer not to say',
      avatar: map['avatar'] ?? 'default',
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, nickname: $nickname, age: $age, gender: $gender, avatar: $avatar, createdAt: $createdAt)';
  }
}
