import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/emotionlog.dart';
import '../providers/auth_provider.dart';
import '../widgets/charts.dart';
import 'logemotionscreen.dart';
import 'ai_chatbot_screen.dart';
import 'self_care/daily_recommendation_screen.dart';
import 'profile_screen.dart';
import 'check_in/diary_screen.dart';
import 'check_in/check_in_screen.dart';
import 'homescreencontroller.dart';

class HomeScreenView extends StatefulWidget {
  const HomeScreenView({super.key});

  @override
  State<HomeScreenView> createState() => _HomeScreenViewState();
}

class _HomeScreenViewState extends State<HomeScreenView> {
  late HomeScreenController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = HomeScreenController(
      context: context,
      setState: setState,
      refreshView: () => setState(() {}),
    );
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildHomeContent() {
    final authProvider = Provider.of<AuthProvider>(context);
    final nickname = authProvider.user.nickname;
    final weekDates = _controller.getWeekDates();
    final groupedLogs = _controller.groupLogsByDate();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hey, $nickname!',
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
                              color: !_controller.showLineChart
                                  ? Colors.purple
                                  : Colors.grey,
                            ),
                            onPressed: () => setState(() {
                              _controller.showLineChart = false;
                            }),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.show_chart,
                              color: _controller.showLineChart
                                  ? Colors.purple
                                  : Colors.grey,
                            ),
                            onPressed: () => setState(() {
                              _controller.showLineChart = true;
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _controller.showLineChart
                        ? _buildLineChart(weekDates)
                        : _buildBarChart(weekDates, groupedLogs),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // TO-DO LIST
          _buildTodoListCard(),

          const SizedBox(height: 20),

          // INSIGHTS
          _buildInsightsCard(),

          const SizedBox(height: 20),

          // TODAY'S ENTRIES
          _buildTodaysEntries(),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<DateTime> weekDates) {
    final spots = _getLineChartData();
    return buildLineChart(
      weekDates: weekDates,
      spots: spots,
      hasData: _controller.weekLogs.isNotEmpty,
    );
  }

  Widget _buildBarChart(
    List<DateTime> weekDates,
    Map<String, List<EmotionLog>> groupedLogs,
  ) {
    return buildBarChart(
      weekDates: weekDates,
      groupedLogs: groupedLogs,
      getEmotionColor: _controller.getEmotionColor,
      getEmotionIcon: _controller.getEmotionIcon,
    );
  }

  Widget _buildTodoListCard() {
    return Card(
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
            _buildTodoItem(
              title: 'Log Your Emotions',
              subtitle: 'Express how you\'re feeling today',
              icon: Icons.mood,
              color: Colors.purple,
              isCompleted: _controller.emotionLogged,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LogEmotionScreen(),
                  ),
                );
                await _controller.loadCompletionStates();
              },
            ),

            const SizedBox(height: 12),

            _buildTodoItem(
              title: 'Daily Check-In',
              subtitle: 'Reflect on your day',
              icon: Icons.edit_note,
              color: Colors.orange,
              isCompleted: _controller.checkInCompleted,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CheckInScreen(),
                  ),
                );

                if (result == true) {
                  await _controller.loadCompletionStates();
                }
              },
            ),

            const SizedBox(height: 12),

            _buildTodoItem(
              title: 'Breathing Exercise',
              subtitle: 'Calm your mind with breathing',
              icon: Icons.air,
              color: Colors.blue,
              isCompleted: _controller.breathingExerciseCompleted,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DailyRecommendationScreen(),
                  ),
                );

                if (result == true) {
                  await _controller.loadCompletionStates();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoItem({
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
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCompleted ? Colors.green : color.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green : color.withOpacity(0.2),
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

  Widget _buildInsightsCard() {
    return Card(
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

            if (_controller.weekLogs.isEmpty)
              const Text(
                'Start logging your emotions to see patterns and insights!',
                style: TextStyle(color: Colors.white70),
              )
            else
              ..._controller.getInsights().map(
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
    );
  }

  Widget _buildTodaysEntries() {
    final todayLogs = _controller.getTodayLogs();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today\'s Entries',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        ...todayLogs.map(
          (log) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _controller.getEmotionColor(log.emotion),
                child: Icon(
                  _controller.getEmotionIcon(log.emotion),
                  color: Colors.white,
                ),
              ),
              title: Text(
                _controller.getEnergyLabel(log.emotion),
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
                    onPressed: () => _showDeleteConfirmation(log.id),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (todayLogs.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No entries yet today',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showDeleteConfirmation(String? emotionId) async {
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
      await _controller.deleteLog(emotionId);
    }
  }

  List<FlSpot> _getLineChartData() {
    final weekDates = _controller.getWeekDates();
    final groupedLogs = _controller.groupLogsByDate();
    final spots = <FlSpot>[];

    for (int i = 0; i < weekDates.length; i++) {
      final dateKey = DateFormat('yyyy-MM-dd').format(weekDates[i]);
      final logsForDay = groupedLogs[dateKey] ?? [];

      if (logsForDay.isNotEmpty) {
        final avgIntensity = logsForDay
                .map((log) => log.intensity)
                .reduce((a, b) => a + b) /
            logsForDay.length;
        spots.add(FlSpot(i.toDouble(), avgIntensity.toDouble()));
      } else {
        spots.add(FlSpot(i.toDouble(), 0));
      }
    }

    return spots;
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
          ? _buildHomeContent()
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
                await _controller.refreshAllData();
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
}