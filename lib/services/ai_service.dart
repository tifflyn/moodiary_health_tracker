// lib/services/ai_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import '../models/emotionlog.dart';

class AIService {
  static final AIService instance = AIService._init();
  AIService._init() {
    _initGemini();
  }

  // ⭐ 新增：你新项目的Gemini模型
  late GenerativeModel _geminiModel;
  final List<Content> _chatHistory = [];

  // 🚀 新项目的系统指令 - 改为英语！
  static const String _chatbotSystemInstruction = '''
    You are a warm, humorous, and slightly emotional friend-style AI chatbot.
    Your responses should be short, friendly, and include appropriate emojis (e.g., 😊, 😂, 🤔).
    Avoid using overly formal or mechanical language.
    Remember, you are a fun friend, not just a tool.
    
    As a mental health companion, also:
    1. Provide supportive, non-judgmental responses
    2. Respond with warmth, empathy, and practical coping strategies
    3. Keep responses concise (2-3 paragraphs)
    4. Use appropriate emojis to convey warmth
    5. Provide personalized responses based on the user's emotional context
  ''';

  // ⭐ 保留原有的API配置
  static const String claudeApiUrl = 'https://api.anthropic.com/v1/messages';
  static const String openAiApiUrl =
      'https://api.openai.com/v1/chat/completions';
  static const String geminiApiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  String? _claudeApiKey;
  String? _openAiApiKey;
  String? _geminiApiKey;
  String _provider = 'gemini_chatbot'; // ⭐ 新增一个专门给chatbot的模式
  String? _lastApiError;

  String? get lastApiError => _lastApiError;

  void _initGemini() {
    try {
      // 🎯 使用新项目的 API 密钥
      final apiKey =
          dotenv.env['GEMINI_API_KEY'] ??
          'AIzaSyDCD6kBoBUxVvq0sigKWF2IOmebvdDXYXQ'; // 你的新密钥

      _geminiModel = GenerativeModel(
        model: 'gemini-2.5-flash', // 使用新项目的模型
        apiKey: apiKey,
      );

      // 初始化聊天历史
      _chatHistory.clear();
      _chatHistory.add(Content('user', [TextPart(_chatbotSystemInstruction)]));

      debugPrint('✅ English Gemini Chatbot initialized successfully');
    } catch (e) {
      debugPrint('❌ Gemini initialization failed: $e');
    }
  }

  // ⭐ 新增：专门给chatbot用的方法（用你调好的模型）
  Future<String> sendChatbotMessage(String message) async {
    debugPrint('=== Using New Gemini Chatbot ===');

    final userContent = Content('user', [TextPart(message)]);
    _chatHistory.add(userContent);

    try {
      final response = await _geminiModel.generateContent(_chatHistory);
      final geminiText =
          response.text ?? 'I\'m here to listen. How can I help you today? 😊';

      _chatHistory.add(Content('model', [TextPart(geminiText)]));
      _lastApiError = null;

      return geminiText;
    } catch (e) {
      if (_chatHistory.isNotEmpty) {
        _chatHistory.removeLast();
      }
      _lastApiError = e.toString();
      debugPrint('Gemini Chatbot error: $e');

      // 降级到原有的规则回应
      return _generateRuleBasedResponse(message, null);
    }
  }

  // ⭐ 原有的方法保持不变（给check-in等其他功能用）
  void setClaudeApiKey(String key) {
    _claudeApiKey = key;
    if (key.isNotEmpty) _provider = 'claude';
  }

  void setOpenAiApiKey(String key) {
    _openAiApiKey = key;
    if (key.isNotEmpty && _provider == 'local') {
      _provider = 'openai';
    }
  }

  void setGeminiApiKey(String key) {
    _geminiApiKey = key;
    if (key.isNotEmpty) {
      _provider = 'gemini';
    }
  }

  // ⭐ 新增：设置chatbot模式
  void setChatbotMode() {
    _provider = 'gemini_chatbot';
    debugPrint('Switched to Gemini Chatbot mode');
  }

  void setProvider(String provider) {
    _provider = provider;
    debugPrint('AI Provider set to: $_provider');
  }

  void clearApiKeys() {
    _claudeApiKey = null;
    _openAiApiKey = null;
    _geminiApiKey = null;
    _lastApiError = null;
    debugPrint('All API keys cleared');
  }

  void setApiKey(String key) {
    setGeminiApiKey(key);
  }

  // ⭐ 原有的generateTherapistResponse方法（现在会调用新的chatbot）
  Future<String> generateTherapistResponse(
    String userMessage,
    List<EmotionLog>? recentEmotions,
  ) async {
    debugPrint('=== AI Service Call ===');
    debugPrint('Current provider: $_provider');

    // 🚀 如果是chatbot模式，使用新的Gemini模型
    if (_provider == 'gemini_chatbot') {
      return await sendChatbotMessage(userMessage);
    }

    // 原有的逻辑保持不变（给其他功能用）
    if (_provider == 'local' ||
        (_provider == 'claude' &&
            (_claudeApiKey == null || _claudeApiKey!.isEmpty)) ||
        (_provider == 'openai' &&
            (_openAiApiKey == null || _openAiApiKey!.isEmpty)) ||
        (_provider == 'gemini' &&
            (_geminiApiKey == null || _geminiApiKey!.isEmpty))) {
      debugPrint('Using local rule-based responses');
      return _generateRuleBasedResponse(userMessage, recentEmotions);
    }

    try {
      final emotionContext = recentEmotions != null && recentEmotions.isNotEmpty
          ? 'Recent emotions: ${recentEmotions.map((e) => '${e.emotion} (intensity: ${e.intensity})').join(', ')}'
          : 'No recent emotion data available.';

      if (_provider == 'gemini' &&
          _geminiApiKey != null &&
          _geminiApiKey!.isNotEmpty) {
        debugPrint('Using old Gemini API');
        return await _generateGeminiResponse(userMessage, emotionContext);
      } else if (_provider == 'claude' &&
          _claudeApiKey != null &&
          _claudeApiKey!.isNotEmpty) {
        return await _generateClaudeResponse(userMessage, emotionContext);
      } else if (_provider == 'openai' &&
          _openAiApiKey != null &&
          _openAiApiKey!.isNotEmpty) {
        return await _generateOpenAiResponse(userMessage, emotionContext);
      } else {
        debugPrint('No matching provider found, using local rule-based');
        return _generateRuleBasedResponse(userMessage, recentEmotions);
      }
    } catch (e) {
      debugPrint('Unexpected AI error, using fallback: $e');
      return _generateRuleBasedResponse(userMessage, recentEmotions);
    }
  }

  // ⭐ 原有的API方法保持不变
  Future<String> _generateClaudeResponse(
    String userMessage,
    String emotionContext,
  ) async {
    final response = await http.post(
      Uri.parse(claudeApiUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _claudeApiKey!,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-sonnet-4-20250514',
        'max_tokens': 500,
        'messages': [
          {
            'role': 'user',
            'content':
                '''You are an empathetic mental health companion. Provide supportive, non-judgmental responses.

Context: $emotionContext

User message: $userMessage

Respond with warmth, empathy, and practical coping strategies. Keep responses concise (2-3 paragraphs).''',
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['content'][0]['text'];
    } else {
      throw Exception('Claude API error: ${response.statusCode}');
    }
  }

  Future<String> _generateOpenAiResponse(
    String userMessage,
    String emotionContext,
  ) async {
    debugPrint('Calling OpenAI API...');
    debugPrint(
      'API Key present: ${_openAiApiKey != null && _openAiApiKey!.isNotEmpty}',
    );

    try {
      final requestBody = {
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are an empathetic mental health companion. Provide supportive, non-judgmental responses with warmth, empathy, and practical coping strategies. Keep responses concise (2-3 paragraphs).',
          },
          {
            'role': 'user',
            'content':
                '''Context: $emotionContext

User message: $userMessage

Please provide a supportive, empathetic response.''',
          },
        ],
        'max_tokens': 500,
        'temperature': 0.7,
      };

      debugPrint('Sending request to OpenAI...');
      final response = await http
          .post(
            Uri.parse(openAiApiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_openAiApiKey',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Request timeout: OpenAI API took too long to respond',
              );
            },
          );

      debugPrint('OpenAI response status: ${response.statusCode}');
      debugPrint(
        'OpenAI response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['choices'] != null &&
            data['choices'].isNotEmpty &&
            data['choices'][0]['message'] != null &&
            data['choices'][0]['message']['content'] != null) {
          final content = data['choices'][0]['message']['content'];
          debugPrint('OpenAI API success! Response length: ${content.length}');
          return content;
        } else {
          debugPrint('Invalid response format: ${data.toString()}');
          throw Exception(
            'Invalid response format from OpenAI API: Missing choices or content',
          );
        }
      } else {
        // Parse error response
        String errorMessage = 'OpenAI API error: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['error'] != null) {
            final error = errorData['error'];
            errorMessage =
                'OpenAI API error: ${error['message'] ?? error['type'] ?? errorMessage}';
            debugPrint('OpenAI API error details: $error');
          }
        } catch (parseError) {
          debugPrint('Could not parse error response: $parseError');
          debugPrint('Raw response: ${response.body}');
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('OpenAI API exception: $e');
      // Re-throw with more context
      final errorStr = e.toString();
      if (errorStr.contains('SocketException') ||
          errorStr.contains('Failed host lookup') ||
          errorStr.contains('Network is unreachable')) {
        throw Exception('Network error: Please check your internet connection');
      } else if (errorStr.contains('401') ||
          errorStr.contains('Unauthorized') ||
          errorStr.contains('Invalid API key')) {
        throw Exception(
          'API key error: Invalid or expired API key. Please check your OpenAI API key in main.dart',
        );
      } else if (errorStr.contains('429') || errorStr.contains('rate limit')) {
        throw Exception(
          'Rate limit exceeded: Please wait a moment and try again',
        );
      } else if (errorStr.contains('quota') ||
          errorStr.contains('insufficient_quota') ||
          errorStr.contains('exceeded')) {
        throw Exception(
          'Quota exceeded: Your OpenAI account has run out of credits. Please add billing/credits to your OpenAI account at https://platform.openai.com/account/billing or switch to local AI mode.',
        );
      } else if (errorStr.contains('timeout')) {
        throw Exception(
          'Request timeout: OpenAI API took too long to respond. Please try again.',
        );
      } else {
        throw Exception('OpenAI API error: $e');
      }
    }
  }

  // Generate response using Google Gemini API
  Future<String> _generateGeminiResponse(
    String userMessage,
    String emotionContext,
  ) async {
    debugPrint('Calling Google Gemini API...');
    debugPrint(
      'API Key present: ${_geminiApiKey != null && _geminiApiKey!.isNotEmpty}',
    );

    try {
      // Gemini API endpoint
      final model =
          'gemini-1.5-flash'; // or 'gemini-1.5-pro' for better quality
      final url = Uri.parse(
        '$geminiApiBaseUrl/models/$model:generateContent?key=$_geminiApiKey',
      );

      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text':
                    '''You are an empathetic mental health companion. Provide supportive, non-judgmental responses with warmth, empathy, and practical coping strategies. Keep responses concise (2-3 paragraphs).

Context: $emotionContext

User message: $userMessage

Please provide a supportive, empathetic response.''',
              },
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 500,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
        ],
      };

      debugPrint('Sending request to Gemini...');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Request timeout: Gemini API took too long to respond',
              );
            },
          );

      debugPrint('Gemini response status: ${response.statusCode}');
      debugPrint(
        'Gemini response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          final content = data['candidates'][0]['content']['parts'][0]['text'];
          debugPrint('Gemini API success! Response length: ${content.length}');
          return content;
        } else {
          debugPrint('Invalid response format: ${data.toString()}');
          throw Exception(
            'Invalid response format from Gemini API: Missing candidates or content',
          );
        }
      } else {
        // Parse error response
        String errorMessage = 'Gemini API error: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['error'] != null) {
            final error = errorData['error'];
            errorMessage =
                'Gemini API error: ${error['message'] ?? error['status'] ?? errorMessage}';
            debugPrint('Gemini API error details: $error');
          }
        } catch (parseError) {
          debugPrint('Could not parse error response: $parseError');
          debugPrint('Raw response: ${response.body}');
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Gemini API exception: $e');
      // Re-throw with more context
      final errorStr = e.toString();
      if (errorStr.contains('SocketException') ||
          errorStr.contains('Failed host lookup') ||
          errorStr.contains('Network is unreachable')) {
        throw Exception('Network error: Please check your internet connection');
      } else if (errorStr.contains('401') ||
          errorStr.contains('403') ||
          errorStr.contains('Unauthorized') ||
          errorStr.contains('Invalid API key') ||
          errorStr.contains('API key not valid')) {
        throw Exception(
          'API key error: Invalid or expired API key. Please check your Gemini API key in main.dart',
        );
      } else if (errorStr.contains('429') ||
          errorStr.contains('rate limit') ||
          errorStr.contains('RESOURCE_EXHAUSTED')) {
        throw Exception(
          'Rate limit exceeded: Please wait a moment and try again',
        );
      } else if (errorStr.contains('quota') || errorStr.contains('exceeded')) {
        throw Exception(
          'Quota exceeded: Your Gemini API account has run out of quota. Please check your usage at https://aistudio.google.com/app/apikey',
        );
      } else if (errorStr.contains('timeout')) {
        throw Exception(
          'Request timeout: Gemini API took too long to respond. Please try again.',
        );
      } else {
        throw Exception('Gemini API error: $e');
      }
    }
  }

  // Enhanced rule-based responses with context awareness
  String _generateRuleBasedResponse(
    String userMessage,
    List<EmotionLog>? recentEmotions,
  ) {
    final lowerMessage = userMessage.toLowerCase();

    // Analyze recent emotions for context
    String? dominantEmotion;
    if (recentEmotions != null && recentEmotions.isNotEmpty) {
      final emotionCounts = <String, int>{};
      for (var log in recentEmotions) {
        emotionCounts[log.emotion] = (emotionCounts[log.emotion] ?? 0) + 1;
      }
      dominantEmotion = emotionCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    // Build contextual response based on message content and recent emotions

    // Stress and overwhelm
    if (lowerMessage.contains('stress') ||
        lowerMessage.contains('overwhelm') ||
        lowerMessage.contains('stressed') ||
        lowerMessage.contains('pressure')) {
      String contextNote = '';
      if (dominantEmotion == 'stressed' || dominantEmotion == 'anxious') {
        contextNote = 'I notice you\'ve been feeling this way recently. ';
      }
      return '''I hear that you're feeling stressed. $contextNote That's completely valid, and I'm here with you.

Try this right now: Take 3 deep breaths. Breathe in for 4 counts, hold for 4, exhale for 6. This activates your body's calm response.

When you're ready, would it help to break down what's overwhelming you into smaller, manageable steps? Sometimes writing it down helps clarify what's truly urgent.''';
    }

    // Anxiety and worry
    if (lowerMessage.contains('anxious') ||
        lowerMessage.contains('worried') ||
        lowerMessage.contains('anxiety') ||
        lowerMessage.contains('panic') ||
        lowerMessage.contains('nervous')) {
      String contextNote = '';
      if (dominantEmotion == 'anxious') {
        contextNote = 'I see you\'ve been experiencing anxiety lately. ';
      }
      return '''Anxiety can feel really overwhelming. $contextNote Thank you for sharing this with me.

Here's a grounding technique: Name 5 things you can see, 4 you can touch, 3 you can hear, 2 you can smell, 1 you can taste. This brings you back to the present moment.

What specific worry is weighing on you most right now? Sometimes naming it out loud can make it feel more manageable.''';
    }

    // Sadness and depression
    if (lowerMessage.contains('sad') ||
        lowerMessage.contains('depressed') ||
        lowerMessage.contains('down') ||
        lowerMessage.contains('hopeless') ||
        lowerMessage.contains('empty')) {
      String contextNote = '';
      if (dominantEmotion == 'sad') {
        contextNote = 'I notice you\'ve been feeling sad recently. ';
      }
      return '''I'm really sorry you're going through this. $contextNote Your feelings are important and valid.

Sometimes when we're feeling low, gentle movement helps - even just a 5-minute walk or some light stretching. The combination of fresh air and movement can shift our mood slightly.

Is there someone you trust who you could reach out to today? You don't have to go through this alone.''';
    }

    // Procrastination and focus
    if (lowerMessage.contains('procrastinat') ||
        lowerMessage.contains('can\'t focus') ||
        lowerMessage.contains('unmotivated') ||
        lowerMessage.contains('lazy') ||
        lowerMessage.contains('stuck')) {
      return '''Procrastination often comes from feeling overwhelmed or uncertain. Let's make this manageable.

Try the 2-minute rule: If something takes less than 2 minutes, do it now. For bigger tasks, commit to just 10 minutes - you can stop after that if you want. Often, starting is the hardest part.

What's one small thing you could accomplish in the next 10 minutes? Even tiny progress counts.''';
    }

    // Sleep and tiredness
    if (lowerMessage.contains('tired') ||
        lowerMessage.contains('sleep') ||
        lowerMessage.contains('exhausted') ||
        lowerMessage.contains('fatigue')) {
      return '''It sounds like you're dealing with fatigue. That can really impact how you feel about everything else.

Are you getting enough rest? Sometimes our bodies need more sleep than we think. If sleep is the issue, try establishing a calming bedtime routine - maybe some light reading or gentle music.

What's been affecting your energy levels most?''';
    }

    // Anger and frustration
    if (lowerMessage.contains('angry') ||
        lowerMessage.contains('mad') ||
        lowerMessage.contains('frustrated') ||
        lowerMessage.contains('irritated')) {
      return '''Anger and frustration are valid emotions. It sounds like something is really bothering you.

Sometimes anger is a signal that a boundary has been crossed or a need isn't being met. Can you identify what's underneath the anger? Is it hurt, disappointment, or feeling unheard?

What would help you feel heard or respected right now?''';
    }

    // Loneliness
    if (lowerMessage.contains('lonely') ||
        lowerMessage.contains('alone') ||
        lowerMessage.contains('isolated')) {
      return '''Feeling lonely can be really difficult. Thank you for reaching out - that's a brave step.

Connection doesn't always have to be deep or long. Even small interactions can help - maybe a text to someone, or joining an online community about something you enjoy.

What kind of connection are you craving most right now?''';
    }

    // Questions about the AI or app
    if (lowerMessage.contains('who are you') ||
        lowerMessage.contains('what are you') ||
        lowerMessage.contains('help') ||
        lowerMessage.contains('what can you do')) {
      return '''I'm your AI mental health companion. I'm here to listen, support you, and offer gentle guidance when you need it.

I can help you process emotions, work through difficult feelings, suggest coping strategies, or just be a non-judgmental space to express yourself.

What would be most helpful for you right now?''';
    }

    // Gratitude and positive feelings
    if (lowerMessage.contains('thank') ||
        lowerMessage.contains('grateful') ||
        lowerMessage.contains('happy') ||
        lowerMessage.contains('good')) {
      return '''I'm so glad to hear you're feeling good! It's wonderful that you're taking time to notice and appreciate positive moments.

Celebrating the good times is just as important as processing the difficult ones. What's contributing to these positive feelings?''';
    }

    // General supportive response with context
    String contextIntro = '';
    if (dominantEmotion != null) {
      contextIntro =
          'I notice you\'ve been feeling $dominantEmotion recently. ';
    }

    return '''$contextIntro Thank you for sharing with me. I'm here to listen and support you.

It takes courage to reach out, even to an AI companion. Whatever you're experiencing is valid.

Would you like to talk more about what's on your mind, or would you prefer some coping strategies? I'm here for whatever you need.''';
  }

  // Generate personalized recommendation based on recent emotions
  Future<Map<String, String>> generateDailyRecommendation(
    List<EmotionLog> recentEmotions,
  ) async {
    // Analyze recent emotions to determine recommendation type
    final emotionCounts = <String, int>{};
    for (var log in recentEmotions) {
      emotionCounts[log.emotion] = (emotionCounts[log.emotion] ?? 0) + 1;
    }

    // Determine dominant mood
    String category;
    if (emotionCounts['sad'] != null && emotionCounts['sad']! > 2) {
      category = 'nature'; // Nature for sadness
    } else if (emotionCounts['anxious'] != null &&
        emotionCounts['anxious']! > 2) {
      category = 'exercise'; // Exercise for anxiety
    } else if (emotionCounts['stressed'] != null) {
      category = 'music'; // Music for stress
    } else {
      category = ['nature', 'art', 'food', 'music'][DateTime.now().day % 4];
    }

    return _getRecommendationForCategory(category);
  }

  Map<String, String> _getRecommendationForCategory(String category) {
    final recommendations = {
      'nature': [
        {
          'title': 'Morning Sunshine Walk',
          'description':
              'Take a 15-minute walk in natural light. Notice the colors of the sky, the temperature of the air, the sounds around you. Natural light boosts serotonin and helps regulate your mood.',
          'imageUrl':
              'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=800',
        },
        {
          'title': 'Cloud Watching',
          'description':
              'Spend 10 minutes lying down and watching clouds. Let your mind wander. This simple act of observation can be deeply meditative and grounding.',
          'imageUrl':
              'https://images.unsplash.com/photo-1419242902214-272b3f66ee7a?w=800',
        },
      ],
      'art': [
        {
          'title': 'Doodle Your Feelings',
          'description':
              'Grab a pen and paper. Don\'t think, just draw. Scribbles, shapes, patterns - whatever flows. Art doesn\'t need to be perfect to be healing.',
          'imageUrl':
              'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=800',
        },
        {
          'title': 'Color Therapy',
          'description':
              'Look at something colorful today - a painting, flowers, or even a coloring book. Colors have emotional resonance. What color calls to you right now?',
          'imageUrl':
              'https://images.unsplash.com/photo-1456086272160-b28b0645b729?w=800',
        },
      ],
      'food': [
        {
          'title': 'Mindful Tea Ritual',
          'description':
              'Brew your favorite tea. Notice the steam, the aroma, the warmth in your hands. Take slow sips and be fully present. This small ritual creates calm.',
          'imageUrl':
              'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=800',
        },
        {
          'title': 'One Beautiful Meal',
          'description':
              'Prepare one meal with intention today. Even something simple. Arrange it beautifully on your plate. Eating is nourishment for body and soul.',
          'imageUrl':
              'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800',
        },
      ],
      'music': [
        {
          'title': 'Music & Movement',
          'description':
              'Put on a song you love and move your body for 3 minutes. Dance, sway, or just tap your feet. Music + movement = instant mood boost.',
          'imageUrl':
              'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=800',
        },
        {
          'title': 'Soundtrack Your Day',
          'description':
              'Create a playlist that matches how you want to feel - not how you currently feel. Let music guide your emotional journey today.',
          'imageUrl':
              'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800',
        },
      ],
      'exercise': [
        {
          'title': 'Gentle Stretching',
          'description':
              'Spend 5 minutes stretching. Reach up, touch your toes, roll your shoulders. Your body holds tension - let it go, one stretch at a time.',
          'imageUrl':
              'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800',
        },
        {
          'title': 'Breathing Exercise',
          'description':
              '4-7-8 breathing: Breathe in for 4 counts, hold for 7, exhale for 8. Repeat 4 times. This activates your parasympathetic nervous system and creates instant calm.',
          'imageUrl':
              'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800',
        },
      ],
    };

    final categoryList = recommendations[category]!;
    final random = DateTime.now().millisecond % categoryList.length;
    final selected = categoryList[random];

    return {
      'title': selected['title']!,
      'description': selected['description']!,
      'category': category,
      'imageUrl': selected['imageUrl']!,
    };
  }

  // Generate proactive check-in message based on recent activity
  String generateCheckInPrompt(List<EmotionLog> recentLogs) {
    if (recentLogs.isEmpty) {
      return "Hey there! 👋 How are you feeling today? I'd love to hear about your day.";
    }

    final lastLog = recentLogs.first;
    final hoursSinceLastLog = DateTime.now()
        .difference(lastLog.dateTime)
        .inHours;

    if (hoursSinceLastLog > 24) {
      return "I haven't heard from you in a while. How have things been? I'm here if you want to chat. 💙";
    }

    if (lastLog.emotion == 'stressed' || lastLog.emotion == 'anxious') {
      return "I noticed you were feeling ${lastLog.emotion} earlier. How are you doing now? Would a breathing exercise help?";
    }

    if (lastLog.emotion == 'sad') {
      return "Checking in on you. Sometimes sadness lingers, and that's okay. How's your heart doing today?";
    }

    return "Hope your day is going well! Want to share how you're feeling? 😊";
  }

  // 在 ai_service.dart 类中添加
  Future<String> sendMessage(String message) async {
    return await sendChatbotMessage(message);
  }
}
