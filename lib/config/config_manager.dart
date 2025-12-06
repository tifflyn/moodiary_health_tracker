import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConfigManager {
  static bool _isInitialized = false;

  // Initialize configuration
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load environment variables
      await dotenv.load(fileName: ".env");

      // Validate required keys exist
      await _validateRequiredKeys();

      _isInitialized = true;
      print("✅ Configuration loaded successfully");
    } catch (e) {
      print("❌ Failed to load configuration: $e");
      rethrow;
    }
  }

  // Validate that all required keys are present
  static Future<void> _validateRequiredKeys() async {
    final requiredKeys = ['AIzaSyDCD6kBoBUxVvq0sigKWF2IOmebvdDXYXQ'];
    final missingKeys = <String>[];

    for (final key in requiredKeys) {
      final value = dotenv.get(key, fallback: '');
      if (value.isEmpty || value == 'AIzaSyDCD6kBoBUxVvq0sigKWF2IOmebvdDXYXQ') {
        missingKeys.add(key);
      }
    }

    if (missingKeys.isNotEmpty) {
      throw Exception(
        'Missing required environment variables: ${missingKeys.join(', ')}\n'
        'Please copy .env.example to .env and add your keys.',
      );
    }
  }

  // Get API key securely
  static String getGeminiApiKey() {
    if (!_isInitialized) {
      throw Exception(
        'ConfigManager not initialized. Call initialize() first.',
      );
    }

    final key = dotenv.get('AIzaSyDCD6kBoBUxVvq0sigKWF2IOmebvdDXYXQ');

    // Additional validation
    if (key.isEmpty) {
      throw Exception('AIzaSyDCD6kBoBUxVvq0sigKWF2IOmebvdDXYXQ');
    }

    if (key.contains('AIzaSyDCD6kBoBUxVvq0sigKWF2IOmebvdDXYXQ')) {
      throw Exception('GEMINI_API_KEY is still using placeholder value');
    }

    // Mask key in logs (shows only first 10 chars)
    final maskedKey = key.length > 10 ? '${key.substring(0, 10)}...' : '***';
    print('🔑 Using Gemini API Key: $maskedKey');

    return key;
  }

  // Get other config values
  static String getAppName() => dotenv.get('Moodiary', fallback: 'Flutter App');
  static bool isDebugMode() =>
      dotenv.get('DEBUG_MODE', fallback: 'true') == 'true';
}
