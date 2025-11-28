import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/emotionlog.dart';
import '../services/database_service.dart';
import 'logemotionscreen.dart';
import 'ai_chatbot_screen.dart';
import 'self_care/daily_recommendation_screen.dart';
import 'profile_screen.dart';
import 'check_in/diary_screen.dart';
import 'check_in/check_in_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

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

  @override
  void initState() {
    super.initState();
    loadWeekData();
    loadCompletionStates();
  }

  Future<void> loadWeekData() async {
    setState(() => isLoading = true);

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(
      const Duration(days: 6, hours: 23, minutes: 59),
    );

    final logs = await DatabaseService.instance.getEmotionsForDateRange(
      startOfWeek,
      endOfWeek,
    );

    if (mounted) {
      setState(() {
        weekLogs = logs;
        isLoading = false;
      });
    }
  }

  // Load completion states from shared preferences or database
  Future<void> loadCompletionStates() async {
    // You'll need to implement this based on your storage solution
    // For now, using mock data
    setState(() {
      emotionLogged = false;
      checkInCompleted = false;
      breathingExerciseCompleted = false;
    });
  }

  // Save completion states
  Future<void> saveCompletionStates() async {
    // Implement saving to shared preferences or database
  }

  Future<void> deleteLog(int? id) async {
    if (id == null) return;
    await DatabaseService.instance.deleteEmotion(id);
    loadWeekData();
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
      case 'happy':
        return Colors.green;
      case 'sad':
        return Colors.blue;
      case 'anxious':
        return Colors.orange;
      case 'angry':
        return Colors.red;
      case 'calm':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData getEmotionIcon(String emotion) {
    switch (emotion) {
      case 'happy':
        return Icons.sentiment_very_satisfied;
      case 'sad':
        return Icons.sentiment_dissatisfied;
      case 'anxious':
        return Icons.sentiment_neutral;
      case 'angry':
        return Icons.sentiment_very_dissatisfied;
      case 'calm':
        return Icons.favorite;
      default:
        return Icons.sentiment_neutral;
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
                        ? buildLineChart(weekDates)
                        : buildBarChart(weekDates, groupedLogs),
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
                      await loadWeekData();

                      // Check if any emotions were logged today to mark as completed
                      final todayLogs = getTodayLogs();
                      if (todayLogs.isNotEmpty) {
                        setState(() {
                          emotionLogged = true;
                        });
                        saveCompletionStates();
                      }
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
                        setState(() {
                          checkInCompleted = true;
                        });
                        saveCompletionStates();
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
                        setState(() {
                          breathingExerciseCompleted = true;
                        });
                        saveCompletionStates();
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
                  log.emotion.toUpperCase(),
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
                      '${log.intensity}/10',
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
                          deleteLog(log.id);
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
          color: color.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCompleted ? Colors.green : color.withValues(alpha:0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green : color.withValues(alpha:0.2),
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
                await loadWeekData();

                // Check if any emotions were logged today
                final todayLogs = getTodayLogs();
                if (todayLogs.isNotEmpty) {
                  setState(() {
                    emotionLogged = true;
                  });
                  saveCompletionStates();
                }
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

  // Build Bar Chart Widget
  Widget buildBarChart(
    List<DateTime> weekDates,
    Map<String, List<EmotionLog>> groupedLogs,
  ) {
    return SizedBox(
      key: const ValueKey('barChart'),
      height: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: weekDates.map((date) {
          final dateKey = DateFormat('yyyy-MM-dd').format(date);
          final logsForDay = groupedLogs[dateKey] ?? [];
          final isToday =
              DateFormat('yyyy-MM-dd').format(date) ==
              DateFormat('yyyy-MM-dd').format(DateTime.now());

          String? dominantEmotion;
          if (logsForDay.isNotEmpty) {
            final emotionCounts = <String, int>{};
            for (var log in logsForDay) {
              emotionCounts[log.emotion] =
                  (emotionCounts[log.emotion] ?? 0) + 1;
            }
            dominantEmotion = emotionCounts.entries
                .reduce((a, b) => a.value > b.value ? a : b)
                .key;
          }

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  DateFormat('E').format(date),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: isToday ? Colors.purple : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date.day.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: isToday ? Colors.purple : Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 8),
                if (dominantEmotion != null)
                  Container(
                    height: 80 + (logsForDay.length * 10.0),
                    width: 40,
                    decoration: BoxDecoration(
                      color: getEmotionColor(dominantEmotion).withValues(alpha:0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          getEmotionIcon(dominantEmotion),
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${logsForDay.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        style: BorderStyle.solid,
                        width: 2,
                      ),
                    ),
                    child: Icon(Icons.add, color: Colors.grey[400], size: 20),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // Build Line Chart Widget
  Widget buildLineChart(List<DateTime> weekDates) {
    final spots = getLineChartData();

    return SizedBox(
      key: const ValueKey('lineChart'),
      height: 200,
      child: weekLogs.isEmpty
          ? Center(
              child: Text(
                'Log emotions to see trend',
                style: TextStyle(color: Colors.grey[500]),
              ),
            )
          : Padding(
              padding: const EdgeInsets.only(right: 20, top: 10),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 2,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(color: Colors.grey[300]!, strokeWidth: 1);
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < weekDates.length) {
                            final date = weekDates[value.toInt()];
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(
                                DateFormat('E').format(date),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 2,
                        reservedSize: 35,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                      left: BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                  ),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: 10,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.purple,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: Colors.purple,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.purple.withValues(alpha:0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                        return touchedBarSpots.map((barSpot) {
                          final date = weekDates[barSpot.x.toInt()];
                          return LineTooltipItem(
                            '${DateFormat('MMM d').format(date)}\n',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text:
                                    'Intensity: ${barSpot.y.toStringAsFixed(1)}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
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
