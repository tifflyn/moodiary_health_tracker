import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  late HomeScreenController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller = HomeScreenController(context);
      _controller.initState();
      // Force rebuild after controller initialization
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _refreshData() {
    _controller.refreshAllData().then((_) {
      if (mounted) setState(() {});
    });
  }

  // Add a method to rebuild the view when controller data changes
  void _forceRebuild() {
    if (mounted) setState(() {});
  }

  // ==================== 惊艳组件开始 ====================

  Widget homeContent() {
    final authProvider = Provider.of<AuthProvider>(context);
    final nickname = authProvider.user.nickname;

    return NotificationListener<ScrollNotification>(
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  DateFormat('MMM d').format(DateTime.now()),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textGray,
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
                  child: Column(
                    children: [
                      SizedBox(height: 180, child: _buildMinimalChart()),
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
                  color: AppColors.primaryBlue.withAlpha(76),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.insights,
                        size: 32,
                        color: AppColors.accentBlue,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${_controller.weekLogs.length}',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'logs this week',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textGray,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.accentGradient,
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
    final spots = _controller.getLineChartData();

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
    if (_controller.weekLogs.isEmpty) {
      return Text('No data yet', style: AppTextStyles.caption);
    }

    final avgIntensity =
        _controller.weekLogs
            .map((log) => log.intensity)
            .reduce((a, b) => a + b) /
        _controller.weekLogs.length;

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
          value: _controller.weekLogs
              .map((log) => log.intensity)
              .reduce((a, b) => a > b ? a : b)
              .toString(),
          unit: '/5',
          color: AppColors.success,
        ),
        _buildStatItem(
          label: 'Consistency',
          value: '${_controller.calculateConsistency()}%',
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
    final completedTasks = _controller.getCompletedTasks();
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
                        ? [AppColors.success, const Color(0xFF4CAF50)]
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
                      // 进度圆环
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress == 1
                              ? AppColors.success
                              : AppColors.accentBlue,
                        ),
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
                        completed: _controller.emotionLogged,
                        icon: Icons.mood,
                      ),
                      const SizedBox(height: 12),
                      _buildTaskItemCompact(
                        title: 'Daily Check-In',
                        completed: _controller.checkInCompleted,
                        icon: Icons.edit_note,
                      ),
                      const SizedBox(height: 12),
                      _buildTaskItemCompact(
                        title: 'Breathing',
                        completed: _controller.breathingExerciseCompleted,
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
                    ? AppColors.success.withAlpha(51)
                    : AppColors.cardLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                completed ? Icons.check : icon,
                size: 16,
                color: completed ? AppColors.success : AppColors.textGray,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: completed ? AppColors.success : Colors.white,
                  fontWeight: FontWeight.w500,
                  decoration: completed ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            Icon(
              completed ? Icons.check_circle : Icons.arrow_forward_ios,
              size: 16,
              color: completed ? AppColors.success : AppColors.textGray,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayEntriesSection() {
    final todayLogs = _controller.getTodayLogs();

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
    final color = _controller.getEmotionColor(log.emotion);

    return GlassCard(
      padding: const EdgeInsets.all(16),
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
                _controller.getEmotionIcon(log.emotion),
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
                      _controller.getEnergyLabel(log.emotion),
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

              if (confirm == true) {
                _controller.deleteLog(log.id).then((_) => _refreshData());
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
                      Icon(greetingIcon, size: 18, color: AppColors.lightBlue),
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

          // 快速情绪选择
          _buildQuickEmotionSelector(),
        ],
      ),
    );
  }

  Widget _buildQuickEmotionSelector() {
    final todayLogs = _controller.getTodayLogs();
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
    final color = _controller.getEmotionColor(emotion);
    final icon = _controller.getEmotionIcon(emotion);

    return GestureDetector(
      onTap: () async {
        // 快速记录情绪
        final log = EmotionLog(
          emotion: emotion,
          intensity: _controller.getIntensityForEmotion(emotion),
          note: '',
          dateTime: DateTime.now(),
        );

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userId = authProvider.user.id;

        try {
          await _controller.firebaseService.addEmotionLog(userId, log);
          _refreshData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Logged: $label'), backgroundColor: color),
          );
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
        backgroundColor: AppColors.primaryDark,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accentBlue),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
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
            colors: AppColors.bgGradient,
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
              margin: const EdgeInsets.only(bottom: 80),
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
