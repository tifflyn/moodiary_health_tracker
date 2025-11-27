// lib/screens/daily_recommendation_screen.dart
import 'package:flutter/material.dart';
import '../../models/daily_recommendation.dart';
import '../../services/database_service.dart';
import '../../services/ai_service.dart';
import 'breathing_screen.dart'; 
import 'meditation.dart';

class DailyRecommendationScreen extends StatefulWidget {
  const DailyRecommendationScreen({super.key});

  @override
  State<DailyRecommendationScreen> createState() =>
      _DailyRecommendationScreenState();
}

class _DailyRecommendationScreenState extends State<DailyRecommendationScreen> {
  DailyRecommendation? todayRecommendation;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrGenerateRecommendation();
  }

Future<void> _markBreathingExerciseAsCompleted() async {
  // You can add database logic here if you want to track breathing exercise completion
  debugPrint('Breathing exercise completed - first cycle finished');
  
  // Optional: Show a snackbar or update UI
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Breathing exercise completed! 🌬️'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

  Future<void> _loadOrGenerateRecommendation() async {
    setState(() => isLoading = true);

    try {
      // Check if today's recommendation exists
      var recommendation = await DatabaseService.instance.getTodayRecommendation();

      if (recommendation == null) {
        // Generate new recommendation based on recent emotions
        final recentEmotions = await DatabaseService.instance.getEmotionsForDateRange(
          DateTime.now().subtract(const Duration(days: 7)),
          DateTime.now(),
        );

        final recData =
            await AIService.instance.generateDailyRecommendation(recentEmotions);

        recommendation = DailyRecommendation(
          title: recData['title']!,
          description: recData['description']!,
          category: recData['category']!,
          imageUrl: recData['imageUrl']!,
          date: DateTime.now(),
        );

        await DatabaseService.instance.insertRecommendation(recommendation);
      }

      if (!mounted) return;

      setState(() {
        todayRecommendation = recommendation;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading recommendation: $e');
      
      if (!mounted) return;

      try {
        final fallbackRecData = await AIService.instance.generateDailyRecommendation([]);
        final fallbackRecommendation = DailyRecommendation(
          title: fallbackRecData['title']!,
          description: fallbackRecData['description']!,
          category: fallbackRecData['category']!,
          imageUrl: fallbackRecData['imageUrl']!,
          date: DateTime.now(),
        );

        setState(() {
          todayRecommendation = fallbackRecommendation;
          isLoading = false;
        });

        try {
          await DatabaseService.instance.insertRecommendation(fallbackRecommendation);
        } catch (_) {}
      } catch (fallbackError) {
        debugPrint('Fallback recommendation also failed: $fallbackError');
        setState(() {
          isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error loading recommendation. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _markAsCompleted() async {
    if (todayRecommendation != null) {
      await DatabaseService.instance
          .markRecommendationCompleted(todayRecommendation!.id!);

      if (!mounted) return;

      setState(() {
        todayRecommendation = DailyRecommendation(
          id: todayRecommendation!.id,
          title: todayRecommendation!.title,
          description: todayRecommendation!.description,
          category: todayRecommendation!.category,
          imageUrl: todayRecommendation!.imageUrl,
          date: todayRecommendation!.date,
          completed: true,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wonderful! You\'re taking care of yourself 🌟'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _startBreathingExercise() {
    // Store context in local variable to avoid using it across async gaps
    
    
    // Navigate to breathing exercise and wait for result
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BreathingExerciseScreen(
          onCompleted: () {
            // Return true when breathing exercise is completed
            Navigator.pop(context, true);
          },
          onTaskCompleted: () {
          // Mark the breathing exercise task as completed in the database
          _markBreathingExerciseAsCompleted();
        },
        ),
      ),
    ).then((result) {
      // If breathing exercise was completed, return true to HomeScreen
      // Check if widget is still mounted before using context
      if (result == true && mounted) {
        Navigator.pop(context, true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.purple,
        title: const Text('Love for the World'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : todayRecommendation == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to load recommendation',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadOrGenerateRecommendation,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Hero image
                      Container(
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(todayRecommendation!.imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha:0.7),
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.all(20),
                          alignment: Alignment.bottomLeft,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  todayRecommendation!.category.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                todayRecommendation!.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Content
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Today\'s Invitation',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              todayRecommendation!.description,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Action buttons
                            if (!todayRecommendation!.completed)
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _markAsCompleted,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _getCategoryColor(),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'I Did This!',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha:0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green, width: 2),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green),
                                    SizedBox(width: 12),
                                    Text(
                                      'Completed! You\'re amazing! 🌟',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 16),

                            // Breathing exercise button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton.icon(
                                onPressed: _startBreathingExercise,
                                icon: const Icon(Icons.air),
                                label: const Text(
                                  'Complete Breathing Exercise Task',
                                  style: TextStyle(fontSize: 16),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: _getCategoryColor()),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),

                          const SizedBox(height: 16),

                          // Meditation card
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const MeditationScreen()),
                                );
                              },
                              icon: const Icon(Icons.self_improvement),
                              label: const Text(
                                'Start Meditation',
                                style: TextStyle(fontSize: 16),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: _getCategoryColor()),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),

                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Color _getCategoryColor() {
    switch (todayRecommendation?.category) {
      case 'nature':
        return Colors.green;
      case 'art':
        return Colors.purple;
      case 'food':
        return Colors.orange;
      case 'music':
        return Colors.pink;
      case 'exercise':
        return Colors.blue;
      default:
        return Colors.teal;
    }
  }
}