import 'package:flutter/material.dart';
import 'screens/homescreen.dart';
import 'services/ai_service.dart';


void main() {
  // IMPORTANT: Clear any old API keys and set Gemini
  // OPTION 1: Use Google Gemini API (recommended - free tier available)
  // Get your API key from: https://aistudio.google.com/app/apikey
  AIService.instance.clearApiKeys(); // Clear any old keys first
  AIService.instance.setProvider('gemini'); // Set provider FIRST
  AIService.instance.setGeminiApiKey('AIzaSyA0QiOoXJmIAsKB-KFfHG6FE0axa1eJdSc');
  
  // OPTION 2: Use OpenAI API (requires valid API key with credits)
  // If you get "quota exceeded" error, add credits at: https://platform.openai.com/account/billing
  // AIService.instance.setProvider('openai');
  // AIService.instance.setOpenAiApiKey('your-api-key-here');
  
  // OPTION 3: Use enhanced local AI (no API key needed, no costs, works offline)
  // This provides intelligent, context-aware responses based on your emotion history
  // AIService.instance.setProvider('local');
  
  runApp(const MyApp());
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
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}