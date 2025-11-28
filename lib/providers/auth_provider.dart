import 'package:flutter/material.dart';
import '../models/user_model.dart'; // 导入我们刚刚定义的模型

class AuthProvider extends ChangeNotifier {
  // 存储当前登录的用户信息，初始为 null
  UserModel? _user;

  // 暴露给外部的 User Getter (只读)
  UserModel get user {
    if (_user == null) {
      // 这是一个安全措施，理论上只有 isLoggedIn 为 true 时才会被访问
      throw Exception("User is not logged in!");
    }
    return _user!;
  }

  // 暴露给外部的登录状态 Getter (核心判断逻辑)
  bool get isLoggedIn => _user != null;

  // 1. 模拟登录/设置完成 - 更新方法以包含年龄
  void setUserInfo(String nickname, int age) {
    _user = UserModel(
      uid: DateTime.now().millisecondsSinceEpoch.toString(), // 简单的模拟 uid
      nickname: nickname,
      age: age, // 添加年龄参数
    );
    // 通知所有监听者（如 main.dart 中的 Consumer）状态已更改
    notifyListeners();

    debugPrint("User setup complete! Nickname: $nickname, Age: $age");
  }

  // 保持向后兼容的旧方法（可选）
  void setNickname(String nickname) {
    setUserInfo(nickname, 0); // 默认年龄为 0
  }

  // 2. 模拟登出功能 (可选，但推荐)
  void logout() {
    _user = null;
    notifyListeners();
    debugPrint("User logged out.");
  }

  // 3. 更新用户信息的方法（用于编辑昵称、年龄或性别）
  void updateUserInfo({
    String? nickname,
    int? age,
    String? gender,
    String? avatar,
  }) {
    if (_user != null) {
      _user = UserModel(
        uid: _user!.uid, // 保持相同的 UID
        nickname: nickname ?? _user!.nickname,
        age: age ?? _user!.age,
        gender: gender ?? _user!.gender, // 添加性别更新
        avatar: avatar ?? _user!.avatar,
      );
      notifyListeners();
      debugPrint(
        "User info updated! Nickname: ${_user!.nickname}, Age: ${_user!.age}, Gender: ${_user!.gender}",
      );
    }
  }

  // 未来：添加持久化逻辑 (例如使用 SharedPreferences 来存储登录状态)
  // Future<void> loadUserState() async { ... }
}
