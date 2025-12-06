import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../models/emotionlog.dart';
import '../services/ai_service.dart';
import '../services/firebase_service.dart';
import '../providers/auth_provider.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../widgets/glass_card.dart';

class Meteor {
  final double startX; // 起始X位置（0-1）
  final double startY; // 起始Y位置（0-1）
  final double speed; // 速度
  final double length; // 长度
  final Color color; // 颜色
  final double startDelay; // 起始延迟（秒）

  Meteor({
    required this.startX,
    required this.startY,
    required this.speed,
    required this.length,
    required this.color,
    required this.startDelay,
  });
}

// 流星绘画器
class MeteorPainter extends CustomPainter {
  final double animationValue;
  final List<Meteor> meteors;

  MeteorPainter({required this.animationValue, required this.meteors});

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制一些微弱的星星（背景）
    final random = Random(42);
    for (int i = 0; i < 45; i++) {
      // 增加星星数量
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final alpha = 50 + random.nextInt(150); // 增加亮度变化范围
      final radius = 0.5 + random.nextDouble() * 1.5; // 增加半径范围

      final starPaint = Paint()
        ..color = Colors.white.withAlpha(alpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), radius, starPaint);

      // 添加星星的微弱光晕
      if (random.nextDouble() > 0.7) {
        // 30%的星星有光晕
        final glowPaint = Paint()
          ..color = Colors.white.withAlpha(alpha ~/ 3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

        canvas.drawCircle(Offset(x, y), radius * 2, glowPaint);
      }
    }

    for (var meteor in meteors) {
      // 计算流星当前位置
      final effectiveTime = (animationValue * 60 + meteor.startDelay) % 60;

      // 调整显示时间窗口
      if (effectiveTime < 4.0) {
        // 4秒显示时间
        final progress = effectiveTime / 4.0;

        // 计算起始位置 - 从左到右移动
        final startX = meteor.startX * size.width;
        final startY = meteor.startY * size.height;

        // 计算结束位置
        final distance = size.width * 0.8; // 移动屏幕宽度的80%
        final endX = startX + distance * progress;
        final endY = startY + distance * progress * 0.15; // 轻微向下倾斜

        // 绘制流星尾迹（渐变效果）- 从左到右
        final gradientPaint = Paint()
          ..shader =
              LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  meteor.color.withOpacity(0.9),
                  meteor.color.withOpacity(0.0),
                ],
              ).createShader(
                Rect.fromPoints(Offset(startX, startY), Offset(endX, endY)),
              )
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;

        canvas.drawLine(
          Offset(startX, startY),
          Offset(endX, endY),
          gradientPaint,
        );

        // 绘制流星头部（发光点）
        final headPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset(endX, endY), 3, headPaint);

        // 绘制流星头部光晕
        final glowPaint = Paint()
          ..color = meteor.color.withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

        canvas.drawCircle(Offset(endX, endY), 8, glowPaint);

        // 添加流星尾迹的发光效果
        final tailGlowPaint = Paint()
          ..color = meteor.color.withOpacity(0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
          ..strokeWidth = 4.0
          ..strokeCap = StrokeCap.round;

        canvas.drawLine(
          Offset(startX, startY),
          Offset(endX, endY),
          tailGlowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AIChatbotScreen extends StatefulWidget {
  const AIChatbotScreen({super.key});

  @override
  State<AIChatbotScreen> createState() => _AIChatbotScreenState();
}

class _AIChatbotScreenState extends State<AIChatbotScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> messages = [];
  bool isLoading = false;
  bool _isInitializing = true;
  StreamSubscription<List<ChatMessage>>? _chatSubscription;

  // 流星动画相关
  late AnimationController _meteorController;
  late Animation<double> _meteorAnimation;
  List<Meteor> meteors = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _initializeChat();
    AIService.instance.setChatbotMode();

    // 初始化流星动画
    _meteorController = AnimationController(
      duration: const Duration(seconds: 10), // 增加动画时长
      vsync: this,
    )..repeat(reverse: false);

    _meteorAnimation = CurvedAnimation(
      parent: _meteorController,
      curve: Curves.linear,
    );

    // 初始化更多流星
    for (int i = 0; i < 10; i++) {
      // 增加到5个流星
      meteors.add(_createRandomMeteor());
    }
  }

  // 创建随机流星
  Meteor _createRandomMeteor() {
    // 随机决定流星的起始高度
    // 0.0-0.3: 顶部区域 (30%)
    // 0.3-0.7: 中间区域 (40%)
    // 0.7-1.0: 底部区域 (30%)
    final randomType = _random.nextDouble();
    double startY;

    if (randomType < 0.2) {
      // 顶部流星：从上往下
      startY = _random.nextDouble() * 0.2;
    } else if (randomType < 0.5) {
      // 中间流星：从屏幕中间开始
      startY = 0.2 + _random.nextDouble() * 0.3;
    } else {
      // 底部流星：从底部开始
      startY = 0.8 + _random.nextDouble() * 0.2;
    }

    return Meteor(
      startX: _random.nextDouble() * 0.2, // 避免太靠近边缘
      startY: startY, // 使用随机的高度
      speed: 0.5 + _random.nextDouble() * 1.0,
      length: 50 + _random.nextDouble() * 100,
      color: Colors.white.withAlpha(150 + _random.nextInt(105)),
      startDelay: _random.nextDouble() * 40, // 0-20秒延迟
    );
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _meteorController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    await Future.delayed(const Duration(milliseconds: 300));

    // 添加欢迎消息
    setState(() {
      messages.add(
        ChatMessage(
          message:
              '''Hello! I'm your mental wellness companion. I'm here to listen, support, and help you navigate your feelings. 💭

Feel free to share what's on your mind - your thoughts, feelings, or anything you'd like to talk about.

How are you feeling today?''',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      _isInitializing = false;
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
    if (_messageController.text.trim().isEmpty || isLoading) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user.id;

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please sign in first', style: AppTextStyles.bodySmall),
          backgroundColor: AppColors.drained,
        ),
      );
      return;
    }

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

    _scrollToBottom();

    try {
      // 保存用户消息
      try {
        await FirebaseService.instance.addChatMessage(userId, userMessage);
      } catch (dbError) {
        debugPrint('Warning: Could not save user message: $dbError');
      }

      // 获取最近的情绪记录（用于上下文）
      List<EmotionLog> recentEmotions = [];
      try {
        final end = DateTime.now();
        final start = end.subtract(const Duration(days: 7));
        recentEmotions = await FirebaseService.instance.getEmotionsForDateRange(
          userId,
          start,
          end,
        );
      } catch (dbError) {
        debugPrint('Warning: Could not load recent emotions: $dbError');
      }

      // 生成AI回复
      String aiResponse;
      try {
        aiResponse = await AIService.instance.generateTherapistResponse(
          userMessage.message,
          recentEmotions,
        );
      } catch (e) {
        debugPrint('AI service error: $e');
        aiResponse =
            '''Thank you for sharing with me. I'm here to listen and support you. 💫

It takes courage to reach out. Whatever you're experiencing is valid.

Would you like to talk more about what's on your mind?''';
      }

      // 确保有回复
      if (aiResponse.isEmpty) {
        aiResponse =
            '''Thank you for your message. I'm here to listen and support you. ✨

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

      // 尝试保存AI消息
      try {
        await FirebaseService.instance.addChatMessage(userId, aiMessage);
      } catch (dbError) {
        debugPrint('Warning: Could not save AI message: $dbError');
      }

      _scrollToBottom();
    } catch (e) {
      debugPrint('Error sending message: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      // 显示错误消息
      final errorMessage = ChatMessage(
        message:
            '''I apologize, but I'm having trouble connecting right now. 🌧️

Please check your internet connection and try again. Remember, I'm always here for you.''',
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        messages.add(errorMessage);
      });

      _scrollToBottom();
    }
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.accentGradient,
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.psychology_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            )
          else
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  color: isUser
                      ? AppColors.accentBlue.withAlpha(30)
                      : AppColors.cardDark,
                  child: Text(
                    message.message,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isUser ? Colors.white : AppColors.textGray,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  DateFormat('h:mm a').format(message.timestamp),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.accentGradient),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.psychology_alt, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 6),
                _buildTypingDot(1),
                const SizedBox(width: 6),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withAlpha(
          (255 * (0.5 + (index * 0.2))).toInt(),
        ),
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.bgGradient,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          Positioned.fill(child: _buildMeteorLayer()),

          Column(
            children: [
              // 头部
              GlassCard(
                margin: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: AppColors.accentGradient,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.psychology_alt_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mindful AI',
                                style: AppTextStyles.headline3,
                              ),
                              Text(
                                'Available 24/7 • Confidential',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.lightBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentBlue.withAlpha(25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.accentBlue.withAlpha(76),
                            ),
                          ),
                          child: Text(
                            'AI',
                            style: TextStyle(
                              color: AppColors.accentBlue,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'I\'m here to listen and support you. Share anything that\'s on your mind.',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.lightBlue,
                      ),
                    ),
                  ],
                ),
              ),

              // 聊天消息
              Expanded(
                child: _isInitializing
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accentBlue,
                        ),
                      )
                    : messages.isEmpty
                    ? Center(
                        child: GlassCard(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.psychology_outlined,
                                size: 60,
                                color: AppColors.textGray.withAlpha(127),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Start a conversation',
                                style: AppTextStyles.headline3,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Your AI companion is here to listen and support you.',
                                style: AppTextStyles.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        itemCount: messages.length + (isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index < messages.length) {
                            return _buildMessageBubble(messages[index]);
                          } else {
                            return _buildTypingIndicator();
                          }
                        },
                      ),
              ),

              // 输入区域 - 增加底部边距
              Container(
                margin: const EdgeInsets.fromLTRB(20, 10, 20, 100), // 改为100
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: AppTextStyles.input,
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: 'Share what\'s on your mind...',
                            hintStyle: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.textGray.withAlpha(150),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 0,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: AppColors.accentGradient,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.send,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeteorLayer() {
    return SizedBox.expand(
      child: AnimatedBuilder(
        animation: _meteorAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: MeteorPainter(
              animationValue: _meteorAnimation.value,
              meteors: meteors,
            ),
          );
        },
      ),
    );
  }
}
