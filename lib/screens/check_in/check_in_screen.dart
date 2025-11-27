import 'package:flutter/material.dart';
import '../../models/check_in.dart';
import '../../services/database_service.dart';
import '../../services/ai_service.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  String? selectedEmoji;
  final TextEditingController _diaryController = TextEditingController();
  final TextEditingController _titleController = TextEditingController(); // Add this controller
  bool isLoading = false;
  CheckIn? generatedCheckIn;

  final emojis = [
    {'emoji': '😊', 'label': 'Happy'},
    {'emoji': '😢', 'label': 'Sad'},
    {'emoji': '😰', 'label': 'Anxious'},
    {'emoji': '😤', 'label': 'Frustrated'},
    {'emoji': '😴', 'label': 'Tired'},
    {'emoji': '🤗', 'label': 'Loved'},
    {'emoji': '😡', 'label': 'Angry'},
    {'emoji': '😌', 'label': 'Calm'},
  ];

  Future<void> _submitCheckIn() async {
    if (selectedEmoji == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an emoji')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // Get recent emotions for AI context
      final recentEmotions = await DatabaseService.instance.getEmotionsForDateRange(
        DateTime.now().subtract(const Duration(days: 7)),
        DateTime.now(),
      );

      // Avoid overwriting BuildContext
      final aiContext = _diaryController.text.isEmpty
          ? 'User selected: $selectedEmoji'
          : 'User selected: $selectedEmoji and wrote: ${_diaryController.text}';

      final aiResponse =
          await AIService.instance.generateTherapistResponse(aiContext, recentEmotions);

      final checkIn = CheckIn(
        emoji: selectedEmoji!,
        diary: _diaryController.text.isEmpty ? null : _diaryController.text,
        title: _titleController.text.isEmpty ? null : _titleController.text, // Add this line
        aiResponse: aiResponse,
        timestamp: DateTime.now(),
      );

      await DatabaseService.instance.insertCheckIn(checkIn);

      if (!mounted) return;

      setState(() {
        generatedCheckIn = checkIn;
        isLoading = false;
      });
    } catch (e) {
      // Handle any errors that occur during submission
      debugPrint('Error submitting check-in: $e');
      
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting check-in: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (generatedCheckIn != null) {
      return _buildResponseScreen();
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.purple,
        title: const Text('Quick Check-In'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How are you feeling right now?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Pick an emoji that represents your mood',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Emoji grid
            SizedBox(
              height: 200, // Fixed height to prevent overflow
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: emojis.length,
                itemBuilder: (context, index) {
                  final emoji = emojis[index];
                  final isSelected = selectedEmoji == emoji['emoji'];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedEmoji = emoji['emoji'];
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.purple : Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? Colors.purple : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                emoji['emoji']!,
                                style: const TextStyle(fontSize: 40),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                emoji['label']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // Add Title Field here
            const Text(
              'Title (Optional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
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
            ),

            const SizedBox(height: 24),

            const Text(
              'Want to share more? (Optional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _diaryController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "What's on your mind today?",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.purple, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submitCheckIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Submit Check-In',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseScreen() {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.purple,
        title: const Text('AI Response'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.purple.withAlpha(40),
                shape: BoxShape.circle,
              ),
              child: Text(
                generatedCheckIn!.emoji,
                style: const TextStyle(fontSize: 80),
              ),
            ),

            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.psychology, color: Colors.purple),
                      SizedBox(width: 8),
                      Text(
                        'AI Companion',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    generatedCheckIn!.aiResponse,
                    style: const TextStyle(fontSize: 16, height: 1.6),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    generatedCheckIn = null;
                    selectedEmoji = null;
                    _diaryController.clear();
                    _titleController.clear(); 
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.purple),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Check In Again',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _diaryController.dispose();
    _titleController.dispose(); 
    super.dispose();
  }
}