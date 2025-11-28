// lib/screens/logemotionscreen.dart
import 'package:flutter/material.dart';
import '../models/emotionlog.dart';
import '../services/database_service.dart';

class LogEmotionScreen extends StatefulWidget {
  const LogEmotionScreen({super.key});

  @override
  State<LogEmotionScreen> createState() => _LogEmotionScreenState();
}

class _LogEmotionScreenState extends State<LogEmotionScreen> {
  String? selectedEnergy; // store the energy "name"
  int intensity = 3; // default (will be set when user taps an energy)
  final TextEditingController noteController = TextEditingController();

  final energies = [
    {
      'name': 'totally_drained',
      'label': 'Totally drained.',
      'icon': Icons.battery_0_bar,
      'color': Colors.red,
      'value': 1
    },
    {
      'name': 'running_low',
      'label': 'Running low...',
      'icon': Icons.battery_1_bar,
      'color': Colors.orange,
      'value': 2
    },
    {
      'name': 'medium_energy',
      'label': 'Medium energy',
      'icon': Icons.battery_2_bar,
      'color': Colors.green,
      'value': 3
    },
    {
      'name': 'energized',
      'label': 'Energized!',
      'icon': Icons.battery_3_bar,
      'color': Colors.blue,
      'value': 4
    },
    {
      'name': 'fully_charged',
      'label': 'Fully charged!!!',
      'icon': Icons.battery_full,
      'color': Colors.purple,
      'value': 5
    },
  ];

  Future<void> saveEmotion() async {
    if (selectedEnergy == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an energy level')),
      );
      return;
    }

    // intensity already set when selecting; ensure it's consistent
    final log = EmotionLog(
      emotion: selectedEnergy!,
      intensity: intensity,
      note: noteController.text,
      dateTime: DateTime.now(),
    );

    await DatabaseService.instance.insertEmotion(log);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry saved!')),
      );
      Navigator.pop(context);
    }
  }

  void _onSelectEnergy(Map<String, Object?> energy) {
    setState(() {
      selectedEnergy = energy['name'] as String?;
      intensity = (energy['value'] as int?) ?? 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.purple,
        title: const Text('Log Your Energy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What\'s your energy level right now?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: energies.map((energy) {
                final isSelected = selectedEnergy == energy['name'];
                final color = energy['color'] as Color;
                return GestureDetector(
                  onTap: () => _onSelectEnergy(energy),
                  child: Container(
                    width: (MediaQuery.of(context).size.width - 56) / 3,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? color : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color, width: 2),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha:0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          energy['icon'] as IconData,
                          size: 40,
                          color: isSelected ? Colors.white : color,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          energy['label'] as String,
                          textAlign: TextAlign.center,
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

            // NOTE: intensity slider removed intentionally per request.

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
                hintText: 'What triggered this feeling? Any thoughts...',
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
                onPressed: saveEmotion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
