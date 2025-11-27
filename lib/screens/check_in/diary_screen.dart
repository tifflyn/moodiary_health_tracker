import 'package:flutter/material.dart';
import '../../models/check_in.dart';
import '../../services/database_service.dart';
import 'check_in_screen.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  List<CheckIn> _diaryEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDiaryEntries();
  }

  Future<void> _loadDiaryEntries() async {
    try {
      final entries = await DatabaseService.instance.getAllCheckIns();
      setState(() {
        _diaryEntries = entries;
        _isLoading = false;
      });
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
        builder: (context) => EditDiaryScreen(checkIn: checkIn),
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
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CheckInScreen()),
          );
        },
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class DiaryEntryCard extends StatelessWidget {
  final CheckIn checkIn;
  final VoidCallback onTap;

  const DiaryEntryCard({
    super.key,
    required this.checkIn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ListTile(
        leading: Text(
          checkIn.emoji,
          style: const TextStyle(fontSize: 30),
        ),
        title: Text(
          // Display title if available, otherwise show default text
          checkIn.title ?? 'My Check-in',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatDate(checkIn.timestamp),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            if (checkIn.diary != null && checkIn.diary!.isNotEmpty)
              Text(
                _truncateDiaryText(checkIn.diary!),
                style: const TextStyle(fontSize: 12, color: Colors.black54),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _truncateDiaryText(String diary) {
    return diary.length > 50 ? '${diary.substring(0, 50)}...' : diary;
  }

}

class EditDiaryScreen extends StatefulWidget {
  final CheckIn checkIn;

  const EditDiaryScreen({super.key, required this.checkIn});

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

  Future<void> _saveChanges() async {
    if (_diaryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diary entry cannot be empty')),
      );
      return;
    }

    try {
      final updatedCheckIn = CheckIn(
        id: widget.checkIn.id,
        emoji: widget.checkIn.emoji,
        diary: _diaryController.text.trim(),
        title: _titleController.text.isEmpty ? null : _titleController.text.trim(), 
        aiResponse: widget.checkIn.aiResponse,
        timestamp: widget.checkIn.timestamp,
      );

      await DatabaseService.instance.updateCheckIn(updatedCheckIn);
      
      if (!mounted) return;
      
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving changes: $e')),
      );
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
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveChanges,
          ),
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
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      if (_editTimestamp != null)
                        Text(
                          'Edited: ${_formatDateTime(_editTimestamp!)}',
                          style: const TextStyle(fontSize: 14, color: Colors.green),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
            
            // AI Response
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI Response:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(widget.checkIn.aiResponse),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _diaryController.dispose();
     _titleController.dispose();
    super.dispose();
  }
}