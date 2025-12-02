import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/emotionlog.dart';
import 'logemotionscreen.dart';
import 'ai_chatbot_screen.dart';
import 'self_care/daily_recommendation_screen.dart';
import 'profile_screen.dart';
import 'check_in/diary_screen.dart';
import 'check_in/check_in_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/charts.dart';
import '../services/firebase_service.dart'; // 添加这一行
import 'dart:developer'; // 添加这行，用于 debugPrint
import '../models/check_in.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<EmotionLog> weekLogs = [];
  bool isLoading = true;
  bool showLineChart = false;
  int _currentIndex = 0;

  // To-do list completion states
  bool emotionLogged = false;
  bool checkInCompleted = false;
  bool breathingExerciseCompleted = false;

  StreamSubscription<List<EmotionLog>>? _emotionSubscription;

  @override
  void initState() {
    super.initState();
    // 先立即加载一次
    loadWeekData();
    // 然后设置实时监听
    _setupRealTimeListener();
  }

  // 添加实时监听方法
  void _setupRealTimeListener() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user.id;

    if (userId.isEmpty) return;

    try {
      _emotionSubscription?.cancel();
      _emotionSubscription = FirebaseService.instance
          .getEmotionLogs(userId)
          .listen(
            (emotions) {
              if (mounted) {
                _processEmotions(emotions);
              }
            },
            onError: (error) {
              debugPrint('Error in emotion stream: $error');
            },
          );
    } catch (e) {
      debugPrint('Error setting up real-time listener: $e');
    }
  }

  // 处理情绪数据的方法
  void _processEmotions(List<EmotionLog> emotions) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(
      const Duration(days: 6, hours: 23, minutes: 59),
    );

    // 过滤出本周的数据
    final weekEmotions = emotions.where((log) {
      return log.dateTime.isAfter(startOfWeek) &&
          log.dateTime.isBefore(endOfWeek);
    }).toList();

    if (mounted) {
      setState(() {
        weekLogs = weekEmotions;
        isLoading = false;

        // 检查今天是否记录了情绪（用于 TodoList）
        final todayLogs = _getTodayLogsFromList(weekEmotions);
        emotionLogged = todayLogs.isNotEmpty;
      });
    }
  }

  // 从列表中获取今天的日志
  List<EmotionLog> _getTodayLogsFromList(List<EmotionLog> allLogs) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return allLogs
        .where((log) => DateFormat('yyyy-MM-dd').format(log.dateTime) == today)
        .toList();
  }

  Future<void> loadWeekData() async {
    setState(() => isLoading = true);

    // 获取当前用户ID
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user.id;

    if (userId.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(
      const Duration(days: 6, hours: 23, minutes: 59),
    );

    try {
      // 切换到 FirebaseService
      final logs = await FirebaseService.instance.getEmotionsForDateRange(
        userId,
        startOfWeek,
        endOfWeek,
      );

      if (mounted) {
        setState(() {
          weekLogs = logs;
          isLoading = false;

          // 检查今天是否记录了情绪
          final todayLogs = _getTodayLogsFromList(logs);
          emotionLogged = todayLogs.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Error loading week data from Firebase: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
      // 可选：显示错误提示给用户
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
    }
  }

  // 在 dispose 方法中添加
  @override
  void dispose() {
    _emotionSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadCompletionStates() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user.id;

    if (userId.isEmpty) return;

    try {
      // 1. Check if emotions were logged today
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final todayEmotions = await FirebaseService.instance
          .getEmotionsForDateRange(userId, todayStart, todayEnd);

      // 2. Check if there are check-ins today
      List<CheckIn> todayCheckIns = [];
      try {
        // Try using the new getTodayCheckIns method
        todayCheckIns = await FirebaseService.instance.getTodayCheckIns(userId);
        debugPrint('✅ Today\'s check-ins count: ${todayCheckIns.length}');
      } catch (e) {
        debugPrint('⚠️ Failed to use getTodayCheckIns: $e');
        // Fallback: use getRecentCheckIns and filter
        final recentCheckIns = await FirebaseService.instance.getRecentCheckIns(
          userId,
          days: 1,
        );
        debugPrint('📊 Recent 1-day check-ins: ${recentCheckIns.length}');

        // Filter out today's records
        todayCheckIns = recentCheckIns.where((checkIn) {
          final checkInDate = DateTime(
            checkIn.timestamp.year,
            checkIn.timestamp.month,
            checkIn.timestamp.day,
          );
          final isToday = checkInDate == todayStart;
          if (isToday) {
            debugPrint(
              '📅 Found today\'s check-in: ${checkIn.title ?? "No title"} at ${checkIn.timestamp}',
            );
          }
          return isToday;
        }).toList();
      }

      // 3. Check if today's recommendation is completed
      final todayRecommendation = await FirebaseService.instance
          .getTodayRecommendation(userId);

      if (mounted) {
        setState(() {
          emotionLogged = todayEmotions.isNotEmpty;
          checkInCompleted = todayCheckIns.isNotEmpty; // ✅ Fixed here
          breathingExerciseCompleted = todayRecommendation?.completed ?? false;
        });

        // Add debug output
        debugPrint('''
✅ Todo status updated:
  Emotion log: ${todayEmotions.isNotEmpty} (${todayEmotions.length} items)
  Check-ins: ${todayCheckIns.isNotEmpty} (${todayCheckIns.length} items)
  Breathing exercise: ${todayRecommendation?.completed ?? false}
''');
      }
    } catch (e) {
      debugPrint('❌ Error loading completion states: $e');
    }
  }

  Future<void> deleteLog(String? emotionId) async {
    // 参数改为 String?
    if (emotionId == null) return;

    // 获取当前用户ID
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user.id;

    if (userId.isEmpty) return;

    try {
      // 切换到 FirebaseService
      await FirebaseService.instance.deleteEmotion(userId, emotionId);

      // 重新加载数据
      await loadWeekData();

      // 显示成功提示
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Emotion entry deleted')));
    } catch (e) {
      debugPrint('Error deleting emotion from Firebase: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
    }
  }

  String getEnergyLabel(String emotion) {
    switch (emotion) {
      case 'totally_drained':
        return 'Totally drained.';
      case 'running_low':
        return 'Running low...';
      case 'medium_energy':
        return 'Medium energy';
      case 'energized':
        return 'Energized!';
      case 'fully_charged':
        return 'Fully charged!!!';
      default:
        return emotion;
    }
  }

  List<DateTime> getWeekDates() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  Map<String, List<EmotionLog>> groupLogsByDate() {
    final Map<String, List<EmotionLog>> grouped = {};
    for (var log in weekLogs) {
      final dateKey = DateFormat('yyyy-MM-dd').format(log.dateTime);
      grouped[dateKey] = [...(grouped[dateKey] ?? []), log];
    }
    return grouped;
  }

  // Get average intensity for each day
  List<FlSpot> getLineChartData() {
    final weekDates = getWeekDates();
    final groupedLogs = groupLogsByDate();
    final spots = <FlSpot>[];

    for (int i = 0; i < weekDates.length; i++) {
      final dateKey = DateFormat('yyyy-MM-dd').format(weekDates[i]);
      final logsForDay = groupedLogs[dateKey] ?? [];

      if (logsForDay.isNotEmpty) {
        final avgIntensity =
            logsForDay.map((log) => log.intensity).reduce((a, b) => a + b) /
            logsForDay.length;
        spots.add(FlSpot(i.toDouble(), avgIntensity.toDouble()));
      } else {
        spots.add(FlSpot(i.toDouble(), 0));
      }
    }

    return spots;
  }

  Color getEmotionColor(String emotion) {
    switch (emotion) {
      case 'totally_drained':
        return Colors.red;
      case 'running_low':
        return Colors.orange;
      case 'medium_energy':
        return Colors.green;
      case 'energized':
        return Colors.blue;
      case 'fully_charged':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData getEmotionIcon(String emotion) {
    switch (emotion) {
      case 'totally_drained':
        return Icons.battery_0_bar;
      case 'running_low':
        return Icons.battery_1_bar;
      case 'medium_energy':
        return Icons.battery_2_bar;
      case 'energized':
        return Icons.battery_3_bar;
      case 'fully_charged':
        return Icons.battery_full;
      default:
        return Icons.battery_unknown;
    }
  }

  Widget homeContent() {
    // 获取 AuthProvider 实例
    final authProvider = Provider.of<AuthProvider>(context);
    final nickname = authProvider.user.nickname;

    final weekDates = getWeekDates();
    final groupedLogs = groupLogsByDate();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🌟 新增：欢迎信息
          Text(
            'Hey, $nickname!', // 使用用户的昵称
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 16),

          // WEEKLY CHART
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'This Week\'s Journey',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.bar_chart,
                              color: !showLineChart
                                  ? Colors.purple
                                  : Colors.grey,
                            ),
                            onPressed: () =>
                                setState(() => showLineChart = false),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.show_chart,
                              color: showLineChart
                                  ? Colors.purple
                                  : Colors.grey,
                            ),
                            onPressed: () =>
                                setState(() => showLineChart = true),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: showLineChart
                        ? buildLineChart(
                            weekDates: weekDates,
                            spots: getLineChartData(),
                            hasData: weekLogs.isNotEmpty,
                          )
                        : buildBarChart(
                            weekDates: weekDates,
                            groupedLogs: groupedLogs,
                            getEmotionColor: getEmotionColor,
                            getEmotionIcon: getEmotionIcon,
                          ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // TO-DO LIST (Replaced "For Your Day")
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Wellness Tasks',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Complete these tasks to maintain your mental wellness:',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 16),

                  // To-Do List Items
                  buildTodoItem(
                    title: 'Log Your Emotions',
                    subtitle: 'Express how you\'re feeling today',
                    icon: Icons.mood,
                    color: Colors.purple,
                    isCompleted: emotionLogged,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LogEmotionScreen(),
                        ),
                      );

                      // Refresh data when returning from LogEmotionScreen
                      await loadCompletionStates();
                    },
                  ),

                  const SizedBox(height: 12),

                  buildTodoItem(
                    title: 'Daily Check-In',
                    subtitle: 'Reflect on your day',
                    icon: Icons.edit_note,
                    color: Colors.orange,
                    isCompleted: checkInCompleted,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CheckInScreen(),
                        ),
                      );

                      // Check if check-in was submitted
                      if (result == true) {
                        // CheckIn 完成后，重新加载状态
                        await loadCompletionStates();
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  buildTodoItem(
                    title: 'Breathing Exercise',
                    subtitle: 'Calm your mind with breathing',
                    icon: Icons.air,
                    color: Colors.blue,
                    isCompleted: breathingExerciseCompleted,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const DailyRecommendationScreen(),
                        ),
                      );

                      // Check if breathing exercise was completed
                      if (result == true) {
                        // 重新加载完成状态
                        await loadCompletionStates();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          // INSIGHTS
          Card(
            elevation: 4,
            color: Colors.purple,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Your Insights',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (weekLogs.isEmpty)
                    const Text(
                      'Start logging your emotions to see patterns and insights!',
                      style: TextStyle(color: Colors.white70),
                    )
                  else
                    ...getInsights().map(
                      (insight) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            insight,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // TODAY'S ENTRIES
          const Text(
            'Today\'s Entries',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          ...getTodayLogs().map(
            (log) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: getEmotionColor(log.emotion),
                  child: Icon(getEmotionIcon(log.emotion), color: Colors.white),
                ),

                title: Text(
                  getEnergyLabel(log.emotion),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('h:mm a').format(log.dateTime)),
                    if (log.note.isNotEmpty) Text(log.note),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${log.intensity}/5',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
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
                          deleteLog(log.id); // 这里现在传递的是 String? id
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (getTodayLogs().isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No entries yet today',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
            ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // Build To-Do List Item
  Widget buildTodoItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCompleted ? Colors.green : color.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green
                    : color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? Icons.check : icon,
                color: isCompleted ? Colors.white : color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? Colors.green : color,
                      fontSize: 16,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isCompleted ? Colors.green : Colors.grey[600],
                      fontSize: 12,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isCompleted ? Icons.check_circle : Icons.arrow_forward_ios,
              color: isCompleted ? Colors.green : color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        title: const Text('Mental Health Tracker'),
        centerTitle: true,
      ),

      body: _currentIndex == 0
          ? homeContent()
          : _currentIndex == 1
          ? const DiaryScreen()
          : _currentIndex == 2
          ? const AIChatbotScreen()
          : _currentIndex == 3
          ? const DailyRecommendationScreen()
          : const ProfileScreen(),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Diary'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'AI Chatbot'),
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: 'Self-care',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),

      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LogEmotionScreen(),
                  ),
                );

                // Refresh data when returning
                await loadCompletionStates();
              },
              backgroundColor: Colors.purple,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Log Emotion',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  List<EmotionLog> getTodayLogs() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return weekLogs
        .where((log) => DateFormat('yyyy-MM-dd').format(log.dateTime) == today)
        .toList();
  }

  List<String> getInsights() {
    if (weekLogs.isEmpty) return [];

    final insights = <String>[];
    final emotionCounts = <String, int>{};

    for (var log in weekLogs) {
      emotionCounts[log.emotion] = (emotionCounts[log.emotion] ?? 0) + 1;
    }

    if (emotionCounts.isNotEmpty) {
      final mostCommon = emotionCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      insights.add(
        'Your most common emotion this week: ${mostCommon.toUpperCase()}',
      );
    }

    final negativeCount = weekLogs
        .where((log) => ['sad', 'anxious', 'angry'].contains(log.emotion))
        .length;

    if (negativeCount >= 5) {
      insights.add(
        'You\'ve had several challenging moments. Consider self-care activities.',
      );
    }

    return insights;
  }
}
