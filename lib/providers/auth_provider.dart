import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/daily_recommendation.dart'; // 添加这个导入
import '../services/firebase_service.dart';
import '../services/database_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel _user = UserModel.empty();
  bool _isLoggedIn = false;
  bool _isLoading = false;

  UserModel get user => _user;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    // Listen to Firebase auth state changes
    FirebaseService.instance.authStateChanges.listen((
      User? firebaseUser,
    ) async {
      if (firebaseUser != null && firebaseUser.emailVerified) {
        // User is signed in and email is verified
        try {
          final userProfile = await FirebaseService.instance.getUserProfile(
            firebaseUser.uid,
          );
          _user = userProfile;
          _isLoggedIn = true;

          // Migrate local data to Firebase on first login
          await _migrateLocalData(firebaseUser.uid);
        } catch (e) {
          debugPrint('Error loading user profile: $e');
        }
      } else {
        _isLoggedIn = false;
        _user = UserModel.empty();
      }

      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> _migrateLocalData(String userId) async {
    try {
      // Check if migration is needed by checking if user has any data in Firebase
      final emotionsSnapshot = await FirebaseService.instance
          .getEmotionLogs(userId)
          .first;

      if (emotionsSnapshot.isEmpty) {
        // No data in Firebase, migrate from local database
        final localEmotions = await DatabaseService.instance.getAllEmotions();
        final localCheckIns = await DatabaseService.instance.getAllCheckIns();
        final localChatMessages = await DatabaseService.instance
            .getChatHistory();
        final localRecommendations = await DatabaseService.instance
            .getTodayRecommendation();

        // 明确指定类型
        final List<DailyRecommendation> recommendationsList =
            localRecommendations != null ? [localRecommendations] : [];

        await FirebaseService.instance.migrateLocalDataToFirebase(
          userId,
          emotions: localEmotions,
          checkIns: localCheckIns,
          chatMessages: localChatMessages,
          recommendations: recommendationsList,
        );

        debugPrint('Local data migrated to Firebase successfully');
      }
    } catch (e) {
      debugPrint('Error migrating local data: $e');
    }
  }

  // Email sign up
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String nickname,
    required int age,
    required String gender,
    required String avatar,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // 先创建用户，获取 userCredential
      final userCredential = await FirebaseService.instance.signUpWithEmail(
        email: email,
        password: password,
        userData: UserModel(
          id: '', // 先用空字符串，创建后会被覆盖
          email: email,
          nickname: nickname,
          age: age,
          gender: gender,
          avatar: avatar,
          createdAt: DateTime.now(),
        ),
      );

      if (userCredential != null) {
        // 使用实际的用户ID更新用户数据
        final userData = UserModel(
          id: userCredential.user!.uid, // 使用 Firebase UID
          email: email,
          nickname: nickname,
          age: age,
          gender: gender,
          avatar: avatar,
          createdAt: DateTime.now(),
        );

        // 更新 Firestore 中的用户数据
        await FirebaseService.instance.updateUserProfile(
          userCredential.user!.uid,
          userData.toMap(),
        );
      }
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();

      // 重新抛出特定的错误信息
      if (e.code == 'email-already-in-use') {
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'This email is already registered. Please sign in instead.',
        );
      } else {
        rethrow;
      }

      // Note: User needs to verify email before they can sign in
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Email sign in
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await FirebaseService.instance.signInWithEmail(
        email: email,
        password: password,
      );

      // 立即检查登录状态并更新
      final currentUser = FirebaseService.instance.currentUser;
      if (currentUser != null && currentUser.emailVerified) {
        try {
          final userProfile = await FirebaseService.instance.getUserProfile(
            currentUser.uid,
          );
          _user = userProfile;
          _isLoggedIn = true;
          notifyListeners(); // 立即通知状态改变
          debugPrint(
            '✅ User signed in and state updated: ${userProfile.nickname}',
          );
        } catch (e) {
          debugPrint('Error loading user profile after sign in: $e');
        }
      }

      // Auth state listener will handle the rest (setting _isLoggedIn, etc.)
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Google sign in
  Future<void> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      await FirebaseService.instance.signInWithGoogle();

      // Auth state listener will handle the rest
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Update user profile information
  Future<void> updateUserInfo({
    String? nickname,
    int? age,
    String? gender,
    String? avatar,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (nickname != null) updates['nickname'] = nickname;
      if (age != null) updates['age'] = age;
      if (gender != null) updates['gender'] = gender;
      if (avatar != null) updates['avatar'] = avatar;

      await FirebaseService.instance.updateUserProfile(_user.id, updates);

      // Update local state
      _user = _user.copyWith(
        nickname: nickname ?? _user.nickname,
        age: age ?? _user.age,
        gender: gender ?? _user.gender,
        avatar: avatar ?? _user.avatar,
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user info: $e');
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await FirebaseService.instance.signOut();
      await DatabaseService.instance.close();

      _isLoggedIn = false;
      _user = UserModel.empty();
      notifyListeners();
    } catch (e) {
      debugPrint('Error during logout: $e');
    }
  }

  // Resend email verification
  Future<void> resendVerificationEmail() async {
    final user = FirebaseService.instance.currentUser;
    if (user != null) {
      await user.sendEmailVerification();
    }
  }

  // 发送密码重置邮件
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      _isLoading = true;
      notifyListeners();

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // For backward compatibility - keep old methods but mark as deprecated
  @Deprecated('Use signUpWithEmail instead')
  void setUserInfo(String nickname, int age) {
    // This is now handled by Firebase authentication
    debugPrint('setUserInfo is deprecated. Use signUpWithEmail instead.');
  }

  @Deprecated('Use updateUserInfo instead')
  void setNickname(String nickname) {
    updateUserInfo(nickname: nickname);
  }
}
