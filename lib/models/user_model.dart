class UserModel {
  final String uid;
  String nickname;
  String gender;
  String avatar;
  int age; // 添加年龄属性

  UserModel({
    required this.uid,
    required this.nickname,
    this.age = 0, // 默认值为 0
    this.gender = 'Not specified',
    this.avatar = 'default',
  });

  @override
  String toString() {
    return 'User(uid: $uid, nickname: $nickname, age: $age, gender: $gender, avatar: $avatar)';
  }
}
