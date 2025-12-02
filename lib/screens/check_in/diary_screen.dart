import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../models/check_in.dart';
import '../../services/firebase_service.dart';
import 'check_in_screen.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  List<CheckIn> _diaryEntries = [];
  bool _isLoading = true;
  final FirebaseService _firebaseService = FirebaseService.instance; // 添加这行
  User? _currentUser; // 添加这行
  StreamSubscription<List<CheckIn>>? _diarySubscription;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _loadDiaryEntries();
  }

  Future<void> _loadDiaryEntries() async {
    try {
      if (_currentUser == null) {
        setState(() {
          _diaryEntries = [];
          _isLoading = false;
        });
        return;
      }

      // 使用 Stream 实时监听数据变化
      _diarySubscription?.cancel();
      _diarySubscription = _firebaseService
          .getCheckIns(_currentUser!.uid)
          .listen(
            (checkIns) {
              if (mounted) {
                setState(() {
                  _diaryEntries = checkIns;
                  _isLoading = false;
                });
              }
            },
            onError: (error) {
              debugPrint('Error loading diary entries: $error');
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
          );
    } catch (e) {
      debugPrint('Error loading diary entries: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToEditScreen(CheckIn checkIn) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditDiaryScreen(
          checkIn: checkIn,
          userId: _currentUser?.uid ?? '', // 传递 userId
        ),
      ),
    );

    if (result == true) {
      _loadDiaryEntries(); // Refresh the list after editing
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.purple,
        title: const Text('Diary'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _diaryEntries.isEmpty
          ? const Center(
              child: Text(
                'No diary entries yet.\nTap + to add your first check-in!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _diaryEntries.length,
              itemBuilder: (context, index) {
                final entry = _diaryEntries[index];
                return DiaryEntryCard(
                  checkIn: entry,
                  onTap: () => _navigateToEditScreen(entry),
                  onDelete: () => _deleteEntry(entry), // 添加删除功能
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CheckInScreen()),
          );
          if (result == true) {
            _loadDiaryEntries(); // Refresh after adding new check-in
          }
        },
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _deleteEntry(CheckIn checkIn) async {
    if (_currentUser == null || checkIn.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text(
          'Are you sure you want to delete this diary entry?',
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
        await _firebaseService.deleteCheckIn(_currentUser!.uid, checkIn.id!);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Entry deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
        }
      }
    }
  }

  @override
  void dispose() {
    _diarySubscription?.cancel();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First row: Emoji, title, and date
              Row(
                children: [
                  Text(checkIn.emoji, style: const TextStyle(fontSize: 30)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      checkIn.title ?? 'My Check-in',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: onDelete,
                    ),
                  Text(
                    _formatDate(checkIn.timestamp),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Diary content preview
              if (checkIn.diary != null && checkIn.diary!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      checkIn.diary!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),

              // AI Response preview - NEW SECTION!
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.psychology, size: 16, color: Colors.purple),
                        SizedBox(width: 4),
                        Text(
                          'AI Companion:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      checkIn.aiResponse,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
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
  final FirebaseService _firebaseService = FirebaseService.instance; // 添加这行

  @override
  void initState() {
    super.initState();
    _diaryController = TextEditingController(text: widget.checkIn.diary ?? '');
    _titleController = TextEditingController(text: widget.checkIn.title ?? '');
  }

  Future<void> _saveChanges() async {
    if (_diaryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diary entry cannot be empty')),
      );
      return;
    }

    try {
      if (widget.checkIn.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot update: No entry ID')),
        );
        return;
      }

      // 创建更新数据
      final updates = {
        'diary': _diaryController.text.trim(),
        'title': _titleController.text.isEmpty
            ? null
            : _titleController.text.trim(),
      };

      // 移除 null 值
      updates.removeWhere((key, value) => value == null);

      // 修改这行
      await _firebaseService.updateCheckIn(
        widget.userId,
        widget.checkIn.id!,
        updates,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving changes: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.purple,
        title: const Text('Edit Diary Entry'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveChanges),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji and original timestamp
            Row(
              children: [
                Text(
                  widget.checkIn.emoji,
                  style: const TextStyle(fontSize: 40),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Original: ${_formatDateTime(widget.checkIn.timestamp)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      if (_editTimestamp != null)
                        Text(
                          'Edited: ${_formatDateTime(_editTimestamp!)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.green,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Title Field
            const Text(
              'Title:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              maxLines: 1,
              decoration: InputDecoration(
                hintText: "Give your entry a title...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.purple, width: 2),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _editTimestamp = DateTime.now();
                });
              },
            ),
            const SizedBox(height: 24),

            // AI Response - Full display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.psychology, color: Colors.purple),
                      SizedBox(width: 8),
                      Text(
                        'AI Companion Response:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.checkIn.aiResponse,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Diary Entry
            const Text(
              'Your Diary:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _diaryController,
              maxLines: 10,
              decoration: InputDecoration(
                hintText: "Write about your day...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.purple, width: 2),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _editTimestamp = DateTime.now();
                });
              },
            ),
          ],
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
