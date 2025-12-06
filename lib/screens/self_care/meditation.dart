import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:math';
import '../../widgets/glass_card.dart';

class MeditationScreen extends StatefulWidget {
  const MeditationScreen({super.key});

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _nebulaController;
  late Animation<double> _nebulaAnimation;

  @override
  void initState() {
    super.initState();
    // 星云动画控制器
    _nebulaController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat(reverse: true);

    _nebulaAnimation = CurvedAnimation(
      parent: _nebulaController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _nebulaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 梦幻星空背景
          _buildDreamyStarfield(),

          // 星云效果
          _buildNebulaEffects(),

          // 漂浮的星系
          _buildFloatingGalaxies(),

          // 主内容
          Padding(
            padding: const EdgeInsets.only(top: 100),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 标题
                        Text(
                          'Cosmic Meditation',
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.5,
                            height: 1.1,
                            shadows: [
                              Shadow(
                                color: Colors.purple,
                                blurRadius: 20,
                                offset: Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Journey through inner space',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.lightBlue.withAlpha(191),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // 引导语
                        GlassCard(
                          color: Colors.black.withAlpha(63),
                          blurSigma: 30,
                          borderRadius: 25,
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(
                                Icons.self_improvement,
                                size: 48,
                                color: Colors.white.withAlpha(191),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Find your center in the cosmic flow. Select a meditation to begin your journey.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withAlpha(223),
                                  height: 1.6,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // 冥想卡片网格
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.0,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildDreamyMeditationCard(index),
                      childCount: 6,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),

          // 悬浮星球返回按钮
          Positioned(top: 60, left: 20, child: _buildPlanetBackButton()),
        ],
      ),
    );
  }

  Widget _buildPlanetBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: AnimatedBuilder(
        animation: _nebulaController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + sin(_nebulaAnimation.value * 2 * pi) * 0.05,
            child: Column(
              children: [
                // 简笔画星球本体
                Container(
                  width: 36, // 更小的尺寸
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withAlpha(127),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // 水平线
                      Positioned(
                        left: 9,
                        right: 9,
                        top: 17,
                        child: Container(
                          height: 0.8,
                          color: Colors.white.withAlpha(191),
                        ),
                      ),

                      // 垂直线
                      Positioned(
                        top: 9,
                        bottom: 9,
                        left: 17,
                        child: Container(
                          width: 0.8,
                          color: Colors.white.withAlpha(191),
                        ),
                      ),

                      // 旋转的虚线环
                      Positioned(
                        top: -8,
                        left: -8,
                        right: -8,
                        bottom: -8,
                        child: Transform.rotate(
                          angle: _nebulaAnimation.value * 2 * pi,
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withAlpha(127),
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 返回箭头
                      Positioned.fill(
                        child: Center(
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 文字标签
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Back',
                    style: TextStyle(
                      color: Colors.white.withAlpha(191),
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

Widget _buildDreamyMeditationCard(int index) {
  final List<Map<String, dynamic>> meditations = [
    {
      'title': 'Stellar Sleep',
      'desc': 'Drift into cosmic dreams',
      'icon': Icons.nightlight_round,
      'gradient': [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      'videoId': 'g0jfhRcXtLQ?si=M--kU1H2jrg_MdYQ',
      'emoji': '🌙',
    },
    {
      'title': 'Galactic Calm',
      'desc': 'Find peace in the void',
      'icon': Icons.self_improvement,
      'gradient': [const Color(0xFF9C27B0), const Color(0xFF2196F3)],
      'videoId': 'tuiQxBB67wI?si=4u1umssqihSyThU0',
      'emoji': '🌀',
    },
    {
      'title': 'Nature\'s Orbit',
      'desc': 'Earth harmony in space',
      'icon': Icons.park,
      'gradient': [const Color(0xFF4CAF50), const Color(0xFF2196F3)],
      'videoId': 'AImuCtIokl0?si=IfXVr4pedNz1psFo',
      'emoji': '🌍',
    },
    {
      'title': 'Nebula Focus',
      'desc': 'Clarity in cosmic clouds',
      'icon': Icons.lightbulb_outline,
      'gradient': [const Color(0xFFFF416C), const Color(0xFFFF4B2B)],
      'videoId': 'inpok4MKVLM?si=5s7gG7U6W2Vq6q_Q',
      'emoji': '✨',
    },
    {
      'title': 'Astral Breath',
      'desc': 'Breathe with the universe',
      'icon': Icons.air,
      'gradient': [const Color(0xFF0062FF), const Color(0xFF00E0FF)],
      'videoId': 'd74K6IhXQh8?si=HdQ2vXvzqM3m3k6f',
      'emoji': '🌬️',
    },
    {
      'title': 'Celestial Flow',
      'desc': 'Move with cosmic energy',
      'icon': Icons.waves,
      'gradient': [const Color(0xFFF7971E), const Color(0xFFFFD200)],
      'videoId': 'z3U0udLH974?si=8YH7q5X5X5X5X5X5',
      'emoji': '⚡',
    },
  ];

  final meditation = meditations[index % meditations.length];

  return AnimatedBuilder(
    animation: _nebulaController,
    builder: (context, child) {
      return Transform.translate(
        offset: Offset(0, sin(_nebulaAnimation.value * 2 * pi + index) * 8),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 800),
                pageBuilder: (_, __, ___) => YouTubeMeditationScreen(
                  videoId: meditation['videoId']!,
                  title: meditation['title']!,
                  gradientColors: meditation['gradient']!,
                ),
                transitionsBuilder: (_, animation, __, child) {
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOutCubic,
                    ),
                    child: child,
                  );
                },
              ),
            );
          },
          child: Container(
            // ADD THIS: Fixed height that matches grid cell
            height: 180, // Reduced from previous values
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: meditation['gradient']!,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // 背景光晕
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (meditation['gradient']![0] as Color)
                              .withAlpha(63),
                        ),
                      ),
                    ),

                    // 内容 - COMPACT VERSION
                    Padding(
                      padding: const EdgeInsets.all(16), // Reduced from 20
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 表情符号 - smaller
                          Container(
                            height: 40, // Reduced from 48
                            width: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                meditation['emoji']!,
                                style: const TextStyle(fontSize: 28), // Reduced
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // 标题 - smaller
                          Text(
                            meditation['title']!,
                            style: const TextStyle(
                              fontSize: 16, // Reduced from 18
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 10,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 4),
                          
                          // 描述
                          Text(
                            meditation['desc']!,
                            style: TextStyle(
                              fontSize: 11, // Reduced from 12
                              color: Colors.white.withAlpha(191),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          const Spacer(),
                          
                          // 底部装饰
                          Container(
                            height: 1, // Reduced from 2
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withAlpha(127),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 6), // Reduced from 8
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(
                                Icons.play_circle_fill,
                                color: Colors.white.withAlpha(223),
                                size: 18, // Reduced from 20
                              ),
                              Text(
                                'Begin',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(223),
                                  fontSize: 11, // Reduced from 12
                                  fontWeight: FontWeight.w600,
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
          ),
        ),
      );
    },
  );
}

  Widget _buildDreamyStarfield() {
    return AnimatedBuilder(
      animation: _nebulaController,
      builder: (context, child) {
        return CustomPaint(
          painter: DreamyStarfieldPainter(_nebulaAnimation.value),
          child: Container(),
        );
      },
    );
  }

  Widget _buildNebulaEffects() {
    return AnimatedBuilder(
      animation: _nebulaController,
      builder: (context, child) {
        return Stack(
          children: [
            // 粉色星云
            Positioned(
              top: 100,
              left: -100,
              child: Transform.scale(
                scale: 1.0 + _nebulaAnimation.value * 0.2,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFF00FF).withAlpha(25),
                        const Color(0xFF9C27B0).withAlpha(12),
                        Colors.transparent,
                      ],
                      stops: const [0.1, 0.3, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // 蓝色星云
            Positioned(
              bottom: 100,
              right: -50,
              child: Transform.scale(
                scale: 1.0 + (1 - _nebulaAnimation.value) * 0.2,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF00E0FF).withAlpha(30),
                        const Color(0xFF0062FF).withAlpha(15),
                        Colors.transparent,
                      ],
                      stops: const [0.1, 0.4, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFloatingGalaxies() {
    return AnimatedBuilder(
      animation: _nebulaController,
      builder: (context, child) {
        return Stack(
          children: [
            // 旋转的星系
            Positioned(
              top: 300,
              right: 50,
              child: Transform.rotate(
                angle: _nebulaAnimation.value * 2 * pi,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const SweepGradient(
                      colors: [Color(0xFF9C27B0), Color(0xFF2196F3)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF9C27B0).withAlpha(127),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 漂浮的星星
            for (int i = 0; i < 5; i++)
              Positioned(
                top: 200 + i * 60,
                left: 20 + i * 40,
                child: Transform.translate(
                  offset: Offset(
                    0,
                    sin(_nebulaAnimation.value * 2 * pi + i) * 15,
                  ),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(
                        127 +
                            (sin(_nebulaAnimation.value * 2 * pi + i) * 128)
                                .toInt(),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withAlpha(191),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class DreamyStarfieldPainter extends CustomPainter {
  final double animationValue;

  DreamyStarfieldPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);

    // 绘制深度星空
    for (int layer = 0; layer < 3; layer++) {
      final speed = (layer + 1) * 0.1;
      final starCount = layer == 0
          ? 30
          : layer == 1
          ? 50
          : 100;
      final maxRadius = layer == 0
          ? 2.0
          : layer == 1
          ? 1.5
          : 1.0;
      final minAlpha = layer == 0
          ? 150
          : layer == 1
          ? 100
          : 50;

      for (int i = 0; i < starCount; i++) {
        final paint = Paint()
          ..color = Colors.white.withAlpha(
            minAlpha + (random.nextDouble() * 105).toInt(),
          )
          ..style = PaintingStyle.fill;

        final x = random.nextDouble() * size.width;
        final y = random.nextDouble() * size.height;
        final offsetX = (animationValue * speed * 100) % size.width;
        final finalX = (x + offsetX) % size.width;

        final radius = maxRadius * 0.5 + random.nextDouble() * maxRadius * 0.5;

        // 添加发光效果
        if (layer == 0 && random.nextDouble() > 0.7) {
          final glowPaint = Paint()
            ..color = Colors.white.withAlpha(25)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

          canvas.drawCircle(Offset(finalX, y), radius * 3, glowPaint);
        }

        canvas.drawCircle(Offset(finalX, y), radius, paint);
      }
    }

    // 绘制流星
    final meteorCount = 3;
    for (int i = 0; i < meteorCount; i++) {
      final seed = i * 100;
      final randomMeteor = Random(seed);
      final startX = randomMeteor.nextDouble() * size.width;
      final startY = randomMeteor.nextDouble() * size.height * 0.5;
      final progress = (animationValue + i * 0.2) % 1.0;

      if (progress < 0.3) {
        final meteorX = startX + progress * 300;
        final meteorY = startY + progress * 150;

        final gradient = Paint()
          ..shader =
              LinearGradient(
                colors: [
                  Colors.white.withAlpha(223),
                  const Color(0xFF00E0FF).withAlpha(127),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ).createShader(
                Rect.fromCircle(center: Offset(meteorX, meteorY), radius: 20),
              );

        canvas.drawCircle(
          Offset(meteorX, meteorY),
          4,
          Paint()..color = Colors.white,
        );

        canvas.drawCircle(Offset(meteorX, meteorY), 15, gradient);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class YouTubeMeditationScreen extends StatefulWidget {
  final String videoId;
  final String title;
  final List<Color> gradientColors;

  const YouTubeMeditationScreen({
    super.key,
    required this.videoId,
    required this.title,
    required this.gradientColors,
  });

  @override
  State<YouTubeMeditationScreen> createState() =>
      _YouTubeMeditationScreenState();
}

class _YouTubeMeditationScreenState extends State<YouTubeMeditationScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebViewController();
  }

  void _initializeWebViewController() {
    final WebViewController controller = WebViewController();

    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    controller.setBackgroundColor(const Color(0x00000000));

    controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (String url) {
          setState(() {
            _isLoading = true;
          });
        },
        onPageFinished: (String url) {
          setState(() {
            _isLoading = false;
          });
        },
      ),
    );

    controller.loadRequest(
      Uri.parse(
        'https://www.youtube.com/embed/${widget.videoId}?autoplay=1&playsinline=1',
      ),
    );

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: GlassCard(
            color: Colors.black.withAlpha(127),
            borderRadius: 20,
            padding: const EdgeInsets.all(8),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 背景渐变
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.gradientColors,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // WebView
          Positioned.fill(child: WebViewWidget(controller: _controller)),

          // 加载动画
          if (_isLoading)
            Container(
              color: Colors.black.withAlpha(191),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Connecting to cosmic stream...',
                      style: TextStyle(
                        color: Colors.white.withAlpha(191),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 底部控制栏
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: GlassCard(
              color: Colors.black.withAlpha(127),
              borderRadius: 20,
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Icons.volume_up, color: Colors.white),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.timer, color: Colors.white),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.airplay, color: Colors.white),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
