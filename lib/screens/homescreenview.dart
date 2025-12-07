// lib/screens/homescreenview.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import '../models/emotionlog.dart';
import '../providers/auth_provider.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../widgets/glass_card.dart';
import 'logemotionscreen.dart';
import 'ai_chatbot_screen.dart';
import 'self_care/daily_recommendation_screen.dart';
import 'profile_screen.dart';
import 'check_in/diary_screen.dart';
import 'check_in/check_in_screen.dart';
import 'homescreencontroller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  HomeScreenController? _controller;
  int _currentIndex = 0;
  final Random _random = Random(42);

  // 动画控制器 - 为星座和问候图标旋转
  late AnimationController _animationController;
  late Animation<double> _starsAnimation;
  late Animation<double> _iconsAnimation;

  @override
  void initState() {
    super.initState();
    _controller = HomeScreenController(context);

    // 初始化动画
    _animationController = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    )..repeat(reverse: false);

    _starsAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    );

    _iconsAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _controller != null) {
        _controller!.initState();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  void _refreshData() {
    _controller?.refreshAllData().then((_) {
      if (mounted) setState(() {});
    });
  }

  // 辅助方法：安全地访问 controller
  HomeScreenController get controller {
    if (_controller == null) {
      // 如果 controller 为空，创建一个新的
      _controller = HomeScreenController(context);
      _controller!.initState();
    }
    return _controller!;
  }

  // ==================== 背景组件 ====================

  // 静态星空背景 - 使用 DiaryScreen 的灰蓝色渐变
  Widget _buildStaticStarfield() {
    return Stack(
      children: [
        // 基础渐变背景
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF0A0E1F), // 更深的星空色
                const Color(0xFF1A1A2E),
                const Color(0xFF16213E),
                const Color(0xFF0F3460),
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
        ),

        // 星云效果
        CustomPaint(painter: NebulaPainter(_random)),

        // 星空
        CustomPaint(painter: DreamyStarFieldPainter(_random, _starsAnimation)),

        // 银河带效果
        Positioned(
          top: MediaQuery.of(context).size.height * 0.3,
          left: 0,
          right: 0,
          child: CustomPaint(painter: MilkyWayPainter()),
        ),
      ],
    );
  }

  // 北极星装饰（带轻微转动）
  Widget _buildConstellations() {
    return Stack(
      children: [
        // 星座容器 - 使用位置偏移创造空间感
        Positioned(
          top: 80,
          left: 30,
          child: _buildDreamyConstellation(
            painter: SouthernCrossPainterV2(),
            size: 120,
            color: const Color(0xFF64B5F6),
            glow: true,
          ),
        ),

        Positioned(
          top: 200,
          right: 40,
          child: _buildDreamyConstellation(
            painter: OrionPainterV2(),
            size: 160,
            color: const Color(0xFF9575CD),
            glow: true,
          ),
        ),

        Positioned(
          bottom: 180,
          left: MediaQuery.of(context).size.width * 0.2,
          child: _buildDreamyConstellation(
            painter: UrsaMajorPainterV2(),
            size: 140,
            color: const Color(0xFF4FC3F7),
            glow: true,
          ),
        ),

        Positioned(
          bottom: 100,
          right: 50,
          child: _buildDreamyConstellation(
            painter: CassiopeiaPainter(), // 新增仙后座
            size: 100,
            color: const Color(0xFFE57373),
            glow: true,
          ),
        ),
      ],
    );
  }

  // 梦幻星座组件
  Widget _buildDreamyConstellation({
    required CustomPainter painter,
    required double size,
    required Color color,
    bool glow = false,
  }) {
    return AnimatedBuilder(
      animation: _starsAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            sin(_starsAnimation.value * 2 * pi) * 3, // 轻微浮动
            cos(_starsAnimation.value * 4 * pi) * 2,
          ),
          child: Transform.scale(
            scale: 1 + sin(_starsAnimation.value * pi) * 0.02, // 轻微脉动
            child: Container(
              width: size,
              height: size,
              decoration: glow
                  ? BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: color.withAlpha(40),
                          blurRadius: 25,
                          spreadRadius: 5,
                        ),
                      ],
                    )
                  : null,
              child: CustomPaint(painter: painter),
            ),
          ),
        );
      },
    );
  }

  // ==================== 主内容组件 ====================

  Widget homeContent() {
    // 添加空检查
    if (_controller == null) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.accentBlue),
      );
    }

    final authProvider = Provider.of<AuthProvider>(context);
    final nickname = authProvider.user.nickname;

    return Stack(
      children: [
        // 静态星空背景
        _buildStaticStarfield(),

        _buildConstellations(),

        // 主内容
        NotificationListener<ScrollNotification>(
          onNotification: (notification) => false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              children: [
                _buildHeroHeader(nickname),
                _buildWeeklyChartSection(),
                _buildDailyTasksSection(),
                _buildTodayEntriesSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChartSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Column(
        children: [
          // 标题栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Weekly Overview",
                style: AppTextStyles.headline2.copyWith(color: Colors.white),
              ),
              GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                borderRadius: 12,
                color: Colors.black.withAlpha(63),
                child: Text(
                  DateFormat('MMM d').format(DateTime.now()),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.lightBlue,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 双卡片布局
          Row(
            children: [
              // 图表卡片
              Expanded(
                flex: 3,
                child: GlassCard(
                  color: Colors.black.withAlpha(63),
                  child: Column(
                    children: [
                      SizedBox(height: 150, child: _buildMinimalChart()),
                      const SizedBox(height: 16),
                      _buildChartStats(),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 统计卡片
              Expanded(
                flex: 2,
                child: GlassCard(
                  color: Colors.black.withAlpha(63),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _starsAnimation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _starsAnimation.value * 2 * pi * 0.2,
                            child: Icon(
                              Icons.star,
                              size: 32,
                              color: AppColors.accentBlue,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${controller.weekLogs.length}',
                        style: AppTextStyles.numberLarge.copyWith(fontSize: 32),
                      ),
                      Text(
                        'logs this week',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.lightBlue,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.accentBlue, AppColors.lightBlue],
                          ),
                          borderRadius: BorderRadius.circular(2),
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

  Widget _buildMinimalChart() {
    final spots = controller.getLineChartData();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: 5,
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.accentBlue,
            barWidth: 3,
            isStrokeCapRound: true,
            shadow: Shadow(
              color: AppColors.accentBlue.withAlpha(76),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.accentBlue.withAlpha(51),
                  AppColors.accentBlue.withAlpha(0),
                ],
                stops: const [0.1, 1.0],
              ),
            ),
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildChartStats() {
    if (controller.weekLogs.isEmpty) {
      return Text('No data yet', style: AppTextStyles.caption);
    }

    final avgIntensity =
        controller.weekLogs
            .map((log) => log.intensity)
            .reduce((a, b) => a + b) /
        controller.weekLogs.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(
          label: 'Avg.',
          value: avgIntensity.toStringAsFixed(1),
          unit: '/5',
          color: AppColors.accentBlue,
        ),
        _buildStatItem(
          label: 'High',
          value: controller.weekLogs
              .map((log) => log.intensity)
              .reduce((a, b) => a > b ? a : b)
              .toString(),
          unit: '/5',
          color: const Color(0xFF4CAF50),
        ),
        _buildStatItem(
          label: 'Consistency',
          value: '${controller.calculateConsistency()}%',
          unit: '',
          color: AppColors.lightBlue,
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: AppTextStyles.caption.copyWith(color: AppColors.textGray),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textGray),
        ),
      ],
    );
  }

  Widget _buildDailyTasksSection() {
    final completedTasks = controller.getCompletedTasks();
    final totalTasks = 3;
    final progress = completedTasks / totalTasks;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Wellness',
                style: AppTextStyles.headline2.copyWith(color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: progress == 1
                        ? [const Color(0xFF4CAF50), const Color(0xFF2E7D32)]
                        : AppColors.accentGradient,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$completedTasks/$totalTasks',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 进度圆环和任务列表
          GlassCard(
            color: Colors.black.withAlpha(63),
            child: Row(
              children: [
                // 进度圆环
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 背景圆环
                      CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 8,
                        color: AppColors.cardDark,
                      ),
                      // 进度圆环 - 发光电池效果
                      AnimatedBuilder(
                        animation: _starsAnimation,
                        builder: (context, child) {
                          return CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 8,
                            strokeCap: StrokeCap.round,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress == 1
                                  ? const Color(0xFF4CAF50)
                                  : AppColors.accentBlue,
                            ),
                          );
                        },
                      ),
                      // 中间内容
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${(progress * 100).toInt()}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '%',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textGray,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 20),

                // 任务列表
                Expanded(
                  child: Column(
                    children: [
                      _buildTaskItemCompact(
                        title: 'Emotion Log',
                        completed: controller.emotionLogged,
                        icon: Icons.mood,
                      ),
                      const SizedBox(height: 12),
                      _buildTaskItemCompactWithCallback(
                        title: 'Daily Check-In',
                        completed: controller.checkInCompleted,
                        icon: Icons.edit_note,
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CheckInScreen(),
                            ),
                          );

                          if (result == true) {
                            _refreshData();
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildTaskItemCompact(
                        title: 'Breathing',
                        completed: controller.breathingExerciseCompleted,
                        icon: Icons.air,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItemCompact({
    required String title,
    required bool completed,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () {
        // 根据任务类型跳转
        if (title == 'Emotion Log') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LogEmotionScreen()),
          ).then((_) => _refreshData());
        } else if (title == 'Daily Check-In') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CheckInScreen()),
          ).then((_) => _refreshData());
        } else if (title == 'Breathing') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DailyRecommendationScreen(),
            ),
          ).then((_) => _refreshData());
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: completed
                    ? const Color(0xFF4CAF50).withAlpha(51)
                    : AppColors.cardLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                completed ? Icons.check : icon,
                size: 16,
                color: completed ? const Color(0xFF4CAF50) : AppColors.textGray,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: completed ? const Color(0xFF4CAF50) : Colors.white,
                  fontWeight: FontWeight.w500,
                  decoration: completed ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            Icon(
              completed ? Icons.check_circle : Icons.arrow_forward_ios,
              size: 16,
              color: completed ? const Color(0xFF4CAF50) : AppColors.textGray,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItemCompactWithCallback({
    required String title,
    required bool completed,
    required IconData icon,
    required Function() onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: completed
                    ? const Color(0xFF4CAF50).withAlpha(51)
                    : AppColors.cardLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                completed ? Icons.check : icon,
                size: 16,
                color: completed ? const Color(0xFF4CAF50) : AppColors.textGray,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: completed ? const Color(0xFF4CAF50) : Colors.white,
                  fontWeight: FontWeight.w500,
                  decoration: completed ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            Icon(
              completed ? Icons.check_circle : Icons.arrow_forward_ios,
              size: 16,
              color: completed ? const Color(0xFF4CAF50) : AppColors.textGray,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayEntriesSection() {
    final todayLogs = controller.getTodayLogs();

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Entries",
                style: AppTextStyles.headline2.copyWith(color: Colors.white),
              ),
              if (todayLogs.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accentBlue.withAlpha(76),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${todayLogs.length} entries',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.accentBlue,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          if (todayLogs.isEmpty)
            GlassCard(
              color: Colors.black.withAlpha(63),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.psychology_outlined,
                      size: 60,
                      color: AppColors.textGray.withAlpha(127),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No entries yet today',
                      style: TextStyle(
                        color: AppColors.textGray,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start by logging your current energy!',
                      style: AppTextStyles.caption,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...todayLogs.reversed
                .map(
                  (log) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: _buildModernLogEntry(log),
                  ),
                )
                .toList(),
        ],
      ),
    );
  }

  Widget _buildModernLogEntry(EmotionLog log) {
    final color = controller.getEmotionColor(log.emotion);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      color: Colors.black.withAlpha(63),
      child: Row(
        children: [
          // 情绪图标
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withAlpha(76), color.withAlpha(25)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                controller.getEmotionIcon(log.emotion),
                color: color,
                size: 28,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // 内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      controller.getEnergyLabel(log.emotion),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: color.withAlpha(76),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${log.intensity}/5',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: AppColors.textGray,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('h:mm a').format(log.dateTime),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),

                if (log.note.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      log.note,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textGray,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 删除按钮
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red.withAlpha(150)),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Delete Entry"),
                  content: const Text(
                    "Are you sure you want to delete this emotion entry?",
                  ),
                  actions: [
                    TextButton(
                      child: const Text("Cancel"),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    TextButton(
                      child: const Text(
                        "Delete",
                        style: TextStyle(color: Colors.red),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                _controller?.deleteLog(log.id).then((_) => _refreshData());
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(String nickname) {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting = 'Good Morning';
    IconData greetingIcon = Icons.wb_sunny_outlined;

    if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
      greetingIcon = Icons.wb_twilight_outlined;
    } else if (hour >= 17) {
      greeting = 'Good Evening';
      greetingIcon = Icons.nightlight_outlined;
    }

    // 获取用户的首字母作为头像
    final initials = nickname.isNotEmpty && nickname.length > 1
        ? nickname.substring(0, 2).toUpperCase()
        : 'U';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentBlue.withAlpha(50),
            AppColors.primaryBlue.withAlpha(30),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _iconsAnimation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _iconsAnimation.value * 2 * pi, // 旋转图标
                            child: Icon(
                              greetingIcon,
                              size: 18,
                              color: AppColors.lightBlue,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        greeting,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.lightBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, MMMM d').format(DateTime.now()),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ),

              // 用户头像
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.accentGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentBlue.withAlpha(76),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // 主标题
          Text(
            nickname.isNotEmpty ? 'Hi, $nickname' : 'Welcome',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),

          Text(
            'How are you feeling today?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: AppColors.textGray,
            ),
          ),

          const SizedBox(height: 24),

          // 快速情绪选择 - 保留原来的情绪标签
          _buildQuickEmotionSelector(),
        ],
      ),
    );
  }

  Widget _buildQuickEmotionSelector() {
    final todayLogs = controller.getTodayLogs();
    final currentEnergy = todayLogs.isNotEmpty ? todayLogs.last.emotion : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Log',
          style: AppTextStyles.headline3.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 12),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildEmotionChip(
                emotion: 'fully_charged',
                label: 'High',
                isSelected: currentEnergy == 'fully_charged',
              ),
              const SizedBox(width: 12),
              _buildEmotionChip(
                emotion: 'energized',
                label: 'Good',
                isSelected: currentEnergy == 'energized',
              ),
              const SizedBox(width: 12),
              _buildEmotionChip(
                emotion: 'medium_energy',
                label: 'Medium',
                isSelected: currentEnergy == 'medium_energy',
              ),
              const SizedBox(width: 12),
              _buildEmotionChip(
                emotion: 'running_low',
                label: 'Low',
                isSelected: currentEnergy == 'running_low',
              ),
              const SizedBox(width: 12),
              _buildEmotionChip(
                emotion: 'totally_drained',
                label: 'Drained',
                isSelected: currentEnergy == 'totally_drained',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmotionChip({
    required String emotion,
    required String label,
    required bool isSelected,
  }) {
    final color = controller.getEmotionColor(emotion);
    final icon = controller.getEmotionIcon(emotion);

    return GestureDetector(
      onTap: () async {
        if (!mounted) return;

        // 快速记录情绪
        final log = EmotionLog(
          emotion: emotion,
          intensity: controller.getIntensityForEmotion(emotion),
          note: '',
          dateTime: DateTime.now(),
        );

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userId = authProvider.user.id;

        try {
          await _controller?.firebaseService.addEmotionLog(userId, log);
          _refreshData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Logged: $label'), backgroundColor: color),
            );
          }
        } catch (e) {
          debugPrint('Error logging emotion: $e');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withAlpha(25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : color.withAlpha(76),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withAlpha(76),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassNavBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              selectedItemColor: AppColors.accentBlue,
              unselectedItemColor: AppColors.textGray,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.book_outlined),
                  activeIcon: Icon(Icons.book),
                  label: 'Diary',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline),
                  activeIcon: Icon(Icons.chat_bubble),
                  label: 'AI Chat',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.self_improvement_outlined),
                  activeIcon: Icon(Icons.self_improvement),
                  label: 'Self-care',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outlined),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
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
    // Check if controller is initialized
    if (_controller == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A2E), // 使用 DiaryScreen 的背景色
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accentBlue),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // 使用 DiaryScreen 的背景色
      extendBody: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text(
          'Mental Health Tracker',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1A1A2E), // 深蓝灰
              Color(0xFF16213E), // 中蓝灰
              Color(0xFF0F3460), // 深蓝
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _currentIndex == 0
            ? homeContent()
            : _currentIndex == 1
            ? const DiaryScreen()
            : _currentIndex == 2
            ? const AIChatbotScreen()
            : _currentIndex == 3
            ? const DailyRecommendationScreen()
            : const ProfileScreen(),
      ),

      // 底部导航栏改成玻璃态
      bottomNavigationBar: _buildGlassNavBar(),

      floatingActionButton: _currentIndex == 0
          ? Container(
              margin: const EdgeInsets.only(bottom: 0),
              child: FloatingActionButton.extended(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LogEmotionScreen(),
                    ),
                  );
                  _refreshData();
                },
                backgroundColor: AppColors.accentBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Log Emotion',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class NebulaPainter extends CustomPainter {
  final Random random;

  NebulaPainter(this.random);

  @override
  void paint(Canvas canvas, Size size) {
    // 创建多个柔和的光晕作为星云
    final nebulaColors = [
      const Color(0xFF1E3A8A).withAlpha(15),
      const Color(0xFF3730A3).withAlpha(10),
      const Color(0xFF5B21B6).withAlpha(8),
      const Color(0xFF7C3AED).withAlpha(5),
    ];

    for (int i = 0; i < 4; i++) {
      final paint = Paint()
        ..color = nebulaColors[i]
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 80 + i * 20);

      final center = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      final radius = 80 + random.nextDouble() * 120;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 梦幻星空
class DreamyStarFieldPainter extends CustomPainter {
  final Random random;
  final Animation<double> animation;

  DreamyStarFieldPainter(this.random, this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // 绘制不同大小的星星
    for (int i = 0; i < 80; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;

      // 星星大小和透明度根据位置变化
      final distanceFromCenter =
          (Offset(x, y) - Offset(size.width / 2, size.height / 2)).distance;
      final normalizedDistance = distanceFromCenter / (size.width / 2);

      // 闪烁效果
      final flicker = (sin(animation.value * pi * 2 + i * 0.1) + 1) / 2;

      // 小星星
      if (i % 3 == 0) {
        paint.color = Colors.white.withAlpha((30 + flicker * 40).toInt());
        final radius = 0.1 + random.nextDouble() * 0.3;
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
      // 中等星星
      else if (i % 3 == 1) {
        paint.color = const Color(
          0xFFB3E5FC,
        ).withAlpha((60 + flicker * 60).toInt());
        final radius = 0.3 + random.nextDouble() * 0.5;
        canvas.drawCircle(Offset(x, y), radius, paint);

        // 光晕
        final glowPaint = Paint()
          ..color = const Color(0xFFB3E5FC).withAlpha(20)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawCircle(Offset(x, y), radius * 2, glowPaint);
      }
      // 大星星
      else {
        paint.color = Colors.white.withAlpha((100 + flicker * 80).toInt());
        final radius = 0.6 + random.nextDouble() * 0.8;
        canvas.drawCircle(Offset(x, y), radius, paint);

        // 更强的光晕
        final glowPaint = Paint()
          ..color = Colors.white.withAlpha(40)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(Offset(x, y), radius * 3, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 银河带
class MilkyWayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0x1AFFFFFF), // 非常浅的白色
          const Color(0x33B3E5FC), // 浅蓝
          const Color(0x1AFFFFFF),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
      ).createShader(Rect.fromLTRB(0, 0, size.width, 100))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, 100), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 南十字星 V2
class SouthernCrossPainterV2 extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final starPaint = Paint()
      ..color = const Color(0xFF64B5F6).withAlpha(200)
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = const Color(0xFF64B5F6).withAlpha(40)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final linePaint = Paint()
      ..color = const Color(0xFF64B5F6).withAlpha(120)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 主星
    final stars = [
      Offset(size.width * 0.5, size.height * 0.3),
      Offset(size.width * 0.5, size.height * 0.7),
      Offset(size.width * 0.3, size.height * 0.5),
      Offset(size.width * 0.7, size.height * 0.5),
    ];

    // 绘制光晕
    for (final star in stars) {
      canvas.drawCircle(star, 10, glowPaint);
      canvas.drawCircle(star, 3, starPaint);
    }

    // 连接线条 - 只连接形成十字
    canvas.drawLine(stars[0], stars[1], linePaint);
    canvas.drawLine(stars[2], stars[3], linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 猎户座 V2
class OrionPainterV2 extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final starPaint = Paint()
      ..color = const Color(0xFF9575CD).withAlpha(220)
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = const Color(0xFF9575CD).withAlpha(50)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final linePaint = Paint()
      ..color = const Color(0xFF9575CD).withAlpha(100)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 猎户座主要星星
    final stars = [
      Offset(size.width * 0.3, size.height * 0.4), // 左肩
      Offset(size.width * 0.7, size.height * 0.3), // 右肩
      Offset(size.width * 0.25, size.height * 0.65), // 左腰带
      Offset(size.width * 0.5, size.height * 0.6), // 中腰带
      Offset(size.width * 0.75, size.height * 0.55), // 右腰带
      Offset(size.width * 0.2, size.height * 0.85), // 左脚
      Offset(size.width * 0.8, size.height * 0.8), // 右脚
    ];

    // 绘制光晕和星星
    for (final star in stars) {
      canvas.drawCircle(star, 12, glowPaint);
      canvas.drawCircle(star, 2.5, starPaint);
    }

    // 连接线条 - 形成更优雅的形状
    canvas.drawLine(stars[0], stars[2], linePaint);
    canvas.drawLine(stars[1], stars[4], linePaint);

    // 腰带
    for (int i = 2; i < 4; i++) {
      canvas.drawLine(stars[i], stars[i + 1], linePaint);
    }

    // 腿
    canvas.drawLine(stars[2], stars[5], linePaint);
    canvas.drawLine(stars[4], stars[6], linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 大熊座 V2
class UrsaMajorPainterV2 extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final starPaint = Paint()
      ..color = const Color(0xFF4FC3F7).withAlpha(220)
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = const Color(0xFF4FC3F7).withAlpha(50)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final linePaint = Paint()
      ..color = const Color(0xFF4FC3F7).withAlpha(100)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 北斗七星 + 一些辅助星
    final stars = [
      Offset(size.width * 0.1, size.height * 0.2), // 1
      Offset(size.width * 0.25, size.height * 0.1), // 2
      Offset(size.width * 0.4, size.height * 0.15), // 3
      Offset(size.width * 0.5, size.height * 0.35), // 4
      Offset(size.width * 0.7, size.height * 0.45), // 5
      Offset(size.width * 0.6, size.height * 0.65), // 6
      Offset(size.width * 0.4, size.height * 0.75), // 7
    ];

    // 绘制光晕和星星
    for (final star in stars) {
      canvas.drawCircle(star, 10, glowPaint);
      canvas.drawCircle(star, 2.2, starPaint);
    }

    // 连接线条形成北斗形状
    for (int i = 0; i < stars.length - 1; i++) {
      canvas.drawLine(stars[i], stars[i + 1], linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 新增：仙后座（优雅的W形状）
class CassiopeiaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final starPaint = Paint()
      ..color = const Color(0xFFE57373).withAlpha(220)
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = const Color(0xFFE57373).withAlpha(40)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final linePaint = Paint()
      ..color = const Color(0xFFE57373).withAlpha(120)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 仙后座的主要星星（W形状）
    final stars = [
      Offset(size.width * 0.2, size.height * 0.8),
      Offset(size.width * 0.4, size.height * 0.6),
      Offset(size.width * 0.5, size.height * 0.7),
      Offset(size.width * 0.6, size.height * 0.5),
      Offset(size.width * 0.8, size.height * 0.7),
    ];

    // 绘制光晕和星星
    for (final star in stars) {
      canvas.drawCircle(star, 9, glowPaint);
      canvas.drawCircle(star, 2.0, starPaint);
    }

    // 连接形成W形状
    for (int i = 0; i < stars.length - 1; i++) {
      canvas.drawLine(stars[i], stars[i + 1], linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 静态星空绘画器 - 使用 DiaryScreen 的灰蓝色调
class StaticStarFieldPainter extends CustomPainter {
  final Random random;

  StaticStarFieldPainter(this.random);

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制灰蓝色渐变背景（模仿 DiaryScreen）
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF1A1A2E), // 深蓝灰
          Color(0xFF16213E), // 中蓝灰
          Color(0xFF0F3460), // 深蓝
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 绘制微小的背景星星（数量减少，更分散）
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 30; i++) {
      // 进一步减少星星数量
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;

      final radius = 0.2 + random.nextDouble() * 0.4; // 更小的星星
      final alpha = (30 + random.nextDouble() * 60).toInt(); // 更暗的星星

      paint.color = Colors.white.withAlpha(alpha);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // 绘制一些重要的导航星（更明亮）
    final importantStars = [
      Offset(size.width * 0.3, size.height * 0.2),
      Offset(size.width * 0.7, size.height * 0.15),
      Offset(size.width * 0.2, size.height * 0.4),
      Offset(size.width * 0.8, size.height * 0.35),
    ];

    for (final star in importantStars) {
      // 明亮的导航星
      paint.color = Colors.white.withAlpha(120);
      canvas.drawCircle(star, 0.8, paint);

      // 微光晕效果
      final glowPaint = Paint()
        ..color = Colors.white.withAlpha(30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(star, 2, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 南十字星绘画器
class SouthernCrossPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(180)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // 绘制南十字星的四个主要星星
    final stars = [
      Offset(centerX, centerY - 15), // 顶部
      Offset(centerX, centerY + 15), // 底部
      Offset(centerX - 12, centerY), // 左侧
      Offset(centerX + 12, centerY), // 右侧
    ];

    // 绘制星星点
    final starPaint = Paint()
      ..color = Colors.white.withAlpha(200)
      ..style = PaintingStyle.fill;

    for (final star in stars) {
      canvas.drawCircle(star, 1.8, starPaint);

      // 星星微弱光晕
      final glowPaint = Paint()
        ..color = Colors.white.withAlpha(80)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

      canvas.drawCircle(star, 3, glowPaint);
    }

    // 连接线条形成十字
    canvas.drawLine(stars[0], stars[1], paint); // 垂直线
    canvas.drawLine(stars[2], stars[3], paint); // 水平线
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 猎户座绘画器
class OrionConstellationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(150)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final starPaint = Paint()
      ..color = Colors.white.withAlpha(180)
      ..style = PaintingStyle.fill;

    // 猎户座的主要星星（简化版）
    final beltStars = [
      Offset(size.width * 0.3, size.height * 0.5), // 左腰带星
      Offset(size.width * 0.5, size.height * 0.45), // 中腰带星
      Offset(size.width * 0.7, size.height * 0.4), // 右腰带星
    ];

    final shoulderStars = [
      Offset(size.width * 0.4, size.height * 0.2), // 左肩
      Offset(size.width * 0.6, size.height * 0.15), // 右肩
    ];

    final footStars = [
      Offset(size.width * 0.35, size.height * 0.8), // 左脚
      Offset(size.width * 0.65, size.height * 0.75), // 右脚
    ];

    // 绘制所有星星
    final allStars = [...beltStars, ...shoulderStars, ...footStars];
    for (final star in allStars) {
      canvas.drawCircle(star, 1.5, starPaint);

      // 光晕效果
      final glowPaint = Paint()
        ..color = Colors.white.withAlpha(60)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(star, 2.5, glowPaint);
    }

    // 连接腰带星星
    for (int i = 0; i < beltStars.length - 1; i++) {
      canvas.drawLine(beltStars[i], beltStars[i + 1], paint);
    }

    // 连接腰带到肩膀
    canvas.drawLine(beltStars[0], shoulderStars[0], paint);
    canvas.drawLine(beltStars[2], shoulderStars[1], paint);

    // 连接腰带到脚部
    canvas.drawLine(beltStars[0], footStars[0], paint);
    canvas.drawLine(beltStars[2], footStars[1], paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 大熊座（北斗七星）绘画器
class UrsaMajorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(150)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final starPaint = Paint()
      ..color = Colors.white.withAlpha(180)
      ..style = PaintingStyle.fill;

    // 北斗七星的主要星星（简化版）
    final stars = [
      Offset(size.width * 0.1, size.height * 0.2), // 勺子起点
      Offset(size.width * 0.3, size.height * 0.1), //
      Offset(size.width * 0.5, size.height * 0.15), //
      Offset(size.width * 0.6, size.height * 0.3), // 勺子底部
      Offset(size.width * 0.8, size.height * 0.4), //
      Offset(size.width * 0.7, size.height * 0.6), // 勺子柄
      Offset(size.width * 0.5, size.height * 0.7), // 勺子柄末端
    ];

    // 绘制所有星星
    for (final star in stars) {
      canvas.drawCircle(star, 1.5, starPaint);

      // 光晕效果
      final glowPaint = Paint()
        ..color = Colors.white.withAlpha(60)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(star, 2.5, glowPaint);
    }

    // 连接星星形成北斗七星
    for (int i = 0; i < stars.length - 1; i++) {
      canvas.drawLine(stars[i], stars[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
