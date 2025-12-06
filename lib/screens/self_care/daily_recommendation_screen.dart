// lib/screens/self_care/daily_recommendation_screen.dart
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/daily_recommendation.dart';
import '../../services/firebase_service.dart';
import '../../services/ai_service.dart';
import './breathing_screen.dart';
import './meditation.dart';
import '../../widgets/glass_card.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';

class DailyRecommendationScreen extends StatefulWidget {
  const DailyRecommendationScreen({super.key});

  @override
  State<DailyRecommendationScreen> createState() =>
      _DailyRecommendationScreenState();
}

class _DailyRecommendationScreenState extends State<DailyRecommendationScreen>
    with SingleTickerProviderStateMixin {
  DailyRecommendation? todayRecommendation;
  bool isLoading = true;
  final FirebaseService _firebaseService = FirebaseService.instance;
  User? _currentUser;
  late AnimationController _starsController;
  late Animation<double> _starsAnimation;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;

    // 星空动画控制器
    _starsController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat(reverse: false);

    _starsAnimation = CurvedAnimation(
      parent: _starsController,
      curve: Curves.linear,
    );

    _loadOrGenerateRecommendation();
  }

  @override
  void dispose() {
    _starsController.dispose();
    super.dispose();
  }

  Future<void> _markBreathingExerciseAsCompleted() async {
    debugPrint('Breathing exercise completed - first cycle finished');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Breathing exercise completed! 🌬️'),
          backgroundColor: AppColors.accentBlue,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _loadOrGenerateRecommendation() async {
    setState(() => isLoading = true);

    try {
      if (_currentUser == null) {
        setState(() => isLoading = false);
        return;
      }

      var recommendation = await _firebaseService.getTodayRecommendation(
        _currentUser!.uid,
      );

      if (recommendation == null) {
        final recentEmotions = await _firebaseService.getEmotionsForDateRange(
          _currentUser!.uid,
          DateTime.now().subtract(const Duration(days: 7)),
          DateTime.now(),
        );

        final recData = await AIService.instance.generateDailyRecommendation(
          recentEmotions,
        );

        recommendation = DailyRecommendation(
          title: recData['title']!,
          description: recData['description']!,
          category: recData['category']!,
          imageUrl: recData['imageUrl']!,
          date: DateTime.now(),
        );

        await _firebaseService.addDailyRecommendation(
          _currentUser!.uid,
          recommendation,
        );
      }

      if (mounted) {
        setState(() {
          todayRecommendation = recommendation;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading recommendation: $e');

      if (mounted) {
        try {
          final fallbackRecData = await AIService.instance
              .generateDailyRecommendation([]);
          final fallbackRecommendation = DailyRecommendation(
            title: fallbackRecData['title']!,
            description: fallbackRecData['description']!,
            category: fallbackRecData['category']!,
            imageUrl: fallbackRecData['imageUrl']!,
            date: DateTime.now(),
          );

          setState(() {
            todayRecommendation = fallbackRecommendation;
            isLoading = false;
          });

          try {
            if (_currentUser != null) {
              await _firebaseService.addDailyRecommendation(
                _currentUser!.uid,
                fallbackRecommendation,
              );
            }
          } catch (_) {}
        } catch (fallbackError) {
          debugPrint('Fallback recommendation also failed: $fallbackError');
          setState(() => isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Error loading recommendation. Please try again.',
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _markAsCompleted() async {
    if (todayRecommendation != null && _currentUser != null) {
      final dateStr =
          '${todayRecommendation!.date.year}-${todayRecommendation!.date.month.toString().padLeft(2, '0')}-${todayRecommendation!.date.day.toString().padLeft(2, '0')}';

      try {
        await _firebaseService.markRecommendationCompleted(
          _currentUser!.uid,
          dateStr,
        );

        setState(() {
          todayRecommendation = DailyRecommendation(
            id: todayRecommendation!.id,
            title: todayRecommendation!.title,
            description: todayRecommendation!.description,
            category: todayRecommendation!.category,
            imageUrl: todayRecommendation!.imageUrl,
            date: todayRecommendation!.date,
            completed: true,
          );
        });

        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        debugPrint('Error marking as completed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _startBreathingExercise() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BreathingExerciseScreen(
          onCompleted: () => Navigator.pop(context, true),
          onTaskCompleted: _markBreathingExerciseAsCompleted,
        ),
      ),
    ).then((result) {
      if (result == true && mounted) {
        Navigator.pop(context, true);
      }
    });
  }

  // 构建星空背景
  Widget _buildStarfield() {
    return AnimatedBuilder(
      animation: _starsAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: StarFieldPainter(_starsAnimation.value),
          child: Container(),
        );
      },
    );
  }

  // 构建行星装饰
  Widget _buildPlanetDecoration() {
    return Positioned(
      top: 50,
      right: 20,
      child: AnimatedBuilder(
        animation: _starsController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _starsAnimation.value * 2 * pi,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9C27B0), Color(0xFF2196F3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withAlpha(127),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 构建小行星带
  Widget _buildAsteroidBelt() {
    return Positioned(
      bottom: 100,
      left: -50,
      child: AnimatedBuilder(
        animation: _starsController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_starsAnimation.value * 100, 0),
            child: Container(
              width: 200,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.grey.withAlpha(63),
                    Colors.grey.withAlpha(25),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Stack(
        children: [
          // 星空背景
          _buildStarfield(),

          // 行星装饰
          _buildPlanetDecoration(),
          _buildAsteroidBelt(),

          // 主内容
          NotificationListener<ScrollNotification>(
            onNotification: (notification) => false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 300,
                  collapsedHeight: 80,
                  pinned: true,
                  floating: false,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildHeroSection(),
                  ),
                ),

                SliverToBoxAdapter(
                  child: isLoading
                      ? Container(
                          height: 300,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(
                            color: AppColors.accentBlue,
                          ),
                        )
                      : todayRecommendation == null
                      ? _buildErrorState()
                      : _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    if (isLoading || todayRecommendation == null) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.spaceGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        image: todayRecommendation!.imageUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(todayRecommendation!.imageUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withAlpha(127),
                  BlendMode.darken,
                ),
              )
            : null,
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withAlpha(191)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassCard(
                color: Colors.black.withAlpha(63),
                blurSigma: 20,
                borderRadius: 12,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  _getCategoryLabel(todayRecommendation!.category),
                  style: AppTextStyles.caption.copyWith(
                    color: _getCategoryColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                todayRecommendation!.title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 20,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: GlassCard(
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.accentBlue,
            ),
            const SizedBox(height: 20),
            Text(
              'Failed to load recommendation',
              style: AppTextStyles.headline3.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              'The cosmic wisdom seems to be out of reach...',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadOrGenerateRecommendation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: Text('Retry Connection', style: AppTextStyles.button),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 今日邀请卡片
          GlassCard(
            color: AppColors.cardDark.withAlpha(127),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.star_outline,
                      color: AppColors.lightBlue,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Today's Cosmic Invitation",
                      style: AppTextStyles.headline3.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  todayRecommendation!.description,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textLight,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // 主要操作按钮
          if (!todayRecommendation!.completed) ...[
            _buildActionButton(
              'Complete This Journey',
              Icons.check_circle_outline,
              _markAsCompleted,
              gradient: AppColors.accentGradient,
            ),
          ] else ...[
            _buildCompletedCard(),
          ],

          const SizedBox(height: 16),

          // 呼吸练习按钮
          _buildActionButton(
            'Stellar Breathing Exercise',
            Icons.air,
            _startBreathingExercise,
            isOutlined: true,
          ),

          const SizedBox(height: 16),

          // 冥想按钮
          _buildActionButton(
            'Cosmic Meditation',
            Icons.self_improvement,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MeditationScreen(),
                ),
              );
            },
            isOutlined: true,
            gradient: AppColors.magicGradient,
          ),

          const SizedBox(height: 24),

          // 类别信息
          GlassCard(
            color: AppColors.cardLight.withAlpha(76),
            borderRadius: 15,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getCategoryColor().withAlpha(25),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getCategoryColor().withAlpha(127),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _getCategoryIcon(todayRecommendation!.category),
                    color: _getCategoryColor(),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textGray,
                        ),
                      ),
                      Text(
                        _getCategoryLabel(todayRecommendation!.category),
                        style: TextStyle(
                          color: _getCategoryColor(),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
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
                    gradient: LinearGradient(
                      colors: [
                        _getCategoryColor().withAlpha(63),
                        _getCategoryColor().withAlpha(127),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('🌟', style: const TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onPressed, {
    bool isOutlined = false,
    List<Color>? gradient,
  }) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          side: BorderSide(
            color: gradient != null
                ? gradient.first
                : AppColors.accentBlue.withAlpha(127),
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: gradient != null ? gradient.first : AppColors.accentBlue,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: gradient != null ? gradient.first : AppColors.accentBlue,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient ?? AppColors.accentGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: (gradient?.first ?? AppColors.accentBlue).withAlpha(127),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            width: double.infinity,
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedCard() {
    return GlassCard(
      color: AppColors.success.withAlpha(25),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(63),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: AppColors.success,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mission Accomplished!',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Your self-care journey today is complete!',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.success.withAlpha(191),
                    ),
                  ),
                ],
              ),
            ),
            const Text('🌠', style: TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor() {
    switch (todayRecommendation?.category) {
      case 'nature':
        return const Color(0xFF4CAF50);
      case 'art':
        return const Color(0xFF9C27B0);
      case 'food':
        return const Color(0xFFFF9800);
      case 'music':
        return const Color(0xFFE91E63);
      case 'exercise':
        return AppColors.accentBlue;
      default:
        return AppColors.lightBlue;
    }
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'nature':
        return 'Nature Connection';
      case 'art':
        return 'Creative Art';
      case 'food':
        return 'Nourishment';
      case 'music':
        return 'Sound Healing';
      case 'exercise':
        return 'Movement';
      default:
        return category;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'nature':
        return Icons.park;
      case 'art':
        return Icons.palette;
      case 'food':
        return Icons.restaurant;
      case 'music':
        return Icons.music_note;
      case 'exercise':
        return Icons.fitness_center;
      default:
        return Icons.star;
    }
  }
}

// 星空绘画器
class StarFieldPainter extends CustomPainter {
  final double animationValue;

  StarFieldPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final random = Random(42); // 固定种子以获得一致的星星位置

    // 绘制背景渐变
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: AppColors.spaceGradient,
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 绘制大星星
    for (int i = 0; i < 15; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final offset = animationValue * 100;
      final finalX = (x + offset) % size.width;

      final radius = 1.5 + random.nextDouble() * 1.5;
      final alpha = (150 + random.nextDouble() * 105).toInt();

      paint.color = Colors.white.withAlpha(alpha);
      canvas.drawCircle(Offset(finalX, y), radius, paint);
    }

    // 绘制小星星
    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final offset = animationValue * 50;
      final finalX = (x - offset) % size.width;

      final radius = 0.5 + random.nextDouble() * 1.0;
      final alpha = (100 + random.nextDouble() * 155).toInt();

      paint.color = Colors.white.withAlpha(alpha);
      canvas.drawCircle(Offset(finalX, y), radius, paint);
    }

    // 绘制遥远的星星（更多，更小）
    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;

      final radius = 0.2 + random.nextDouble() * 0.5;
      final alpha = (50 + random.nextDouble() * 100).toInt();

      paint.color = Colors.white.withAlpha(alpha);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // 绘制星云效果
    final nebulaPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [const Color(0xFF9C27B0).withAlpha(25), Colors.transparent],
            stops: const [0.1, 1.0],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.7, size.height * 0.3),
              radius: 150,
            ),
          );

    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.3),
      150,
      nebulaPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
