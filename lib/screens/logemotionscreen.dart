import 'package:flutter/material.dart';
import '../models/emotionlog.dart';
import '../services/database_service.dart';

class LogEmotionScreen extends StatefulWidget {
  const LogEmotionScreen({super.key});

  @override
  State<LogEmotionScreen> createState() => _LogEmotionScreenState();
}

class _LogEmotionScreenState extends State<LogEmotionScreen> {
  String? selectedEmotion;
  double intensity = 5;
  final TextEditingController noteController = TextEditingController();

  final emotions = [
    {'name': 'happy', 'label': 'Happy', 'icon': Icons.sentiment_very_satisfied, 'color': Colors.green},
    {'name': 'sad', 'label': 'Sad', 'icon': Icons.sentiment_dissatisfied, 'color': Colors.blue},
    {'name': 'anxious', 'label': 'Anxious', 'icon': Icons.sentiment_neutral, 'color': Colors.orange},
    {'name': 'angry', 'label': 'Angry', 'icon': Icons.sentiment_very_dissatisfied, 'color': Colors.red},
    {'name': 'calm', 'label': 'Calm', 'icon': Icons.favorite, 'color': Colors.purple},
  ];

  Future<void> saveEmotion() async {
    if (selectedEmotion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an emotion')),
      );
      return;
    }

    final log = EmotionLog(
      emotion: selectedEmotion!,
      intensity: intensity.round(),
      note: noteController.text,
      dateTime: DateTime.now(),
    );

    await DatabaseService.instance.insertEmotion(log);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emotion logged successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.purple,
        title: const Text('Log Your Emotion'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How are you feeling?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: emotions.map((emotion) {
                final isSelected = selectedEmotion == emotion['name'];
                return GestureDetector(
                  onTap: () => setState(() => selectedEmotion = emotion['name'] as String),
                  child: Container(
                    width: (MediaQuery.of(context).size.width - 56) / 3,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (emotion['color'] as Color)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: emotion['color'] as Color,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: (emotion['color'] as Color).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          emotion['icon'] as IconData,
                          size: 40,
                          color: isSelected ? Colors.white : emotion['color'] as Color,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          emotion['label'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            const Text(
              'Intensity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: intensity,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: intensity.round().toString(),
                    activeColor: Colors.purple,
                    onChanged: (value) => setState(() => intensity = value),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${intensity.round()}/10',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Notes (Optional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'What triggered this emotion? Any thoughts...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                onPressed: saveEmotion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Entry',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
    noteController.dispose();
    super.dispose();
  }
}