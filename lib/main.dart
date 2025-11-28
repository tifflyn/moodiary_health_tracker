import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 导入所有依赖
import 'providers/auth_provider.dart'; // 我们马上就要创建或更新它
import 'screens/welcome_screen.dart';
import 'screens/homescreen.dart';
import 'services/ai_service.dart'; // 保持您原有的 AI 服务导入

void main() {
  // 确保 Flutter widgets 初始化
  WidgetsFlutterBinding.ensureInitialized();

  // IMPORTANT: Clear any old API keys and set Gemini
  // 我们保留您的 AI 初始化代码
  AIService.instance.clearApiKeys();
  AIService.instance.setProvider('gemini');
  AIService.instance.setGeminiApiKey('AIzaSyA0QiOoXJmIAsKB-KFfHG6FE0axa1eJdSc');

  runApp(
    // 1. 使用 ChangeNotifierProvider 包装应用根部，注入 AuthProvider
    ChangeNotifierProvider(
      create: (context) => AuthProvider(), // 创建 AuthProvider 实例
      child: const MyApp(), // 定义 MyApp Widget
    ),
  );
}

// 应用程序的主 Widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mental Health Tracker', // 使用您提供的标题
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      // 关键导航逻辑：使用 Consumer 监听 AuthProvider 的状态
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // *** 重要的判断逻辑：***
          // 检查用户是否已完成设置（即是否已登录）
          if (authProvider.isLoggedIn) {
            // 如果已登录/设置完成，显示主页
            return const HomeScreen();
          } else {
            // 如果未登录/未完成设置，显示欢迎页
            return const WelcomeScreen();
          }
        },
      ),
    );
  }
}
