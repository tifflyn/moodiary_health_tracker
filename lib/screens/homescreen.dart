// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:fl_chart/fl_chart.dart';
// import '../models/emotionlog.dart';
// import 'logemotionscreen.dart';
// import 'ai_chatbot_screen.dart';
// import 'self_care/daily_recommendation_screen.dart';
// import 'profile_screen.dart';
// import 'check_in/diary_screen.dart';
// import 'check_in/check_in_screen.dart';
// import 'package:provider/provider.dart';
// import '../providers/auth_provider.dart';
// import '../services/firebase_service.dart'; // 添加这一行
// import 'dart:developer'; // 添加这行，用于 debugPrint
// import '../models/check_in.dart';
// import '../constants/colors.dart';
// import '../constants/text_styles.dart';
// import '../widgets/glass_card.dart';
// import 'dart:ui'; // 添加这行 - ImageFilter需要这个

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   List<EmotionLog> weekLogs = [];
//   bool isLoading = true;
//   bool showLineChart = false;
//   int _currentIndex = 0;

//   // To-do list completion states
//   bool emotionLogged = false;
//   bool checkInCompleted = false;
//   bool breathingExerciseCompleted = false;

//   StreamSubscription<List<EmotionLog>>? _emotionSubscription;

//   @override
//   void initState() {
//     super.initState();
//     // 先立即加载一次
//     loadWeekData();
//     // 然后设置实时监听
//     _setupRealTimeListener();

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       loadCompletionStates();
//     });
//   }

//   // 添加实时监听方法
//   void _setupRealTimeListener() async {
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);
//     final userId = authProvider.user.id;

//     if (userId.isEmpty) return;

//     try {
//       _emotionSubscription?.cancel();
//       _emotionSubscription = FirebaseService.instance
//           .getEmotionLogs(userId)
//           .listen(
//             (emotions) {
//               if (mounted) {
//                 _processEmotions(emotions);
//               }
//             },
//             onError: (error) {
//               debugPrint('Error in emotion stream: $error');

//               if (mounted) {
//                 loadWeekData();
//               }
//             },
//           );
//     } catch (e) {
//       debugPrint('Error setting up real-time listener: $e');
//     }
//   }

//   // 处理情绪数据的方法
//   void _processEmotions(List<EmotionLog> emotions) {
//     final now = DateTime.now();
//     final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
//     final endOfWeek = startOfWeek.add(
//       const Duration(days: 6, hours: 23, minutes: 59),
//     );

//     // 过滤出本周的数据
//     final weekEmotions = emotions.where((log) {
//       return log.dateTime.isAfter(startOfWeek) &&
//           log.dateTime.isBefore(endOfWeek);
//     }).toList();

//     if (mounted) {
//       setState(() {
//         weekLogs = weekEmotions;
//         isLoading = false;

//         // 检查今天是否记录了情绪（用于 TodoList）
//         final todayLogs = _getTodayLogsFromList(weekEmotions);
//         emotionLogged = todayLogs.isNotEmpty;

//         loadCompletionStates();
//       });
//     }
//   }

//   void _debugPrintLogs() {
//     if (weekLogs.isEmpty) return;

//     debugPrint('=== DEBUG: Checking EmotionLog IDs ===');
//     debugPrint('Total week logs: ${weekLogs.length}');

//     final todayLogs = getTodayLogs();
//     debugPrint('Today\'s logs: ${todayLogs.length}');

//     // Check for logs without IDs
//     int logsWithoutId = 0;
//     for (var log in weekLogs) {
//       if (log.id == null || log.id!.isEmpty) {
//         logsWithoutId++;
//         debugPrint(
//           '⚠️ EmotionLog without ID: emotion=${log.emotion}, date=${DateFormat('yyyy-MM-dd HH:mm').format(log.dateTime)}',
//         );
//       }
//     }

//     // Print today's logs with IDs
//     for (var log in todayLogs) {
//       debugPrint(
//         'Today: id="${log.id ?? "NULL"}", ${log.emotion}, ${log.intensity}/5, ${DateFormat('HH:mm').format(log.dateTime)}',
//       );
//     }

//     if (logsWithoutId > 0) {
//       debugPrint('❌ Found $logsWithoutId logs without IDs');
//     } else {
//       debugPrint('✅ All logs have proper IDs');
//     }
//     debugPrint('====================================');
//   }

//   // 从列表中获取今天的日志
//   List<EmotionLog> _getTodayLogsFromList(List<EmotionLog> allLogs) {
//     final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
//     return allLogs
//         .where((log) => DateFormat('yyyy-MM-dd').format(log.dateTime) == today)
//         .toList();
//   }

//   Future<void> loadWeekData() async {
//     setState(() => isLoading = true);

//     // 获取当前用户ID
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);
//     final userId = authProvider.user.id;

//     if (userId.isEmpty) {
//       setState(() => isLoading = false);
//       return;
//     }

//     final now = DateTime.now();
//     final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
//     final endOfWeek = startOfWeek.add(
//       const Duration(days: 6, hours: 23, minutes: 59),
//     );

//     try {
//       // 切换到 FirebaseService
//       final logs = await FirebaseService.instance.getEmotionsForDateRange(
//         userId,
//         startOfWeek,
//         endOfWeek,
//       );

//       if (mounted) {
//         setState(() {
//           weekLogs = logs;
//           isLoading = false;

//           // 检查今天是否记录了情绪
//           final todayLogs = _getTodayLogsFromList(logs);
//           emotionLogged = todayLogs.isNotEmpty;
//         });
//       }
//     } catch (e) {
//       debugPrint('Error loading week data from Firebase: $e');
//       if (mounted) {
//         setState(() => isLoading = false);
//       }
//       // 可选：显示错误提示给用户
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
//     }
//   }

//   // 在 dispose 方法中添加
//   @override
//   void dispose() {
//     _emotionSubscription?.cancel();
//     super.dispose();
//   }

//   Future<void> loadCompletionStates() async {
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);
//     final userId = authProvider.user.id;

//     if (userId.isEmpty) return;

//     try {
//       // 1. Check if emotions were logged today
//       final now = DateTime.now();
//       final todayStart = DateTime(now.year, now.month, now.day);
//       final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

//       final todayEmotions = await FirebaseService.instance
//           .getEmotionsForDateRange(userId, todayStart, todayEnd);

//       // 2. Check if there are check-ins today
//       List<CheckIn> todayCheckIns = [];
//       try {
//         // Try using the new getTodayCheckIns method
//         todayCheckIns = await FirebaseService.instance.getTodayCheckIns(userId);
//         debugPrint('✅ Today\'s check-ins count: ${todayCheckIns.length}');
//       } catch (e) {
//         debugPrint('⚠️ Failed to use getTodayCheckIns: $e');
//         // Fallback: use getRecentCheckIns and filter
//         final recentCheckIns = await FirebaseService.instance.getRecentCheckIns(
//           userId,
//           days: 1,
//         );
//         debugPrint('📊 Recent 1-day check-ins: ${recentCheckIns.length}');

//         // Filter out today's records
//         todayCheckIns = recentCheckIns.where((checkIn) {
//           final checkInDate = DateTime(
//             checkIn.timestamp.year,
//             checkIn.timestamp.month,
//             checkIn.timestamp.day,
//           );
//           final isToday = checkInDate == todayStart;
//           if (isToday) {
//             debugPrint(
//               '📅 Found today\'s check-in: ${checkIn.title ?? "No title"} at ${checkIn.timestamp}',
//             );
//           }
//           return isToday;
//         }).toList();
//       }

//       // 3. Check if today's recommendation is completed
//       final todayRecommendation = await FirebaseService.instance
//           .getTodayRecommendation(userId);

//       if (mounted) {
//         setState(() {
//           emotionLogged = todayEmotions.isNotEmpty;
//           checkInCompleted = todayCheckIns.isNotEmpty; // ✅ Fixed here
//           breathingExerciseCompleted = todayRecommendation?.completed ?? false;
//         });

//         // Add debug output
//         debugPrint('''
// ✅ Todo status updated:
//   Emotion log: ${todayEmotions.isNotEmpty} (${todayEmotions.length} items)
//   Check-ins: ${todayCheckIns.isNotEmpty} (${todayCheckIns.length} items)
//   Breathing exercise: ${todayRecommendation?.completed ?? false}
// ''');
//       }
//     } catch (e) {
//       debugPrint('❌ Error loading completion states: $e');
//     }
//   }

//   Future<void> deleteLog(String? emotionId) async {
//     if (emotionId == null || emotionId.isEmpty) {
//       debugPrint('❌ Cannot delete: emotionId is null or empty');
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Cannot delete: Invalid emotion ID')),
//       );
//       return;
//     }

//     final authProvider = Provider.of<AuthProvider>(context, listen: false);
//     final userId = authProvider.user.id;

//     if (userId.isEmpty) return;

//     try {
//       await FirebaseService.instance.deleteEmotion(userId, emotionId);

//       // Show success message
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Emotion entry deleted')));

//       // Note: Real-time listener will automatically update the list
//     } catch (e) {
//       debugPrint('Error deleting emotion: $e');
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
//     }
//   }

//   Future<void> refreshAllData() async {
//     await loadCompletionStates();
//     await loadWeekData();
//   }

//   String getEnergyLabel(String emotion) {
//     switch (emotion) {
//       case 'totally_drained':
//         return 'Totally drained.';
//       case 'running_low':
//         return 'Running low...';
//       case 'medium_energy':
//         return 'Medium energy';
//       case 'energized':
//         return 'Energized!';
//       case 'fully_charged':
//         return 'Fully charged!!!';
//       default:
//         return emotion;
//     }
//   }

//   List<DateTime> getWeekDates() {
//     final now = DateTime.now();
//     final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
//     return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
//   }

//   Map<String, List<EmotionLog>> groupLogsByDate() {
//     final Map<String, List<EmotionLog>> grouped = {};
//     for (var log in weekLogs) {
//       final dateKey = DateFormat('yyyy-MM-dd').format(log.dateTime);
//       grouped[dateKey] = [...(grouped[dateKey] ?? []), log];
//     }
//     return grouped;
//   }

//   // Get average intensity for each day
//   List<FlSpot> getLineChartData() {
//     final weekDates = getWeekDates();
//     final groupedLogs = groupLogsByDate();
//     final spots = <FlSpot>[];

//     for (int i = 0; i < weekDates.length; i++) {
//       final dateKey = DateFormat('yyyy-MM-dd').format(weekDates[i]);
//       final logsForDay = groupedLogs[dateKey] ?? [];

//       if (logsForDay.isNotEmpty) {
//         final avgIntensity =
//             logsForDay.map((log) => log.intensity).reduce((a, b) => a + b) /
//             logsForDay.length;
//         spots.add(FlSpot(i.toDouble(), avgIntensity.toDouble()));
//       } else {
//         spots.add(FlSpot(i.toDouble(), 0));
//       }
//     }

//     return spots;
//   }

//   Color getEmotionColor(String emotion) {
//     switch (emotion) {
//       case 'totally_drained':
//         return Colors.red;
//       case 'running_low':
//         return Colors.orange;
//       case 'medium_energy':
//         return Colors.green;
//       case 'energized':
//         return Colors.blue;
//       case 'fully_charged':
//         return Colors.purple;
//       default:
//         return Colors.grey;
//     }
//   }

//   IconData getEmotionIcon(String emotion) {
//     switch (emotion) {
//       case 'totally_drained':
//         return Icons.battery_0_bar;
//       case 'running_low':
//         return Icons.battery_1_bar;
//       case 'medium_energy':
//         return Icons.battery_2_bar;
//       case 'energized':
//         return Icons.battery_3_bar;
//       case 'fully_charged':
//         return Icons.battery_full;
//       default:
//         return Icons.battery_unknown;
//     }
//   }

//   // ==================== 惊艳组件开始 ====================

//   Widget _buildWeeklyChartSection() {
//     return Container(
//       margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
//       child: Column(
//         children: [
//           // 标题栏
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 "Weekly Overview",
//                 style: AppTextStyles.headline2.copyWith(color: Colors.white),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 6,
//                 ),
//                 decoration: BoxDecoration(
//                   color: AppColors.cardDark,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Text(
//                   DateFormat('MMM d').format(DateTime.now()),
//                   style: AppTextStyles.caption.copyWith(
//                     color: AppColors.textGray,
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 16),

//           // 双卡片布局
//           Row(
//             children: [
//               // 图表卡片
//               Expanded(
//                 flex: 3,
//                 child: GlassCard(
//                   child: Column(
//                     children: [
//                       SizedBox(height: 180, child: _buildMinimalChart()),
//                       const SizedBox(height: 16),
//                       _buildChartStats(),
//                     ],
//                   ),
//                 ),
//               ),

//               const SizedBox(width: 12),

//               // 统计卡片
//               Expanded(
//                 flex: 2,
//                 child: GlassCard(
//                   color: AppColors.primaryBlue.withAlpha(76),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       const Icon(
//                         Icons.insights,
//                         size: 32,
//                         color: AppColors.accentBlue,
//                       ),
//                       const SizedBox(height: 12),
//                       Text(
//                         '${weekLogs.length}',
//                         style: const TextStyle(
//                           fontSize: 36,
//                           fontWeight: FontWeight.w800,
//                           color: Colors.white,
//                         ),
//                       ),
//                       Text(
//                         'logs this week',
//                         style: AppTextStyles.caption.copyWith(
//                           color: AppColors.textGray,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                       const SizedBox(height: 12),
//                       Container(
//                         width: 40,
//                         height: 4,
//                         decoration: BoxDecoration(
//                           gradient: const LinearGradient(
//                             colors: AppColors.accentGradient,
//                           ),
//                           borderRadius: BorderRadius.circular(2),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMinimalChart() {
//     final spots = getLineChartData();

//     return LineChart(
//       LineChartData(
//         gridData: const FlGridData(show: false),
//         titlesData: const FlTitlesData(show: false),
//         borderData: FlBorderData(show: false),
//         minX: 0,
//         maxX: 6,
//         minY: 0,
//         maxY: 5,
//         lineTouchData: const LineTouchData(enabled: false),
//         lineBarsData: [
//           LineChartBarData(
//             spots: spots,
//             isCurved: true,
//             color: AppColors.accentBlue,
//             barWidth: 3,
//             isStrokeCapRound: true,
//             shadow: Shadow(
//               color: AppColors.accentBlue.withAlpha(76),
//               blurRadius: 8,
//               offset: const Offset(0, 3),
//             ),
//             belowBarData: BarAreaData(
//               show: true,
//               gradient: LinearGradient(
//                 colors: [
//                   AppColors.accentBlue.withAlpha(51),
//                   AppColors.accentBlue.withAlpha(0),
//                 ],
//                 stops: const [0.1, 1.0],
//               ),
//             ),
//             dotData: const FlDotData(show: false),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildChartStats() {
//     if (weekLogs.isEmpty) {
//       return Text('No data yet', style: AppTextStyles.caption);
//     }

//     final avgIntensity =
//         weekLogs.map((log) => log.intensity).reduce((a, b) => a + b) /
//         weekLogs.length;

//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceAround,
//       children: [
//         _buildStatItem(
//           label: 'Avg.',
//           value: avgIntensity.toStringAsFixed(1),
//           unit: '/5',
//           color: AppColors.accentBlue,
//         ),
//         _buildStatItem(
//           label: 'High',
//           value: weekLogs
//               .map((log) => log.intensity)
//               .reduce((a, b) => a > b ? a : b)
//               .toString(),
//           unit: '/5',
//           color: AppColors.success,
//         ),
//         _buildStatItem(
//           label: 'Consistency',
//           value: '${_calculateConsistency()}%',
//           unit: '',
//           color: AppColors.lightBlue,
//         ),
//       ],
//     );
//   }

//   Widget _buildStatItem({
//     required String label,
//     required String value,
//     required String unit,
//     required Color color,
//   }) {
//     return Column(
//       children: [
//         Row(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.baseline,
//           textBaseline: TextBaseline.alphabetic,
//           children: [
//             Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.w700,
//                 color: Colors.white,
//               ),
//             ),
//             const SizedBox(width: 2),
//             Text(
//               unit,
//               style: AppTextStyles.caption.copyWith(color: AppColors.textGray),
//             ),
//           ],
//         ),
//         const SizedBox(height: 4),
//         Text(
//           label,
//           style: AppTextStyles.caption.copyWith(color: AppColors.textGray),
//         ),
//       ],
//     );
//   }

//   int _calculateConsistency() {
//     if (weekLogs.length < 2) return 0;

//     // 简单的一致性计算：记录频率
//     final daysWithLogs = weekLogs
//         .map((log) => DateFormat('yyyy-MM-dd').format(log.dateTime))
//         .toSet()
//         .length;

//     return ((daysWithLogs / 7) * 100).toInt();
//   }

//   Widget _buildDailyTasksSection() {
//     final completedTasks = _getCompletedTasks();
//     final totalTasks = 3;
//     final progress = completedTasks / totalTasks;

//     return Container(
//       margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Daily Wellness',
//                 style: AppTextStyles.headline2.copyWith(color: Colors.white),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 6,
//                 ),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: progress == 1
//                         ? [AppColors.success, const Color(0xFF4CAF50)]
//                         : AppColors.accentGradient,
//                   ),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Text(
//                   '$completedTasks/$totalTasks',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w600,
//                     fontSize: 12,
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 16),

//           // 进度圆环和任务列表
//           GlassCard(
//             child: Row(
//               children: [
//                 // 进度圆环
//                 SizedBox(
//                   width: 100,
//                   height: 100,
//                   child: Stack(
//                     alignment: Alignment.center,
//                     children: [
//                       // 背景圆环
//                       CircularProgressIndicator(
//                         value: 1.0,
//                         strokeWidth: 8,
//                         color: AppColors.cardDark,
//                       ),
//                       // 进度圆环
//                       CircularProgressIndicator(
//                         value: progress,
//                         strokeWidth: 8,
//                         strokeCap: StrokeCap.round,
//                         valueColor: AlwaysStoppedAnimation<Color>(
//                           progress == 1
//                               ? AppColors.success
//                               : AppColors.accentBlue,
//                         ),
//                       ),
//                       // 中间内容
//                       Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             '${(progress * 100).toInt()}',
//                             style: const TextStyle(
//                               fontSize: 24,
//                               fontWeight: FontWeight.w800,
//                               color: Colors.white,
//                             ),
//                           ),
//                           Text(
//                             '%',
//                             style: AppTextStyles.caption.copyWith(
//                               color: AppColors.textGray,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(width: 20),

//                 // 任务列表
//                 Expanded(
//                   child: Column(
//                     children: [
//                       _buildTaskItemCompact(
//                         title: 'Emotion Log',
//                         completed: emotionLogged,
//                         icon: Icons.mood,
//                       ),
//                       const SizedBox(height: 12),
//                       _buildTaskItemCompact(
//                         title: 'Daily Check-In',
//                         completed: checkInCompleted,
//                         icon: Icons.edit_note,
//                       ),
//                       const SizedBox(height: 12),
//                       _buildTaskItemCompact(
//                         title: 'Breathing',
//                         completed: breathingExerciseCompleted,
//                         icon: Icons.air,
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTaskItemCompact({
//     required String title,
//     required bool completed,
//     required IconData icon,
//   }) {
//     return InkWell(
//       onTap: () {
//         // 根据任务类型跳转
//         if (title == 'Emotion Log') {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => const LogEmotionScreen()),
//           ).then((_) => refreshAllData());
//         } else if (title == 'Daily Check-In') {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => const CheckInScreen()),
//           ).then((_) => refreshAllData());
//         } else if (title == 'Breathing') {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => const DailyRecommendationScreen(),
//             ),
//           ).then((_) => refreshAllData());
//         }
//       },
//       borderRadius: BorderRadius.circular(12),
//       child: Container(
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: AppColors.cardDark,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 32,
//               height: 32,
//               decoration: BoxDecoration(
//                 color: completed
//                     ? AppColors.success.withAlpha(51)
//                     : AppColors.cardLight,
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 completed ? Icons.check : icon,
//                 size: 16,
//                 color: completed ? AppColors.success : AppColors.textGray,
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Text(
//                 title,
//                 style: TextStyle(
//                   color: completed ? AppColors.success : Colors.white,
//                   fontWeight: FontWeight.w500,
//                   decoration: completed ? TextDecoration.lineThrough : null,
//                 ),
//               ),
//             ),
//             Icon(
//               completed ? Icons.check_circle : Icons.arrow_forward_ios,
//               size: 16,
//               color: completed ? AppColors.success : AppColors.textGray,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   int _getCompletedTasks() {
//     int count = 0;
//     if (emotionLogged) count++;
//     if (checkInCompleted) count++;
//     if (breathingExerciseCompleted) count++;
//     return count;
//   }

//   Widget homeContent() {
//     final authProvider = Provider.of<AuthProvider>(context);
//     final nickname = authProvider.user.nickname;

//     // 添加滚动控制器
//     final scrollController = ScrollController();

//     return NotificationListener<ScrollNotification>(
//       onNotification: (notification) {
//         // 可以根据滚动位置添加效果
//         return false;
//       },
//       child: SingleChildScrollView(
//         controller: scrollController,
//         physics: const BouncingScrollPhysics(),
//         padding: const EdgeInsets.only(bottom: 100),
//         child: Column(
//           children: [
//             _buildHeroHeader(nickname),
//             _buildWeeklyChartSection(),
//             _buildDailyTasksSection(),
//             _buildTodayEntriesSection(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTodayEntriesSection() {
//     final todayLogs = getTodayLogs();

//     return Container(
//       margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 "Today's Entries",
//                 style: AppTextStyles.headline2.copyWith(color: Colors.white),
//               ),
//               if (todayLogs.isNotEmpty)
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 6,
//                   ),
//                   decoration: BoxDecoration(
//                     color: AppColors.accentBlue.withAlpha(25),
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(
//                       color: AppColors.accentBlue.withAlpha(76),
//                       width: 1,
//                     ),
//                   ),
//                   child: Text(
//                     '${todayLogs.length} entries',
//                     style: AppTextStyles.caption.copyWith(
//                       color: AppColors.accentBlue,
//                     ),
//                   ),
//                 ),
//             ],
//           ),

//           const SizedBox(height: 16),

//           if (todayLogs.isEmpty)
//             GlassCard(
//               child: Padding(
//                 padding: const EdgeInsets.all(32),
//                 child: Column(
//                   children: [
//                     Icon(
//                       Icons.psychology_outlined,
//                       size: 60,
//                       color: AppColors.textGray.withAlpha(127),
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       'No entries yet today',
//                       style: TextStyle(
//                         color: AppColors.textGray,
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Start by logging your current energy!',
//                       style: AppTextStyles.caption,
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ),
//               ),
//             )
//           else
//             ...todayLogs.reversed
//                 .map(
//                   (log) => Container(
//                     margin: const EdgeInsets.only(bottom: 12),
//                     child: _buildModernLogEntry(log),
//                   ),
//                 )
//                 .toList(),
//         ],
//       ),
//     );
//   }

//   Widget _buildModernLogEntry(EmotionLog log) {
//     final color = getEmotionColor(log.emotion);

//     return GlassCard(
//       padding: const EdgeInsets.all(16),
//       child: Row(
//         children: [
//           // 情绪图标
//           Container(
//             width: 60,
//             height: 60,
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [color.withAlpha(76), color.withAlpha(25)],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               shape: BoxShape.circle,
//             ),
//             child: Center(
//               child: Icon(getEmotionIcon(log.emotion), color: color, size: 28),
//             ),
//           ),

//           const SizedBox(width: 16),

//           // 内容
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       getEnergyLabel(log.emotion),
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w700,
//                         color: Colors.white,
//                       ),
//                     ),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 10,
//                         vertical: 4,
//                       ),
//                       decoration: BoxDecoration(
//                         color: color.withAlpha(25),
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(
//                           color: color.withAlpha(76),
//                           width: 1,
//                         ),
//                       ),
//                       child: Text(
//                         '${log.intensity}/5',
//                         style: TextStyle(
//                           color: color,
//                           fontWeight: FontWeight.w600,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 4),

//                 Row(
//                   children: [
//                     Icon(
//                       Icons.access_time,
//                       size: 12,
//                       color: AppColors.textGray,
//                     ),
//                     const SizedBox(width: 4),
//                     Text(
//                       DateFormat('h:mm a').format(log.dateTime),
//                       style: AppTextStyles.caption,
//                     ),
//                   ],
//                 ),

//                 if (log.note.isNotEmpty) ...[
//                   const SizedBox(height: 8),
//                   Container(
//                     padding: const EdgeInsets.all(10),
//                     decoration: BoxDecoration(
//                       color: AppColors.cardDark,
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Text(
//                       log.note,
//                       style: AppTextStyles.bodySmall.copyWith(
//                         color: AppColors.textGray,
//                       ),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),

//           // 删除按钮
//           IconButton(
//             icon: Icon(Icons.delete_outline, color: Colors.red.withAlpha(150)),
//             onPressed: () async {
//               final confirm = await showDialog<bool>(
//                 context: context,
//                 builder: (context) => AlertDialog(
//                   title: const Text("Delete Entry"),
//                   content: const Text(
//                     "Are you sure you want to delete this emotion entry?",
//                   ),
//                   actions: [
//                     TextButton(
//                       child: const Text("Cancel"),
//                       onPressed: () => Navigator.pop(context, false),
//                     ),
//                     TextButton(
//                       child: const Text(
//                         "Delete",
//                         style: TextStyle(color: Colors.red),
//                       ),
//                       onPressed: () => Navigator.pop(context, true),
//                     ),
//                   ],
//                 ),
//               );

//               if (confirm == true) {
//                 deleteLog(log.id);
//               }
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildHeroHeader(String nickname) {
//     final now = DateTime.now();
//     final hour = now.hour;
//     String greeting = 'Good Morning';
//     IconData greetingIcon = Icons.wb_sunny_outlined;

//     if (hour >= 12 && hour < 17) {
//       greeting = 'Good Afternoon';
//       greetingIcon = Icons.wb_twilight_outlined;
//     } else if (hour >= 17) {
//       greeting = 'Good Evening';
//       greetingIcon = Icons.nightlight_outlined;
//     }

//     // 获取用户的首字母作为头像
//     final initials = nickname.isNotEmpty && nickname.length > 1
//         ? nickname.substring(0, 2).toUpperCase()
//         : 'U';

//     return Container(
//       padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             AppColors.accentBlue.withAlpha(50),
//             AppColors.primaryBlue.withAlpha(30),
//             Colors.transparent,
//           ],
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           stops: const [0.0, 0.5, 1.0],
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // 顶部栏
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Icon(greetingIcon, size: 18, color: AppColors.lightBlue),
//                       const SizedBox(width: 8),
//                       Text(
//                         greeting,
//                         style: AppTextStyles.bodySmall.copyWith(
//                           color: AppColors.lightBlue,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     DateFormat('EEEE, MMMM d').format(DateTime.now()),
//                     style: AppTextStyles.caption.copyWith(
//                       color: AppColors.textGray,
//                     ),
//                   ),
//                 ],
//               ),

//               // 用户头像
//               Container(
//                 width: 50,
//                 height: 50,
//                 decoration: BoxDecoration(
//                   gradient: const LinearGradient(
//                     colors: AppColors.accentGradient,
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   shape: BoxShape.circle,
//                   boxShadow: [
//                     BoxShadow(
//                       color: AppColors.accentBlue.withAlpha(76),
//                       blurRadius: 10,
//                       spreadRadius: 2,
//                     ),
//                   ],
//                 ),
//                 child: Center(
//                   child: Text(
//                     initials,
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 18,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 30),

//           // 主标题
//           Text(
//             nickname.isNotEmpty ? 'Hi, $nickname' : 'Welcome',
//             style: const TextStyle(
//               fontSize: 36,
//               fontWeight: FontWeight.w800,
//               color: Colors.white,
//               height: 1.1,
//               letterSpacing: -0.5,
//             ),
//           ),

//           Text(
//             'How are you feeling today?',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.w400,
//               color: AppColors.textGray,
//             ),
//           ),

//           const SizedBox(height: 24),

//           // 快速情绪选择
//           _buildQuickEmotionSelector(),
//         ],
//       ),
//     );
//   }

//   Widget _buildQuickEmotionSelector() {
//     final todayLogs = getTodayLogs();
//     final currentEnergy = todayLogs.isNotEmpty ? todayLogs.last.emotion : null;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Quick Log',
//           style: AppTextStyles.headline3.copyWith(color: Colors.white),
//         ),
//         const SizedBox(height: 12),

//         SingleChildScrollView(
//           scrollDirection: Axis.horizontal,
//           child: Row(
//             children: [
//               _buildEmotionChip(
//                 emotion: 'fully_charged',
//                 label: 'High',
//                 isSelected: currentEnergy == 'fully_charged',
//               ),
//               const SizedBox(width: 12),
//               _buildEmotionChip(
//                 emotion: 'energized',
//                 label: 'Good',
//                 isSelected: currentEnergy == 'energized',
//               ),
//               const SizedBox(width: 12),
//               _buildEmotionChip(
//                 emotion: 'medium_energy',
//                 label: 'Medium',
//                 isSelected: currentEnergy == 'medium_energy',
//               ),
//               const SizedBox(width: 12),
//               _buildEmotionChip(
//                 emotion: 'running_low',
//                 label: 'Low',
//                 isSelected: currentEnergy == 'running_low',
//               ),
//               const SizedBox(width: 12),
//               _buildEmotionChip(
//                 emotion: 'totally_drained',
//                 label: 'Drained',
//                 isSelected: currentEnergy == 'totally_drained',
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildEmotionChip({
//     required String emotion,
//     required String label,
//     required bool isSelected,
//   }) {
//     final color = getEmotionColor(emotion);
//     final icon = getEmotionIcon(emotion);

//     return GestureDetector(
//       onTap: () async {
//         // 快速记录情绪
//         final log = EmotionLog(
//           emotion: emotion,
//           intensity: _getIntensityForEmotion(emotion),
//           note: '',
//           dateTime: DateTime.now(),
//         );

//         final authProvider = Provider.of<AuthProvider>(context, listen: false);
//         final userId = authProvider.user.id;

//         try {
//           await FirebaseService.instance.addEmotionLog(userId, log);
//           await refreshAllData();
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Logged: $label'), backgroundColor: color),
//           );
//         } catch (e) {
//           debugPrint('Error logging emotion: $e');
//         }
//       },
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//         decoration: BoxDecoration(
//           color: isSelected ? color : color.withAlpha(25),
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(
//             color: isSelected ? Colors.white : color.withAlpha(76),
//             width: isSelected ? 2 : 1,
//           ),
//           boxShadow: isSelected
//               ? [
//                   BoxShadow(
//                     color: color.withAlpha(76),
//                     blurRadius: 15,
//                     spreadRadius: 2,
//                   ),
//                 ]
//               : null,
//         ),
//         child: Row(
//           children: [
//             Icon(icon, size: 18, color: isSelected ? Colors.white : color),
//             const SizedBox(width: 8),
//             Text(
//               label,
//               style: TextStyle(
//                 fontWeight: FontWeight.w600,
//                 color: isSelected ? Colors.white : color,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   int _getIntensityForEmotion(String emotion) {
//     switch (emotion) {
//       case 'fully_charged':
//         return 5;
//       case 'energized':
//         return 4;
//       case 'medium_energy':
//         return 3;
//       case 'running_low':
//         return 2;
//       case 'totally_drained':
//         return 1;
//       default:
//         return 3;
//     }
//   }

//   // Build To-Do List Item
//   Widget buildTodoItem({
//     required String title,
//     required String subtitle,
//     required IconData icon,
//     required Color color,
//     required bool isCompleted,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(12),
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: color.withValues(alpha: 0.1),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color: isCompleted ? Colors.green : color.withValues(alpha: 0.3),
//             width: 2,
//           ),
//         ),
//         child: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: isCompleted
//                     ? Colors.green
//                     : color.withValues(alpha: 0.2),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 isCompleted ? Icons.check : icon,
//                 color: isCompleted ? Colors.white : color,
//                 size: 24,
//               ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: isCompleted ? Colors.green : color,
//                       fontSize: 16,
//                       decoration: isCompleted
//                           ? TextDecoration.lineThrough
//                           : TextDecoration.none,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     subtitle,
//                     style: TextStyle(
//                       color: isCompleted ? Colors.green : Colors.grey[600],
//                       fontSize: 12,
//                       decoration: isCompleted
//                           ? TextDecoration.lineThrough
//                           : TextDecoration.none,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Icon(
//               isCompleted ? Icons.check_circle : Icons.arrow_forward_ios,
//               color: isCompleted ? Colors.green : color,
//               size: 20,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildGlassNavBar() {
//     return Container(
//       margin: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(25),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.3),
//             blurRadius: 30,
//             spreadRadius: 5,
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(25),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
//           child: Container(
//             decoration: BoxDecoration(
//               color: Colors.black.withOpacity(0.2),
//               border: Border.all(
//                 color: Colors.white.withOpacity(0.1),
//                 width: 1,
//               ),
//               borderRadius: BorderRadius.circular(25),
//             ),
//             child: BottomNavigationBar(
//               backgroundColor: Colors.transparent,
//               currentIndex: _currentIndex,
//               onTap: (index) => setState(() => _currentIndex = index),
//               selectedItemColor: AppColors.accentBlue,
//               unselectedItemColor: AppColors.textGray,
//               type: BottomNavigationBarType.fixed,
//               elevation: 0,
//               items: const [
//                 BottomNavigationBarItem(
//                   icon: Icon(Icons.home_outlined),
//                   activeIcon: Icon(Icons.home),
//                   label: 'Home',
//                 ),
//                 BottomNavigationBarItem(
//                   icon: Icon(Icons.book_outlined),
//                   activeIcon: Icon(Icons.book),
//                   label: 'Diary',
//                 ),
//                 BottomNavigationBarItem(
//                   icon: Icon(Icons.chat_bubble_outline),
//                   activeIcon: Icon(Icons.chat_bubble),
//                   label: 'AI Chat',
//                 ),
//                 BottomNavigationBarItem(
//                   icon: Icon(Icons.self_improvement_outlined),
//                   activeIcon: Icon(Icons.self_improvement),
//                   label: 'Self-care',
//                 ),
//                 BottomNavigationBarItem(
//                   icon: Icon(Icons.person_outlined),
//                   activeIcon: Icon(Icons.person),
//                   label: 'Profile',
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!isLoading && weekLogs.isNotEmpty && _currentIndex == 0) {
//         _debugPrintLogs();
//       }
//     });

//     return Scaffold(
//       backgroundColor: AppColors.primaryDark, // ← 改这里
//       extendBody: true,
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.transparent, // ← 改这里
//         foregroundColor: Colors.white,
//         title: const Text(
//           'Mental Health Tracker',
//           style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
//         ),
//         centerTitle: true,
//       ),

//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: AppColors.bgGradient,
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: _currentIndex == 0
//             ? homeContent()
//             : _currentIndex == 1
//             ? const DiaryScreen()
//             : _currentIndex == 2
//             ? const AIChatbotScreen()
//             : _currentIndex == 3
//             ? const DailyRecommendationScreen()
//             : const ProfileScreen(),
//       ),

//       // 底部导航栏改成玻璃态
//       bottomNavigationBar: _buildGlassNavBar(),

//       floatingActionButton: _currentIndex == 0
//           ? Container(
//               margin: const EdgeInsets.only(bottom: 80),
//               child: FloatingActionButton.extended(
//                 onPressed: () async {
//                   await Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const LogEmotionScreen(),
//                     ),
//                   );
//                   await refreshAllData();
//                 },
//                 backgroundColor: AppColors.accentBlue,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 icon: const Icon(Icons.add, color: Colors.white),
//                 label: const Text(
//                   'Log Emotion',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             )
//           : null,
//     );
//   }

//   List<EmotionLog> getTodayLogs() {
//     final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
//     return weekLogs
//         .where((log) => DateFormat('yyyy-MM-dd').format(log.dateTime) == today)
//         .toList();
//   }

//   List<String> getInsights() {
//     if (weekLogs.isEmpty) return [];

//     final insights = <String>[];
//     final emotionCounts = <String, int>{};

//     for (var log in weekLogs) {
//       emotionCounts[log.emotion] = (emotionCounts[log.emotion] ?? 0) + 1;
//     }

//     if (emotionCounts.isNotEmpty) {
//       final mostCommon = emotionCounts.entries
//           .reduce((a, b) => a.value > b.value ? a : b)
//           .key;
//       insights.add(
//         'Your most common emotion this week: ${mostCommon.toUpperCase()}',
//       );
//     }

//     final negativeCount = weekLogs
//         .where((log) => ['sad', 'anxious', 'angry'].contains(log.emotion))
//         .length;

//     if (negativeCount >= 5) {
//       insights.add(
//         'You\'ve had several challenging moments. Consider self-care activities.',
//       );
//     }

//     return insights;
//   }
// }
