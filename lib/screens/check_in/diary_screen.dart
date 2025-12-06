import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../models/check_in.dart';
import '../../services/firebase_service.dart';
import 'check_in_screen.dart';
import '../../providers/auth_provider.dart';
import '../../constants/text_styles.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  List<CheckIn> _diaryEntries = [];
  bool _isLoading = true;
  String _filter = 'all';
  List<String> _selectedEmotions = [];
  bool _showFilters = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _loadDiaryEntries();
  }

  // 安全容器构建器，解决 clipBehavior 问题
  Widget _safeContainer({
    Key? key,
    AlignmentGeometry? alignment,
    EdgeInsetsGeometry? padding,
    Color? color,
    Decoration? decoration,
    double? width,
    double? height,
    EdgeInsetsGeometry? margin,
    Widget? child,
    Clip clipBehavior = Clip.none,
  }) {
    final safeClipBehavior = (decoration == null) ? Clip.none : clipBehavior;

    return Container(
      key: key,
      alignment: alignment,
      padding: padding,
      color: color,
      decoration: decoration,
      width: width,
      height: height,
      margin: margin,
      clipBehavior: safeClipBehavior,
      child: child,
    );
  }

  Future<void> _loadDiaryEntries() async {
    debugPrint('=== DIARY SCREEN DEBUG ===');
    debugPrint('1. 调用 _loadDiaryEntries()');
    debugPrint('2. 当前时间: ${DateTime.now()}');
    debugPrint('3. _filter 值: $_filter');
    debugPrint('4. _getFilterDays() 返回: ${_getFilterDays()}');

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user.id;

    debugPrint('5. 用户ID: $userId');
    debugPrint('6. 用户是否登录: ${authProvider.isLoggedIn}');

    if (userId.isEmpty) {
      debugPrint('❌ 用户ID为空，无法加载数据');
      setState(() {
        _diaryEntries = [];
        _isLoading = false;
      });
      return;
    }

    try {
      debugPrint('7. 调用 FirebaseService.getRecentCheckIns...');
      final checkIns = await FirebaseService.instance.getRecentCheckIns(
        userId,
        days: _getFilterDays(),
      );

      debugPrint('8. 查询完成，获取到 ${checkIns.length} 条记录');

      if (checkIns.isNotEmpty) {
        for (var i = 0; i < checkIns.length; i++) {
          final entry = checkIns[i];
          debugPrint(
            '   记录$i: ${entry.emoji} | ${entry.emotion} | ${entry.timestamp}',
          );
        }
      }

      List<CheckIn> filtered = checkIns;
      if (_selectedEmotions.isNotEmpty) {
        debugPrint('9. 应用情绪筛选: $_selectedEmotions');
        filtered = checkIns
            .where((entry) => _selectedEmotions.contains(entry.emotion))
            .toList();
        debugPrint('   筛选后剩余 ${filtered.length} 条记录');
      }

      setState(() {
        _diaryEntries = filtered;
        _isLoading = false;
      });

      debugPrint('✅ 10. 最终设置 _diaryEntries 长度: ${_diaryEntries.length}');
    } catch (e) {
      debugPrint('❌ 加载日记记录失败: $e');
      debugPrint('错误类型: ${e.runtimeType}');
      setState(() => _isLoading = false);
    }
  }

  int _getFilterDays() {
    switch (_filter) {
      case 'today':
        return 1;
      case 'week':
        return 7;
      case 'month':
        return 30;
      default:
        return 365;
    }
  }

  List<String> _getAvailableEmotions() {
    final emotions = _diaryEntries
        .map((entry) => entry.emotion)
        .toSet()
        .toList();
    return emotions
        .where((emotion) => emotion.isNotEmpty && emotion != 'neutral')
        .toList();
  }

  Widget _buildFilterRow() {
    return _safeContainer(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间筛选
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('All', 'all'),
              _buildFilterChip('Today', 'today'),
              _buildFilterChip('Week', 'week'),
              _buildFilterChip('Month', 'month'),
            ],
          ),

          // 情绪筛选
          if (_getAvailableEmotions().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Filter by emotion:',
              style: TextStyle(
                color: Colors.white.withAlpha(180),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _getAvailableEmotions().map((emotion) {
                return _buildEmotionChip(emotion);
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _filter = value;
        });
        _loadDiaryEntries();
      },
      child: _safeContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.white.withAlpha(50),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withAlpha(200),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEmotionChip(String emotion) {
    final isSelected = _selectedEmotions.contains(emotion);
    final color = _getEmotionColor(emotion);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedEmotions.remove(emotion);
          } else {
            _selectedEmotions.add(emotion);
          }
        });
        _loadDiaryEntries();
      },
      child: _safeContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withAlpha(30),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : color.withAlpha(100)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getEmotionEmoji(emotion),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 6),
            Text(
              emotion[0].toUpperCase() + emotion.substring(1),
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return Color(0xFFFFD54F);
      case 'sad':
        return Color(0xFF64B5F6);
      case 'anxious':
        return Color(0xFFBA68C8);
      case 'angry':
        return Color(0xFFEF5350);
      case 'tired':
        return Color(0xFF66BB6A);
      case 'loved':
        return Color(0xFFFF8A65);
      case 'calm':
        return Color(0xFF26C6DA);
      default:
        return Color(0xFF9E9E9E);
    }
  }

  String _getEmotionEmoji(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'sad':
        return '😢';
      case 'anxious':
        return '😰';
      case 'angry':
        return '😡';
      case 'tired':
        return '😴';
      case 'loved':
        return '🤗';
      case 'calm':
        return '😌';
      default:
        return '😐';
    }
  }

  Widget _buildStats() {
    final totalEntries = _diaryEntries.length;
    final thisWeek = _diaryEntries.where((entry) {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      return entry.timestamp.isAfter(weekAgo);
    }).length;

    final uniqueMoods = _diaryEntries
        .map((entry) => entry.emotion)
        .toSet()
        .length;

    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(30)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('📝', totalEntries.toString(), 'Total'),
              _buildStatItem('📅', thisWeek.toString(), 'This Week'),
              _buildStatItem('😊', uniqueMoods.toString(), 'Moods'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String icon, String value, String label) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(180)),
        ),
      ],
    );
  }

  void _navigateToEditScreen(CheckIn checkIn) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditDiaryScreen(
          checkIn: checkIn,
          userId: Provider.of<AuthProvider>(context, listen: false).user.id,
        ),
      ),
    );

    if (result == true) {
      _loadDiaryEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _safeContainer(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 顶部标题
              Material(
                color: Colors.transparent,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withAlpha(30)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _safeContainer(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.book_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Diary',
                                style: AppTextStyles.headline2.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Reflect on your journey',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(180),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showFilters = !_showFilters;
                            });
                          },
                          child: _safeContainer(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _showFilters
                                  ? Color(0xFF8E2DE2).withAlpha(100)
                                  : Colors.white.withAlpha(20),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _showFilters
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _safeContainer(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(20),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_diaryEntries.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 筛选器和统计信息 - 可折叠区域
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: _showFilters ? null : 0,
                child: _showFilters
                    ? SingleChildScrollView(
                        child: Column(
                          children: [
                            // 筛选器
                            _buildFilterRow(),
                            const SizedBox(height: 16),
                            // 统计信息
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: _buildStats(),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // 当筛选器收起时显示一个小的筛选指示器
              if (!_showFilters) ...[
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      // 显示当前筛选状态
                      _safeContainer(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(10),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.filter_alt,
                              size: 14,
                              color: Color(0xFF8E2DE2),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getFilterLabel(),
                              style: TextStyle(
                                color: Colors.white.withAlpha(200),
                                fontSize: 12,
                              ),
                            ),
                            if (_selectedEmotions.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                '• ${_selectedEmotions.length} emotions',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(150),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Spacer(),
                      // 快速清除筛选按钮
                      if (_filter != 'all' || _selectedEmotions.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _filter = 'all';
                              _selectedEmotions.clear();
                            });
                            _loadDiaryEntries();
                          },
                          child: _safeContainer(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(10),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.clear_all,
                                  size: 14,
                                  color: Colors.white.withAlpha(150),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Clear',
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(150),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : _diaryEntries.isEmpty
                    ? Center(
                        child: Material(
                          color: Colors.transparent,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(10),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withAlpha(30),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.book_outlined,
                                    size: 60,
                                    color: Colors.white.withAlpha(100),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'No entries yet',
                                    style: AppTextStyles.headline3.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Tap + to add your first check-in',
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(150),
                                    ),
                                  ),
                                  if (!_showFilters)
                                    Column(
                                      children: [
                                        const SizedBox(height: 20),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _showFilters = true;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Color(
                                                0xFF8E2DE2,
                                              ).withAlpha(30),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.filter_alt,
                                                  size: 16,
                                                  color: Color(0xFF8E2DE2),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Show Filters',
                                                  style: TextStyle(
                                                    color: Color(0xFF8E2DE2),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
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
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _diaryEntries.length,
                        itemBuilder: (context, index) {
                          final entry = _diaryEntries[index];
                          return DiaryEntryCard(
                            checkIn: entry,
                            onTap: () => _navigateToEditScreen(entry),
                            onDelete: () => _deleteEntry(entry),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CheckInScreen()),
            );
            if (result == true) {
              _loadDiaryEntries();
            }
          },
          backgroundColor: const Color(0xFF8E2DE2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'New Entry',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  String _getFilterLabel() {
    switch (_filter) {
      case 'today':
        return 'Today';
      case 'week':
        return 'This Week';
      case 'month':
        return 'This Month';
      default:
        return 'All Time';
    }
  }

  Future<void> _deleteEntry(CheckIn checkIn) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user.id;

    if (userId.isEmpty || checkIn.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Delete Entry',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this diary entry?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseService.instance.deleteCheckIn(userId, checkIn.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Entry deleted'),
              backgroundColor: Colors.green,
            ),
          );
          _loadDiaryEntries();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class DiaryEntryCard extends StatelessWidget {
  final CheckIn checkIn;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const DiaryEntryCard({
    super.key,
    required this.checkIn,
    required this.onTap,
    this.onDelete,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkInDate = DateTime(date.year, date.month, date.day);

    if (checkInDate == today) {
      return 'Today • ${DateFormat('h:mm a').format(date)}';
    } else if (checkInDate == yesterday) {
      return 'Yesterday • ${DateFormat('h:mm a').format(date)}';
    } else {
      return DateFormat('MMM d • h:mm a').format(date);
    }
  }

  String _getEmotionEmoji(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'sad':
        return '😢';
      case 'anxious':
        return '😰';
      case 'angry':
        return '😡';
      case 'tired':
        return '😴';
      case 'loved':
        return '🤗';
      case 'calm':
        return '😌';
      default:
        return '😐';
    }
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return Color(0xFFFFD54F);
      case 'sad':
        return Color(0xFF64B5F6);
      case 'anxious':
        return Color(0xFFBA68C8);
      case 'angry':
        return Color(0xFFEF5350);
      case 'tired':
        return Color(0xFF66BB6A);
      case 'loved':
        return Color(0xFFFF8A65);
      case 'calm':
        return Color(0xFF26C6DA);
      default:
        return Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withAlpha(30)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _getEmotionColor(
                            checkIn.emotion,
                          ).withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getEmotionColor(
                              checkIn.emotion,
                            ).withAlpha(100),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            checkIn.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    checkIn.title ?? 'My Check-in',
                                    style: AppTextStyles.subtitle1.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                if (onDelete != null)
                                  IconButton(
                                    onPressed: onDelete,
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Colors.white.withAlpha(150),
                                      size: 20,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getEmotionColor(
                                      checkIn.emotion,
                                    ).withAlpha(30),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        _getEmotionEmoji(checkIn.emotion),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        checkIn.emotion[0].toUpperCase() +
                                            checkIn.emotion.substring(1),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: _getEmotionColor(
                                            checkIn.emotion,
                                          ),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _formatDate(checkIn.timestamp),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withAlpha(150),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (checkIn.diary != null && checkIn.diary!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        checkIn.diary!,
                        style: TextStyle(
                          color: Colors.white.withAlpha(200),
                          height: 1.5,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF8E2DE2).withAlpha(30),
                          Color(0xFF4A00E0).withAlpha(20),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.psychology_outlined,
                          size: 16,
                          color: Color(0xFF8E2DE2),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Companion says:',
                                style: TextStyle(
                                  color: Color(0xFF8E2DE2),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                checkIn.aiResponse,
                                style: TextStyle(
                                  color: Colors.white.withAlpha(180),
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
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
  }
}

class EditDiaryScreen extends StatefulWidget {
  final CheckIn checkIn;
  final String userId;

  const EditDiaryScreen({
    super.key,
    required this.checkIn,
    required this.userId,
  });

  @override
  State<EditDiaryScreen> createState() => _EditDiaryScreenState();
}

class _EditDiaryScreenState extends State<EditDiaryScreen> {
  late TextEditingController _diaryController;
  late TextEditingController _titleController;
  DateTime? _editTimestamp;

  @override
  void initState() {
    super.initState();
    _diaryController = TextEditingController(text: widget.checkIn.diary ?? '');
    _titleController = TextEditingController(text: widget.checkIn.title ?? '');
  }

  // 安全容器构建器
  Widget _safeContainer({
    Key? key,
    AlignmentGeometry? alignment,
    EdgeInsetsGeometry? padding,
    Color? color,
    Decoration? decoration,
    double? width,
    double? height,
    EdgeInsetsGeometry? margin,
    Widget? child,
    Clip clipBehavior = Clip.none,
  }) {
    final safeClipBehavior = (decoration == null) ? Clip.none : clipBehavior;

    return Container(
      key: key,
      alignment: alignment,
      padding: padding,
      color: color,
      decoration: decoration,
      width: width,
      height: height,
      margin: margin,
      clipBehavior: safeClipBehavior,
      child: child,
    );
  }

  Future<void> _saveChanges() async {
    if (_diaryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Diary entry cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      if (widget.checkIn.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot update: No entry ID'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final updates = {
        'diary': _diaryController.text.trim(),
        'title': _titleController.text.isEmpty
            ? null
            : _titleController.text.trim(),
      };

      updates.removeWhere((key, value) => value == null);

      await FirebaseService.instance.updateCheckIn(
        widget.userId,
        widget.checkIn.id!,
        updates,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving changes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _safeContainer(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 顶部栏
              Material(
                color: Colors.transparent,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withAlpha(30)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: _safeContainer(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(20),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_back,
                              color: Colors.white.withAlpha(200),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Edit Diary Entry',
                            style: AppTextStyles.headline3.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8E2DE2),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.save, size: 16),
                              SizedBox(width: 6),
                              Text('Save'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(10),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withAlpha(30),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _safeContainer(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(20),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          widget.checkIn.emoji,
                                          style: const TextStyle(fontSize: 32),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Original: ${_formatDateTime(widget.checkIn.timestamp)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white.withAlpha(
                                                150,
                                              ),
                                            ),
                                          ),
                                          if (_editTimestamp != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Edited: ${_formatDateTime(_editTimestamp!)}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // AI Response
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF8E2DE2).withAlpha(20),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.psychology_outlined,
                                            color: Color(0xFF8E2DE2),
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'AI Companion Response',
                                            style: TextStyle(
                                              color: Color(0xFF8E2DE2),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        widget.checkIn.aiResponse,
                                        style: TextStyle(
                                          color: Colors.white.withAlpha(200),
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 标题输入
                      Material(
                        color: Colors.transparent,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(10),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withAlpha(30),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Title',
                                  style: AppTextStyles.subtitle2.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _titleController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Give your entry a title...',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withAlpha(100),
                                    ),
                                    border: InputBorder.none,
                                    filled: true,
                                    fillColor: Colors.white.withAlpha(10),
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                  onChanged: (value) {
                                    setState(
                                      () => _editTimestamp = DateTime.now(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 日记内容
                      Material(
                        color: Colors.transparent,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(10),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withAlpha(30),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Diary',
                                  style: AppTextStyles.subtitle2.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _diaryController,
                                  maxLines: 8,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Write about your day...',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withAlpha(100),
                                    ),
                                    border: InputBorder.none,
                                    filled: true,
                                    fillColor: Colors.white.withAlpha(10),
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                  onChanged: (value) {
                                    setState(
                                      () => _editTimestamp = DateTime.now(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('MMM d, yyyy • HH:mm').format(date);
  }

  @override
  void dispose() {
    _diaryController.dispose();
    _titleController.dispose();
    super.dispose();
  }
}
