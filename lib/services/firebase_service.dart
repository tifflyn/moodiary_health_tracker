import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/emotionlog.dart';
import '../models/chat_message.dart';
import '../models/check_in.dart';
import '../models/daily_recommendation.dart';
import '../models/user_model.dart';

class FirebaseService {
  static final FirebaseService instance = FirebaseService._init();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseService._init();

  // Auth methods
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Email sign up
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    required UserModel userData,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Send email verification
      await userCredential.user!.sendEmailVerification();

      // Save user profile to Firestore
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userData.toMap());

      return userCredential;
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  // Email sign in
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      // Check if email is verified
      if (!userCredential.user!.emailVerified) {
        await _auth.signOut();
        throw Exception('Please verify your email before signing in');
      }

      return userCredential;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  // Google sign in
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw Exception('Google sign in cancelled');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Check if user exists in Firestore, if not create profile
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        final newUser = UserModel(
          id: userCredential.user!.uid,
          email: userCredential.user!.email!,
          nickname: userCredential.user!.displayName ?? 'User',
          avatar: 'default',
          age: 0,
          gender: 'Prefer not to say',
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(newUser.toMap());
      }

      return userCredential;
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }

  // User profile management
  Future<UserModel> getUserProfile(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    } else {
      // Create default profile if doesn't exist
      final defaultUser = UserModel(
        id: userId,
        email: _auth.currentUser?.email ?? '',
        nickname: 'User',
        avatar: 'default',
        age: 0,
        gender: 'Prefer not to say',
        createdAt: DateTime.now(),
      );
      await _firestore.collection('users').doc(userId).set(defaultUser.toMap());
      return defaultUser;
    }
  }

  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    await _firestore.collection('users').doc(userId).update(updates);
  }

  // Emotion logs
  Future<void> addEmotionLog(String userId, EmotionLog log) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('emotions')
        .add(log.toMap());
  }

  Stream<List<EmotionLog>> getEmotionLogs(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('emotions')
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return EmotionLog.fromMap(data);
          }).toList(),
        );
  }

  Future<List<EmotionLog>> getEmotionsForDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('emotions')
        .where('dateTime', isGreaterThanOrEqualTo: start)
        .where('dateTime', isLessThanOrEqualTo: end)
        .orderBy('dateTime')
        .get();

    return snapshot.docs.map((doc) => EmotionLog.fromMap(doc.data())).toList();
  }

  Future<void> deleteEmotion(String userId, String emotionId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('emotions')
        .doc(emotionId)
        .delete();
  }

  // Check-ins
  Future<void> addCheckIn(String userId, CheckIn checkIn) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('check_ins')
        .add(checkIn.toMap());
  }

  Future<void> updateCheckIn(
    String userId,
    String checkInId,
    CheckIn checkIn,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('check_ins')
        .doc(checkInId)
        .update(checkIn.toMap());
  }

  Stream<List<CheckIn>> getCheckIns(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('check_ins')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // Include document ID
            return CheckIn.fromMap(data);
          }).toList(),
        );
  }

  Future<List<CheckIn>> getRecentCheckIns(String userId, {int days = 7}) async {
    final since = DateTime.now().subtract(Duration(days: days));
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('check_ins')
        .where('timestamp', isGreaterThan: since)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return CheckIn.fromMap(data);
    }).toList();
  }

  // Chat messages
  Future<void> addChatMessage(String userId, ChatMessage message) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('chat_messages')
        .add(message.toMap());
  }

  Stream<List<ChatMessage>> getChatMessages(String userId, {int limit = 50}) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('chat_messages')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return ChatMessage.fromMap(data);
          }).toList(),
        );
  }

  // Daily recommendations
  Future<void> addDailyRecommendation(
    String userId,
    DailyRecommendation recommendation,
  ) async {
    // 将 DateTime 转换为字符串格式的日期
    final dateStr =
        '${recommendation.date.year}-${recommendation.date.month.toString().padLeft(2, '0')}-${recommendation.date.day.toString().padLeft(2, '0')}';

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('daily_recommendations')
        .doc(dateStr)
        .set(recommendation.toMap());
  }

  Future<DailyRecommendation?> getTodayRecommendation(String userId) async {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('daily_recommendations')
        .doc(todayStr)
        .get();

    return doc.exists ? DailyRecommendation.fromMap(doc.data()!) : null;
  }

  Future<void> markRecommendationCompleted(String userId, String date) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('daily_recommendations')
        .doc(date)
        .update({'completed': true});
  }

  // Data migration from local to Firebase
  Future<void> migrateLocalDataToFirebase(
    String userId, {
    required List<EmotionLog> emotions,
    required List<CheckIn> checkIns,
    required List<ChatMessage> chatMessages,
    required List<DailyRecommendation> recommendations,
  }) async {
    // Migrate emotions
    for (final emotion in emotions) {
      await addEmotionLog(userId, emotion);
    }

    // Migrate check-ins
    for (final checkIn in checkIns) {
      await addCheckIn(userId, checkIn);
    }

    // Migrate chat messages
    for (final message in chatMessages) {
      await addChatMessage(userId, message);
    }

    // Migrate recommendations
    for (final recommendation in recommendations) {
      await addDailyRecommendation(userId, recommendation);
    }
  }

  // Utility method to get document ID from snapshot
  String getDocId(QueryDocumentSnapshot doc) => doc.id;
}
