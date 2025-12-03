import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/emotionlog.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';
import '../models/check_in.dart';
import 'dart:developer';


class HomeScreenController {
  final BuildContext context;
  late final AuthProvider authProvider;
  final Function(void Function()) setState;
  final Function() refreshView;
  
  List<EmotionLog> weekLogs = [];
  bool isLoading = true;
  bool showLineChart = false;
  
  // To-do list completion states
  bool emotionLogged = false;
  bool checkInCompleted = false;
  bool breathingExerciseCompleted = false;
  
  StreamSubscription<List<EmotionLog>>? _emotionSubscription;
  
  HomeScreenController({
    required this.context,
    required this.setState,
    required this.refreshView,
  }) {
    authProvider = Provider.of<AuthProvider>(context, listen: false);
  }
  
  void init() {
    loadWeekData();
    _setupRealTimeListener();
    loadCompletionStates();
  }
  
  void _setupRealTimeListener() async {
    final userId = authProvider.user.id;
    if (userId.isEmpty) return;
    
    try {
      _emotionSubscription?.cancel();
      _emotionSubscription = FirebaseService.instance
          .getEmotionLogs(userId)
          .listen(
            (emotions) {
              _processEmotions(emotions);
            },
            onError: (error) {
              debugPrint('Error in emotion stream: $error');
              loadWeekData();
            },
          );
    } catch (e) {
      debugPrint('Error setting up real-time listener: $e');
    }
  }
  
  void _processEmotions(List<EmotionLog> emotions) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(
      const Duration(days: 6, hours: 23, minutes: 59),
    );
    
    final weekEmotions = emotions.where((log) {
      return log.dateTime.isAfter(startOfWeek) &&
          log.dateTime.isBefore(endOfWeek);
    }).toList();
    
    setState(() {
      weekLogs = weekEmotions;
      isLoading = false;
      final todayLogs = _getTodayLogsFromList(weekEmotions);
      emotionLogged = todayLogs.isNotEmpty;
      loadCompletionStates();
    });
  }
  
  List<EmotionLog> _getTodayLogsFromList(List<EmotionLog> allLogs) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return allLogs
        .where((log) => DateFormat('yyyy-MM-dd').format(log.dateTime) == today)
        .toList();
  }
  
  Future<void> loadWeekData() async {
    setState(() => isLoading = true);
    
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
      final logs = await FirebaseService.instance.getEmotionsForDateRange(
        userId,
        startOfWeek,
        endOfWeek,
      );
      
      setState(() {
        weekLogs = logs;
        isLoading = false;
        final todayLogs = _getTodayLogsFromList(logs);
        emotionLogged = todayLogs.isNotEmpty;
      });
    } catch (e) {
      debugPrint('Error loading week data from Firebase: $e');
      setState(() => isLoading = false);
      _showError('Failed to load data: $e');
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message))
    );
  }
  
  Future<void> loadCompletionStates() async {
    final userId = authProvider.user.id;
    if (userId.isEmpty) return;
    
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
      
      final todayEmotions = await FirebaseService.instance
          .getEmotionsForDateRange(userId, todayStart, todayEnd);
      
      List<CheckIn> todayCheckIns = [];
      try {
        todayCheckIns = await FirebaseService.instance.getTodayCheckIns(userId);
      } catch (e) {
        final recentCheckIns = await FirebaseService.instance.getRecentCheckIns(
          userId,
          days: 1,
        );
        
        todayCheckIns = recentCheckIns.where((checkIn) {
          final checkInDate = DateTime(
            checkIn.timestamp.year,
            checkIn.timestamp.month,
            checkIn.timestamp.day,
          );
          return checkInDate == todayStart;
        }).toList();
      }
      
      final todayRecommendation = await FirebaseService.instance
          .getTodayRecommendation(userId);
      
      setState(() {
        emotionLogged = todayEmotions.isNotEmpty;
        checkInCompleted = todayCheckIns.isNotEmpty;
        breathingExerciseCompleted = todayRecommendation?.completed ?? false;
      });
      
    } catch (e) {
      debugPrint('❌ Error loading completion states: $e');
    }
  }
  
  Future<void> deleteLog(String? emotionId) async {
    if (emotionId == null || emotionId.isEmpty) {
      _showError('Cannot delete: Invalid emotion ID');
      return;
    }
    
    final userId = authProvider.user.id;
    if (userId.isEmpty) return;
    
    try {
      await FirebaseService.instance.deleteEmotion(userId, emotionId);
      _showSuccess('Emotion entry deleted');
    } catch (e) {
      debugPrint('Error deleting emotion: $e');
      _showError('Failed to delete: $e');
    }
  }
  
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message))
    );
  }
  
  Future<void> refreshAllData() async {
    await loadCompletionStates();
    await loadWeekData();
  }
  
  void toggleChart() {
    setState(() => showLineChart = !showLineChart);
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
  
  void dispose() {
    _emotionSubscription?.cancel();
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
}