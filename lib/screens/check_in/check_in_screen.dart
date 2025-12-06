import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../models/check_in.dart';
import '../../services/firebase_service.dart';
import '../../services/ai_service.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../constants/text_styles.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  String? selectedEmoji;
  final TextEditingController _diaryController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  bool isLoading = false;
  CheckIn? generatedCheckIn;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<String> _selectedTags = [];
  String? _selectedEmotion;
  final FirebaseService _firebaseService = FirebaseService.instance;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
    });
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _completeReset() {
    // 使用 Navigator.pushReplacement 完全替换当前屏幕
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => const CheckInScreen(),
        transitionDuration: Duration.zero,
      ),
    );
  }

  final List<Map<String, dynamic>> emojis = [
    {
      'emoji': '😊',
      'label': 'Happy',
      'emotion': 'happy',
      'color': Color(0xFFFFF9C4),
      'gradient': [Color(0xFFFFD54F), Color(0xFFFFF176)],
    },
    {
      'emoji': '😢',
      'label': 'Sad',
      'emotion': 'sad',
      'color': Color(0xFFE3F2FD),
      'gradient': [Color(0xFF64B5F6), Color(0xFF90CAF9)],
    },
    {
      'emoji': '😰',
      'label': 'Anxious',
      'emotion': 'anxious',
      'color': Color(0xFFF3E5F5),
      'gradient': [Color(0xFFBA68C8), Color(0xFFCE93D8)],
    },
    {
      'emoji': '😤',
      'label': 'Frustrated',
      'emotion': 'frustrated',
      'color': Color(0xFFFFEBEE),
      'gradient': [Color(0xFFEF5350), Color(0xFFE57373)],
    },
    {
      'emoji': '😴',
      'label': 'Tired',
      'emotion': 'tired',
      'color': Color(0xFFE8F5E9),
      'gradient': [Color(0xFF66BB6A), Color(0xFF81C784)],
    },
    {
      'emoji': '🤗',
      'label': 'Loved',
      'emotion': 'loved',
      'color': Color(0xFFFFF3E0),
      'gradient': [Color(0xFFFF8A65), Color(0xFFFFAB91)],
    },
    {
      'emoji': '😡',
      'label': 'Angry',
      'emotion': 'angry',
      'color': Color(0xFFFCE4EC),
      'gradient': [Color(0xFFEC407A), Color(0xFFF48FB1)],
    },
    {
      'emoji': '😌',
      'label': 'Calm',
      'emotion': 'calm',
      'color': Color(0xFFE0F7FA),
      'gradient': [Color(0xFF26C6DA), Color(0xFF4DD0E1)],
    },
  ];

  final List<Map<String, dynamic>> tags = [
    {'label': 'Work', 'emoji': '💼', 'color': Color(0xFFE8F5E9)},
    {'label': 'Family', 'emoji': '👨‍👩‍👧‍👦', 'color': Color(0xFFFFF3E0)},
    {'label': 'Friends', 'emoji': '👯', 'color': Color(0xFFE3F2FD)},
    {'label': 'Health', 'emoji': '🏥', 'color': Color(0xFFFCE4EC)},
    {'label': 'Hobby', 'emoji': '🎨', 'color': Color(0xFFF3E5F5)},
    {'label': 'Nature', 'emoji': '🌳', 'color': Color(0xFFE8F5E9)},
    {'label': 'Food', 'emoji': '🍕', 'color': Color(0xFFFFF3E0)},
    {'label': 'Exercise', 'emoji': '🏃', 'color': Color(0xFFE0F7FA)},
  ];

  // 使用 Material 替代 Container 的包装器
  Widget _buildGlassContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double borderRadius = 20,
    bool withBorder = true,
  }) {
    return Container(
      margin: margin,
      child: Material(
        color: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(borderRadius),
            border: withBorder
                ? Border.all(color: Colors.white.withAlpha(30))
                : null,
          ),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: emojis.length,
      itemBuilder: (context, index) {
        final emoji = emojis[index];
        final isSelected = selectedEmoji == emoji['emoji'];
        final gradient = emoji['gradient'] as List<Color>;

        return GestureDetector(
          onTap: () {
            setState(() {
              selectedEmoji = emoji['emoji'] as String?;
              _selectedEmotion = emoji['emotion'] as String?;
            });
          },
          child: Material(
            color: Colors.transparent,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : Colors.white.withAlpha(20),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? Colors.white.withAlpha(150)
                      : Colors.transparent,
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: gradient[0].withAlpha(100),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    emoji['emoji'] as String,
                    style: const TextStyle(fontSize: 36),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    emoji['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withAlpha(200),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTagChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) {
        final isSelected = _selectedTags.contains(tag['label']);
        final color = tag['color'] as Color;

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedTags.remove(tag['label'] as String);
              } else {
                _selectedTags.add(tag['label'] as String);
              }
            });
          },
          child: Material(
            color: Colors.transparent,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isSelected ? color : color.withAlpha(50),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : color.withAlpha(100),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(tag['emoji'] as String),
                    const SizedBox(width: 6),
                    Text(
                      tag['label'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.black87
                            : Colors.white.withAlpha(200),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _submitCheckIn() async {
    if (selectedEmoji == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an emoji')));
      return;
    }

    final authProvider = Provider.of<app_auth.AuthProvider>(
      context,
      listen: false,
    );

    final userId = authProvider.user.id;

    if (userId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please sign in first')));
      return;
    }

    setState(() => isLoading = true);

    try {
      final userMessage = _buildUserMessage();
      final aiResponse = await AIService.instance.generateTherapistResponse(
        userMessage,
        null,
      );

      final checkIn = CheckIn(
        emoji: selectedEmoji!,
        diary: _diaryController.text.isEmpty ? null : _diaryController.text,
        title: _titleController.text.isEmpty ? null : _titleController.text,
        aiResponse: aiResponse,
        timestamp: DateTime.now(),
        emotion: _selectedEmotion ?? 'neutral',
      );

      await _firebaseService.addCheckIn(userId, checkIn);

      if (!mounted) return;

      setState(() {
        generatedCheckIn = checkIn;
        isLoading = false;
      });

      debugPrint('✅ CheckIn submitted successfully:');
      debugPrint('   Emoji: ${checkIn.emoji}');
      debugPrint('   Emotion: ${checkIn.emotion}');
      debugPrint('   Title: ${checkIn.title}');
      debugPrint('   Diary length: ${checkIn.diary?.length ?? 0}');
      debugPrint('   AI Response length: ${checkIn.aiResponse?.length ?? 0}');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting check-in: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _buildUserMessage() {
    final emojiData = emojis.firstWhere(
      (e) => e['emoji'] == selectedEmoji,
      orElse: () => {'label': 'unknown', 'emotion': 'neutral'},
    );

    final emojiLabel = emojiData['label'] as String;
    final emotion = emojiData['emotion'] as String;

    String message =
        'I selected the $emojiLabel emoji ($selectedEmoji) to represent my mood. My emotion is: $emotion.';

    if (_diaryController.text.isNotEmpty) {
      message += ' Here\'s what I wrote about my day: ${_diaryController.text}';
    }

    if (_titleController.text.isNotEmpty) {
      message += ' The title of my entry is: "${_titleController.text}".';
    }

    if (_selectedTags.isNotEmpty) {
      message += ' I added these tags: ${_selectedTags.join(', ')}.';
    }

    return message;
  }

  Widget _buildResponseScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2C3E50), Color(0xFF4A6491), Color(0xFF2C3E50)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 返回按钮
                _buildGlassContainer(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Material(
                          color: Colors.transparent,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(20),
                              shape: BoxShape.circle,
                            ),
                            child: const SizedBox(
                              width: 40,
                              height: 40,
                              child: Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Material(
                        color: Colors.transparent,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(20),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              generatedCheckIn?.title ??
                                  'AI Response', // 使用实际标题
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 表情 - 使用实际选择的emoji
                Material(
                  color: Colors.transparent,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: Center(
                          child: Text(
                            generatedCheckIn?.emoji ?? '😊', // 使用实际emoji
                            style: const TextStyle(fontSize: 60),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 显示情绪标签
                if (generatedCheckIn?.emotion != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Feeling: ${generatedCheckIn!.emotion}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                const SizedBox(height: 32),

                // AI 响应 - 使用实际的AI回复
                _buildGlassContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF9C27B0),
                                    Color(0xFFE040FB),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const SizedBox(
                                width: 36,
                                height: 36,
                                child: Icon(
                                  Icons.psychology,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'AI Companion',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // 显示实际AI回复
                      if (generatedCheckIn?.aiResponse != null)
                        Text(
                          generatedCheckIn!.aiResponse!,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: Colors.white.withAlpha(230),
                          ),
                        )
                      else
                        const Text(
                          'No AI response available.',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),

                // 显示用户的日记内容（如果有）
                if (generatedCheckIn?.diary != null &&
                    generatedCheckIn!.diary!.isNotEmpty)
                  Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildGlassContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF2196F3),
                                          Color(0xFF21CBF3),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const SizedBox(
                                      width: 36,
                                      height: 36,
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Your Thoughts',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              generatedCheckIn!.diary!,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: Colors.white.withAlpha(200),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 32),

                // 在 _buildResponseScreen() 中，修改 "Done" 按钮
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      // 返回 true 表示有新数据
                      Navigator.pop(context, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A6491),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _completeReset,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Check In Again',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (generatedCheckIn != null) {
      return _buildResponseScreen();
    }

    final authProvider = Provider.of<app_auth.AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2C3E50), Color(0xFF4A6491), Color(0xFF2C3E50)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 顶部导航
              _buildGlassContainer(
                margin: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Material(
                        color: Colors.transparent,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                          child: const SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(Icons.arrow_back, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Material(
                      color: Colors.transparent,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            'Check-In',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: PageView(
                  controller: _pageController,
                  children: [
                    // 第1页：选择情绪
                    SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildGlassContainer(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Material(
                                      color: Colors.transparent,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFFF9A9E),
                                              Color(0xFFFAD0C4),
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const SizedBox(
                                          width: 50,
                                          height: 50,
                                          child: Icon(
                                            Icons.favorite_border,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Hi, ${user.nickname}',
                                            style: AppTextStyles.headline3
                                                .copyWith(color: Colors.white),
                                          ),
                                          Text(
                                            'How are you feeling today?',
                                            style: TextStyle(
                                              color: Colors.white.withAlpha(
                                                180,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Select your mood',
                                  style: AppTextStyles.subtitle1.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Pick an emoji that best describes your current emotion',
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(150),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildEmojiGrid(),
                        ],
                      ),
                    ),

                    // 第2页：添加详情
                    SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildGlassContainer(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Material(
                                      color: Colors.transparent,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFA1C4FD),
                                              Color(0xFFC2E9FB),
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const SizedBox(
                                          width: 50,
                                          height: 50,
                                          child: Icon(
                                            Icons.edit_note_outlined,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Add Details',
                                            style: AppTextStyles.headline3
                                                .copyWith(color: Colors.white),
                                          ),
                                          Text(
                                            'Optional: add context to your check-in',
                                            style: TextStyle(
                                              color: Colors.white.withAlpha(
                                                180,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildGlassContainer(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Title',
                                  style: AppTextStyles.subtitle2.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _titleController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Give your entry a title...',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withAlpha(100),
                                    ),
                                    border: InputBorder.none,
                                    filled: true,
                                    fillColor: Colors.white.withAlpha(10),
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildGlassContainer(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Description',
                                  style: AppTextStyles.subtitle2.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _diaryController,
                                  maxLines: 4,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'What\'s on your mind today?',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withAlpha(100),
                                    ),
                                    border: InputBorder.none,
                                    filled: true,
                                    fillColor: Colors.white.withAlpha(10),
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildGlassContainer(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tags',
                                  style: AppTextStyles.subtitle2.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Add tags to categorize your entry',
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(150),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildTagChips(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 底部导航和按钮
              Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 分页指示器
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(2, (index) {
                        return Material(
                          color: Colors.transparent,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentPage == index
                                  ? Colors.white
                                  : Colors.white.withAlpha(100),
                            ),
                            child: const SizedBox(width: 8, height: 8),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (_currentPage > 0)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withAlpha(20),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.arrow_back, size: 18),
                                  SizedBox(width: 8),
                                  Text('Back'),
                                ],
                              ),
                            ),
                          ),
                        if (_currentPage > 0) const SizedBox(width: 12),
                        Expanded(
                          flex: _currentPage == 0 ? 2 : 1,
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    if (_currentPage == 0) {
                                      if (selectedEmoji == null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                              'Please select a mood',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }
                                      _pageController.nextPage(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeInOut,
                                      );
                                    } else {
                                      _submitCheckIn();
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A6491),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _currentPage == 0
                                            ? 'Continue'
                                            : 'Submit Check-In',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      if (_currentPage == 0)
                                        const Icon(
                                          Icons.arrow_forward,
                                          size: 18,
                                        ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _diaryController.dispose();
    _titleController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}
