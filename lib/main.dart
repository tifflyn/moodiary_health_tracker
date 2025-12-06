import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 添加这行
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/homescreenview.dart';
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
      'AIzaSyDkdff1oUen4H_Z9zoh-TCdW4soDUwTL70'; // 你的新密钥

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
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (authProvider.isLoggedIn) {
            return const HomeScreenView();
          } else {
            return const WelcomeScreen();
          }
        },
      ),
    );
  }
}
