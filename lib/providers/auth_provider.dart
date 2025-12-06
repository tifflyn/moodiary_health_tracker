import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/daily_recommendation.dart';
import '../services/firebase_service.dart';
import '../services/database_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel _user = UserModel.empty();
  bool _isLoggedIn = false;
  bool _isLoading = false;
  bool _hasCompletedSetup = false;
  String? _tempPassword;
  String? _pendingEmail;    // Add for auto-login
  String? _pendingPassword; // Add for auto-login

  UserModel get user => _user;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  bool get hasCompletedSetup => _hasCompletedSetup;
  String? get tempPassword => _tempPassword;
  String? get pendingEmail => _pendingEmail;    // Add getter
  String? get pendingPassword => _pendingPassword; // Add getter
  
  bool get isProfileComplete {
    
    return _user.nickname.isNotEmpty && 
           _user.nickname != 'User' && 
           _user.age > 0 &&
           _user.gender.isNotEmpty;
  }
  
  // FIXED: Add reload to get latest verification status
  bool get isEmailVerified {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    return firebaseUser?.emailVerified ?? false;
  }

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    FirebaseService.instance.authStateChanges.listen((
      User? firebaseUser,
    ) async {
      if (firebaseUser != null) {
        // IMPORTANT: Reload user to get latest verification status
        await firebaseUser.reload();
        final updatedUser = FirebaseAuth.instance.currentUser;
        
        if (updatedUser != null && updatedUser.emailVerified) {
          try {
            final userProfile = await FirebaseService.instance.getUserProfile(
              updatedUser.uid,
            );
            _user = userProfile;
            _isLoggedIn = true;
            _hasCompletedSetup = isProfileComplete;

            // Migrate local data to Firebase on first login
            await _migrateLocalData(updatedUser.uid);
          } catch (e) {
            debugPrint('Error loading user profile: $e');
            _isLoggedIn = true;
            _hasCompletedSetup = false;
          }
        } else {
          _isLoggedIn = false;
          _user = UserModel.empty();
          _hasCompletedSetup = false;
          _tempPassword = null;
        }
      } else {
        _isLoggedIn = false;
        _user = UserModel.empty();
        _hasCompletedSetup = false;
        _tempPassword = null;
      }

      _isLoading = false;
      notifyListeners();
    });
  }

  // Store credentials for auto-login after verification
  void storePendingCredentials(String email, String password) {
    _pendingEmail = email;
    _pendingPassword = password;
    notifyListeners();
  }
  
  // Clear stored credentials
  void clearPendingCredentials() {
    _pendingEmail = null;
    _pendingPassword = null;
    notifyListeners();
  }

  void setTempPassword(String password) {
    _tempPassword = password;
    notifyListeners();
  }

  void setSetupComplete(bool value) {
    _hasCompletedSetup = value;
    notifyListeners();
  }

  // Auto-login with stored credentials after email verification
  Future<bool> autoLoginWithStoredCredentials() async {
    try {
      if (_pendingEmail == null || _pendingPassword == null) {
        debugPrint('⚠️ No stored credentials for auto-login');
        return false;
      }
      
      debugPrint('🔐 Attempting auto-login with stored credentials');
      
      // Sign in with stored credentials
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _pendingEmail!,
        password: _pendingPassword!,
      );
      
      // Force reload to get latest user data
      final user = FirebaseAuth.instance.currentUser;
      await user?.reload();
      
      // Get user profile from Firestore
      if (user != null && user.emailVerified) {
        final userProfile = await FirebaseService.instance.getUserProfile(
          user.uid,
        );
        _user = userProfile;
        _isLoggedIn = true;
        _hasCompletedSetup = isProfileComplete;
        _tempPassword = _pendingPassword; // Keep for setup screens
        
        debugPrint('✅ Auto-login successful');
        
        // Clear stored credentials after successful login
        clearPendingCredentials();
        
        notifyListeners();
        return true;
      }
      
      return false;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Auto-login Firebase error: ${e.code} - ${e.message}');
      clearPendingCredentials();
      return false;
    } catch (e) {
      debugPrint('❌ Auto-login error: $e');
      clearPendingCredentials();
      return false;
    }
  }

  Future<void> completeProfileSetup({
    required String nickname,
    required int age,
    required String gender,
    String avatar = 'default',
  }) async {
    try {
      await updateUserInfo(
        nickname: nickname,
        age: age,
        gender: gender,
        avatar: avatar,
      );
      
      _hasCompletedSetup = true;
      _tempPassword = null; // Clear temp password after setup
      notifyListeners();
    } catch (e) {
      debugPrint('Error completing profile setup: $e');
      rethrow;
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? nickname,
    int? age,
    String? gender,
    String avatar = 'default',
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      _tempPassword = password;

      final userCredential = await FirebaseService.instance.signUpWithEmail(
        email: email,
        password: password,
        userData: UserModel(
          id: '',
          email: email,
          nickname: nickname ?? '',
          age: age ?? -1,
          gender: gender ?? '',
          avatar: avatar,
          createdAt: DateTime.now(),
        ),
      );

      if (userCredential != null) {
        final userData = UserModel(
          id: userCredential.user!.uid,
          email: email,
          nickname: nickname ?? '',
          age: age ?? -1,
          gender: gender ?? '',
          avatar: avatar,
          createdAt: DateTime.now(),
        );

        await FirebaseService.instance.updateUserProfile(
          userCredential.user!.uid,
          userData.toMap(),
        );
        
        _user = userData;
        _isLoggedIn = true;
        _hasCompletedSetup = isProfileComplete;
        
        debugPrint('✅ User signed up. Profile complete: $_hasCompletedSetup');
      }
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _tempPassword = null;
      notifyListeners();

      if (e.code == 'email-already-in-use') {
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'This email is already registered. Please sign in instead.',
        );
      } else {
        rethrow;
      }
    } catch (e) {
      _isLoading = false;
      _tempPassword = null;
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Simplified signup for email only
  Future<void> signUpWithEmailOnly({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Store credentials for auto-login after verification
      storePendingCredentials(email, password);
      
      // Store temp password for setup flow
      _tempPassword = password;

      final userCredential = await FirebaseService.instance.signUpWithEmail(
        email: email,
        password: password,
        userData: UserModel(
          id: '',
          email: email,
          nickname: '',
          age: -1,
          gender: '',
          avatar: 'default',
          createdAt: DateTime.now(),
        ),
      );

      if (userCredential != null) {
        final userData = UserModel(
          id: userCredential.user!.uid,
          email: email,
          nickname: '',
          age: -1,
          gender: '',
          avatar: 'default',
          createdAt: DateTime.now(),
        );

        await FirebaseService.instance.updateUserProfile(
          userCredential.user!.uid,
          userData.toMap(),
        );
        
        _user = userData;
        _isLoggedIn = true;
        _hasCompletedSetup = false;
        
        debugPrint('✅ User signed up with email only. Setup needed.');
      }
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _tempPassword = null;
      clearPendingCredentials();
      notifyListeners();

      if (e.code == 'email-already-in-use') {
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'This email is already registered. Please sign in instead.',
        );
      } else {
        rethrow;
      }
    } catch (e) {
      _isLoading = false;
      _tempPassword = null;
      clearPendingCredentials();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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

      _user = _user.copyWith(
        nickname: nickname ?? _user.nickname,
        age: age ?? _user.age,
        gender: gender ?? _user.gender,
        avatar: avatar ?? _user.avatar,
      );
      
      _hasCompletedSetup = isProfileComplete;

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user info: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await FirebaseService.instance.signOut();
      await DatabaseService.instance.close();

      _isLoggedIn = false;
      _user = UserModel.empty();
      _hasCompletedSetup = false;
      _tempPassword = null;
      clearPendingCredentials();
      notifyListeners();
    } catch (e) {
      debugPrint('Error during logout: $e');
    }
  }

  // Force refresh auth state - useful after email verification
  Future<void> refreshAuthState() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        final updatedUser = FirebaseAuth.instance.currentUser;
        
        if (updatedUser != null && updatedUser.emailVerified) {
          final userProfile = await FirebaseService.instance.getUserProfile(
            updatedUser.uid,
          );
          _user = userProfile;
          _isLoggedIn = true;
          _hasCompletedSetup = isProfileComplete;
        } else {
          _isLoggedIn = false;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing auth state: $e');
    }
  }

  Future<void> _migrateLocalData(String userId) async {
    try {
      final emotionsSnapshot = await FirebaseService.instance
          .getEmotionLogs(userId)
          .first;

      if (emotionsSnapshot.isEmpty) {
        final localEmotions = await DatabaseService.instance.getAllEmotions();
        final localCheckIns = await DatabaseService.instance.getAllCheckIns();
        final localChatMessages = await DatabaseService.instance
            .getChatHistory();
        final localRecommendations = await DatabaseService.instance
            .getTodayRecommendation();

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

      // Force reload to get latest verification status
      final currentUser = FirebaseAuth.instance.currentUser;
      await currentUser?.reload();
      
      if (currentUser != null && currentUser.emailVerified) {
        try {
          final userProfile = await FirebaseService.instance.getUserProfile(
            currentUser.uid,
          );
          _user = userProfile;
          _isLoggedIn = true;
          _hasCompletedSetup = isProfileComplete;
          notifyListeners();
          debugPrint(
            '✅ User signed in. Profile complete: $_hasCompletedSetup',
          );
        } catch (e) {
          debugPrint('Error loading user profile after sign in: $e');
        }
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      await FirebaseService.instance.signInWithGoogle();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> resendVerificationEmail() async {
    final user = FirebaseService.instance.currentUser;
    if (user != null) {
      await user.sendEmailVerification();
    }
  }

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

  @Deprecated('Use signUpWithEmail instead')
  void setUserInfo(String nickname, int age) {
    debugPrint('setUserInfo is deprecated. Use signUpWithEmail instead.');
  }

  @Deprecated('Use updateUserInfo instead')
  void setNickname(String nickname) {
    updateUserInfo(nickname: nickname);
  }
}