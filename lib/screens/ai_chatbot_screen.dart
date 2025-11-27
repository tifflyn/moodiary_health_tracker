import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';
import '../models/emotionlog.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';

class AIChatbotScreen extends StatefulWidget {
  const AIChatbotScreen({super.key});
  @override
  State<AIChatbotScreen> createState() => _AIChatbotScreenState();
}

class _AIChatbotScreenState extends State<AIChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> messages = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    final history = await DatabaseService.instance.getChatHistory(limit: 50);
    setState(() {
      messages = history.reversed.toList();
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text;
    _messageController.clear();

    final userMessage = ChatMessage(
      message: messageText,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      messages.add(userMessage);
      isLoading = true;
    });

    String aiResponse = '';
    try {
      // Try to save user message (non-critical if it fails)
      try {
        await DatabaseService.instance.insertChatMessage(userMessage);
      } catch (dbError) {
        debugPrint('Warning: Could not save user message to database: $dbError');
      }
      _scrollToBottom();

      // Get recent emotions for context (non-critical if it fails)
      List<EmotionLog>? recentEmotions;
      try {
        recentEmotions = await DatabaseService.instance.getEmotionsForDateRange(
          DateTime.now().subtract(const Duration(days: 7)),
          DateTime.now(),
        );
      } catch (dbError) {
        debugPrint('Warning: Could not load recent emotions: $dbError');
        recentEmotions = null;
      }

      // Generate AI response (will automatically fallback to rule-based on error)
      try {
        aiResponse = await AIService.instance.generateTherapistResponse(
          userMessage.message,
          recentEmotions,
        );
        
        // Show API error warnings to help debug
        final apiError = AIService.instance.lastApiError;
        if (apiError != null && mounted) {
          String errorMessage = 'Using enhanced local AI';
          bool showError = false;
          
          if (apiError.contains('API key') || apiError.contains('401') || apiError.contains('Unauthorized') || apiError.contains('403')) {
            if (apiError.contains('Gemini')) {
              errorMessage = 'API key error: Check your Gemini API key in main.dart. Using local AI for now.';
            } else {
              errorMessage = 'API key error: Check your API key in main.dart. Using local AI for now.';
            }
            showError = true;
          } else if (apiError.contains('Network error')) {
            errorMessage = 'Network error: Check your internet connection. Using local AI for now.';
            showError = true;
          } else if (apiError.contains('Rate limit') || apiError.contains('429')) {
            errorMessage = 'Rate limit exceeded: Please wait a moment. Using local AI for now.';
            showError = true;
          } else if (apiError.contains('quota') || apiError.contains('exceeded') || apiError.contains('insufficient_quota')) {
            if (apiError.contains('Gemini')) {
              errorMessage = 'Gemini quota exceeded: Check usage at aistudio.google.com/app/apikey. Using local AI for now.';
            } else {
              errorMessage = 'OpenAI quota exceeded: Add credits at platform.openai.com/account/billing. Using local AI for now.';
            }
            showError = true;
          } else if (apiError.contains('timeout')) {
            if (apiError.contains('Gemini')) {
              errorMessage = 'Request timeout: Gemini API took too long. Using local AI for now.';
            } else {
              errorMessage = 'Request timeout: API took too long. Using local AI for now.';
            }
            showError = true;
          }
          
          if (showError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      } catch (aiError) {
        // If AI service fails completely, use a basic fallback
        debugPrint('AI service error: $aiError');
        aiResponse = '''Thank you for sharing with me. I'm here to listen and support you.

It takes courage to reach out. Whatever you're experiencing is valid.

Would you like to talk more about what's on your mind?''';
      }

      // Ensure we have a response
      if (aiResponse.isEmpty) {
        aiResponse = '''Thank you for your message. I'm here to listen and support you.

How can I help you today?''';
      }

      final aiMessage = ChatMessage(
        message: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );

      if (!mounted) return;

      setState(() {
        messages.add(aiMessage);
        isLoading = false;
      });

      // Try to save AI message (non-critical if it fails)
      try {
        await DatabaseService.instance.insertChatMessage(aiMessage);
      } catch (dbError) {
        debugPrint('Warning: Could not save AI message to database: $dbError');
      }
      _scrollToBottom();
    } catch (e) {
      // Handle any other errors that occur during message sending
      debugPrint('Error sending message: $e');
      
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      // Show user-friendly error message
      String errorMessage = 'Unable to send message. Please try again.';
      final errorStr = e.toString().toLowerCase();
      
      if (errorStr.contains('network error') || 
          errorStr.contains('socketexception') || 
          errorStr.contains('failed host lookup') ||
          errorStr.contains('connection')) {
        errorMessage = 'Network error: Please check your internet connection';
      } else if (errorStr.contains('api key') || 
                 errorStr.contains('401') || 
                 errorStr.contains('403') ||
                 errorStr.contains('unauthorized') ||
                 errorStr.contains('invalid api key')) {
        if (errorStr.contains('gemini')) {
          errorMessage = 'API key error: Please check your Gemini API key in main.dart';
        } else {
          errorMessage = 'API key error: Please check your API key in main.dart';
        }
      } else if (errorStr.contains('rate limit') || 
                 errorStr.contains('429') ||
                 errorStr.contains('quota')) {
        errorMessage = 'Rate limit exceeded: Please wait a moment and try again';
      } else if (errorStr.contains('timeout')) {
        errorMessage = 'Request timed out. Please try again.';
      } else {
        // For debugging - show full error in console but user-friendly message in UI
        errorMessage = 'Unable to process message. The enhanced local AI will be used instead.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.purple,
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.psychology, color: Colors.purple),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Companion', style: TextStyle(fontSize: 18)),
                Text(
                  'Always here to listen',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Start a conversation',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Share what\'s on your mind. I\'m here to listen and support you.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),

          // Loading indicator
          if (isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    child: const Icon(Icons.psychology, color: Colors.purple),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('Thinking...'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Input area
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Share what\'s on your mind...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.purple,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: const Icon(Icons.psychology, color: Colors.purple, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.purple : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    message.message,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('h:mm a').format(message.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.purple[100],
              child: const Icon(Icons.person, color: Colors.purple, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}