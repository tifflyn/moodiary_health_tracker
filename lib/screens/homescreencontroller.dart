import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/emotionlog.dart';
import '../models/check_in.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';
import 'dart:developer';
import 'package:fl_chart/fl_chart.dart';

class HomeScreenController {
  final BuildContext context;
  late final AuthProvider authProvider;
  late final FirebaseService firebaseService;

  List<EmotionLog> weekLogs = [];
  bool isLoading = true;
  bool showLineChart = false;

  // To-do list completion states
  bool emotionLogged = false;
  bool checkInCompleted = false;
  bool breathingExerciseCompleted = false;

  StreamSubscription<List<EmotionLog>>? _emotionSubscription;

  HomeScreenController(this.context) {
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    firebaseService = FirebaseService.instance;
  }

  void initState() {
    loadWeekData();
    _setupRealTimeListener();
    loadCompletionStates();
  }

  void dispose() {
    _emotionSubscription?.cancel();
  }

  // 添加实时监听方法
  void _setupRealTimeListener() async {
    final userId = authProvider.user.id;
    if (userId.isEmpty) return;

    try {
      _emotionSubscription?.cancel();
      _emotionSubscription = firebaseService
          .getEmotionLogs(userId)
          .listen(
            (emotions) => _processEmotions(emotions),
            onError: (error) {
              debugPrint('Error in emotion stream: $error');
              loadWeekData();
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

    weekLogs = weekEmotions;
    isLoading = false;

    // 检查今天是否记录了情绪（用于 TodoList）
    final todayLogs = _getTodayLogsFromList(weekEmotions);
    emotionLogged = todayLogs.isNotEmpty;

    loadCompletionStates();
  }

  void debugPrintLogs() {
    if (weekLogs.isEmpty) return;

    debugPrint('=== DEBUG: Checking EmotionLog IDs ===');
    debugPrint('Total week logs: ${weekLogs.length}');

    final todayLogs = getTodayLogs();
    debugPrint('Today\'s logs: ${todayLogs.length}');

    // Check for logs without IDs
    int logsWithoutId = 0;
    for (var log in weekLogs) {
      if (log.id == null || log.id!.isEmpty) {
        logsWithoutId++;
        debugPrint(
          '⚠️ EmotionLog without ID: emotion=${log.emotion}, date=${DateFormat('yyyy-MM-dd HH:mm').format(log.dateTime)}',
        );
      }
    }

    // Print today's logs with IDs
    for (var log in todayLogs) {
      debugPrint(
        'Today: id="${log.id ?? "NULL"}", ${log.emotion}, ${log.intensity}/5, ${DateFormat('HH:mm').format(log.dateTime)}',
      );
    }

    if (logsWithoutId > 0) {
      debugPrint('❌ Found $logsWithoutId logs without IDs');
    } else {
      debugPrint('✅ All logs have proper IDs');
    }
    debugPrint('====================================');
  }

  // 从列表中获取今天的日志
  List<EmotionLog> _getTodayLogsFromList(List<EmotionLog> allLogs) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return allLogs
        .where((log) => DateFormat('yyyy-MM-dd').format(log.dateTime) == today)
        .toList();
  }

  Future<void> loadWeekData() async {
    isLoading = true;

    final userId = authProvider.user.id;
    if (userId.isEmpty) {
      isLoading = false;
      return;
    }

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(
      const Duration(days: 6, hours: 23, minutes: 59),
    );

    try {
      final logs = await firebaseService.getEmotionsForDateRange(
        userId,
        startOfWeek,
        endOfWeek,
      );

      weekLogs = logs;
      isLoading = false;

      // 检查今天是否记录了情绪
      final todayLogs = _getTodayLogsFromList(logs);
      emotionLogged = todayLogs.isNotEmpty;
    } catch (e) {
      debugPrint('Error loading week data from Firebase: $e');
      isLoading = false;
      // 可选：显示错误提示给用户
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
    }
  }

  Future<void> loadCompletionStates() async {
    final userId = authProvider.user.id;
    if (userId.isEmpty) return;

    try {
      // 1. Check if emotions were logged today
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final todayEmotions = await firebaseService.getEmotionsForDateRange(
        userId,
        todayStart,
        todayEnd,
      );

      // 2. Check if there are check-ins today
      List<CheckIn> todayCheckIns = [];
      try {
        // Try using the new getTodayCheckIns method
        todayCheckIns = await firebaseService.getTodayCheckIns(userId);
        debugPrint('✅ Today\'s check-ins count: ${todayCheckIns.length}');
      } catch (e) {
        debugPrint('⚠️ Failed to use getTodayCheckIns: $e');
        // Fallback: use getRecentCheckIns and filter
        final recentCheckIns = await firebaseService.getRecentCheckIns(
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
      final todayRecommendation = await firebaseService.getTodayRecommendation(
        userId,
      );

      emotionLogged = todayEmotions.isNotEmpty;
      checkInCompleted = todayCheckIns.isNotEmpty;
      breathingExerciseCompleted = todayRecommendation?.completed ?? false;

      // Add debug output
      debugPrint('''
✅ Todo status updated:
  Emotion log: ${todayEmotions.isNotEmpty} (${todayEmotions.length} items)
  Check-ins: ${todayCheckIns.isNotEmpty} (${todayCheckIns.length} items)
  Breathing exercise: ${todayRecommendation?.completed ?? false}
''');
    } catch (e) {
      debugPrint('❌ Error loading completion states: $e');
    }
  }

  Future<void> deleteLog(String? emotionId) async {
    if (emotionId == null || emotionId.isEmpty) {
      debugPrint('❌ Cannot delete: emotionId is null or empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete: Invalid emotion ID')),
      );
      return;
    }

    final userId = authProvider.user.id;
    if (userId.isEmpty) return;

    try {
      await firebaseService.deleteEmotion(userId, emotionId);

      // Show success message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Emotion entry deleted')));
    } catch (e) {
      debugPrint('Error deleting emotion: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
    }
  }

  Future<void> refreshAllData() async {
    await loadCompletionStates();
    await loadWeekData();
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

  int calculateConsistency() {
    if (weekLogs.length < 2) return 0;

    // 简单的一致性计算：记录频率
    final daysWithLogs = weekLogs
        .map((log) => DateFormat('yyyy-MM-dd').format(log.dateTime))
        .toSet()
        .length;

    return ((daysWithLogs / 7) * 100).toInt();
  }

  int getCompletedTasks() {
    int count = 0;
    if (emotionLogged) count++;
    if (checkInCompleted) count++;
    if (breathingExerciseCompleted) count++;
    return count;
  }

  int getIntensityForEmotion(String emotion) {
    switch (emotion) {
      case 'fully_charged':
        return 5;
      case 'energized':
        return 4;
      case 'medium_energy':
        return 3;
      case 'running_low':
        return 2;
      case 'totally_drained':
        return 1;
      default:
        return 3;
    }
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
