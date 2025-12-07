import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 添加这行
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/welcome_screen.dart';

import 'screens/homescreenview.dart';
import 'screens/email_screen.dart';

import 'services/ai_service.dart';

void main() async {
  // 确保 Flutter widgets 初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 🎯 加载环境变量（必须在 Firebase 初始化之前）
  await dotenv.load(fileName: ".env");

  // 添加 Firebase 初始化
  try {
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('❌ Firebase initialization failed: $e');
  }

  // 🎯 使用新的 Gemini Chatbot 配置
  AIService.instance.clearApiKeys();
  AIService.instance.setChatbotMode(); // 🚀 设置为 chatbot 模式

  // 🎯 使用 .env 中的新 API 密钥
  final geminiApiKey =
      dotenv.env['GEMINI_API_KEY'] ??
      'AIzaSyAmxFv_sfWkUd3B0nWhIN0Fpr87T_DCWjo'; // 你的新密钥

  AIService.instance.setGeminiApiKey(geminiApiKey);

  debugPrint(
    '🎯 Using new Gemini Chatbot with key: ${geminiApiKey.substring(0, 10)}...',
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mental Health Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isLoading) {
            debugPrint('🔄 AuthProvider is loading...');
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // 🔴 添加状态调试
          debugPrint('=== AUTH STATE ===');
          debugPrint('isLoggedIn: ${authProvider.isLoggedIn}');
          debugPrint('isLoading: ${authProvider.isLoading}');

          if (authProvider.isLoggedIn) {
            final user = authProvider.user;

            // 🔴 添加详细的调试信息
            debugPrint('=== USER PROFILE CHECK ===');
            debugPrint('User ID: ${user.id}');
            debugPrint('Email: ${user.email}');
            debugPrint(
              'Nickname: "${user.nickname}" (isEmpty: ${user.nickname.isEmpty})',
            );
            debugPrint('Age: ${user.age} (age == -1: ${user.age == -1})');
            debugPrint('Gender: ${user.gender}');
            debugPrint('Avatar: ${user.avatar}');
            debugPrint('==========================');

            // 🔴 更严格的检查条件
            final bool isProfileComplete =
                user.nickname.isNotEmpty &&
                user.nickname != 'User' &&
                user.age > 0;

            if (!isProfileComplete) {
              debugPrint('🚨 User profile incomplete, showing setup screen');

              return Scaffold(
                backgroundColor: Colors.black,
                body: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade300,
                                Colors.purple.shade300,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(
                            Icons.person_add_alt_1,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),

                        const SizedBox(height: 30),

                        const Text(
                          'Complete Your Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16),

                        Text(
                          'Email: ${user.email}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Please set up your nickname and age to personalize your experience.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 40),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              debugPrint('📱 Navigating to profile setup');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EmailScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_outline, size: 20),
                                SizedBox(width: 10),
                                Text(
                                  'Set Up Profile Now',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        TextButton(
                          onPressed: () async {
                            debugPrint('🚪 User requested logout');
                            await authProvider.logout();
                          },
                          child: const Text(
                            'Logout',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            } else {
              debugPrint('✅ User profile complete, showing home screen');
              return const HomeScreen();
            }
          } else {
            debugPrint('👋 No user logged in, showing welcome screen');
            return const WelcomeScreen();
          }
        },
      ),
    );
  }
}
