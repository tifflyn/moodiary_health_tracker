// lib/screens/breathing_exercise_screen.dart
import 'package:flutter/material.dart';

class BreathingExerciseScreen extends StatefulWidget {
  final VoidCallback onCompleted;
  final VoidCallback onTaskCompleted;

  const BreathingExerciseScreen({
    super.key, 
    required this.onCompleted,
    required this.onTaskCompleted,
  });

  @override
  State<BreathingExerciseScreen> createState() => _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen> {
  int breathingPhase = 0;
  bool isRunning = true;
  int completedCycles = 0;
  bool taskMarkedAsCompleted = false;
  bool showContinuePrompt = false;

  @override
  void initState() {
    super.initState();
    _animateBreathing();
  }

  void _animateBreathing() {
    if (!isRunning) return;

    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted || !isRunning) return;
      setState(() => breathingPhase = 1);
      
      Future.delayed(const Duration(seconds: 7), () {
        if (!mounted || !isRunning) return;
        setState(() => breathingPhase = 2);
        
        Future.delayed(const Duration(seconds: 8), () {
          if (!mounted || !isRunning) return;
          setState(() {
            breathingPhase = 0;
            completedCycles++;
          });

          // Mark task as completed after first cycle
          if (completedCycles == 1 && !taskMarkedAsCompleted) {
            taskMarkedAsCompleted = true;
            widget.onTaskCompleted();
          }

          // Show continue prompt after 4 cycles
          if (completedCycles >= 4 && completedCycles % 4 == 0) {
            setState(() {
              showContinuePrompt = true;
            });
          } else if (!showContinuePrompt) {
            _animateBreathing(); // Continue looping
          }
        });
      });
    });
  }

  void _completeExercise() {
    isRunning = false;
    widget.onCompleted();
  }

  void _continueExercise() {
    setState(() {
      showContinuePrompt = false;
    });
    _animateBreathing(); // Continue for another 4 cycles
  }

  void _exitExercise() {
    isRunning = false;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    isRunning = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final instructions = [
      'Breathe In (4 seconds)',
      'Hold (7 seconds)',
      'Breathe Out (8 seconds)',
    ];

    return Scaffold(
      backgroundColor: Colors.indigo[900],
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Breathing exercise UI
                  if (!showContinuePrompt) ...[
                    Text(
                      instructions[breathingPhase],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 60),
                    AnimatedContainer(
                      duration: Duration(
                        seconds: breathingPhase == 0
                            ? 4
                            : breathingPhase == 1
                                ? 7
                                : 8,
                      ),
                      width: breathingPhase == 0
                          ? 200
                          : breathingPhase == 1
                              ? 200
                              : 100,
                      height: breathingPhase == 0
                          ? 200
                          : breathingPhase == 1
                              ? 200
                              : 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha:0.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha:0.3),
                            blurRadius: 40,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),
                    Text(
                      breathingPhase == 0
                          ? 'Inhaling... Fill your lungs slowly'
                          : breathingPhase == 1
                              ? 'Holding... Keep it steady'
                              : 'Exhaling... Release all tension',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha:0.7),
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Completed cycles: $completedCycles',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha:0.5),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Complete button (shown after at least one cycle)
                    if (completedCycles > 0)
                      ElevatedButton(
                        onPressed: _completeExercise,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        child: const Text('Complete Exercise'),
                      ),
                  ],

                  // Continue prompt (shown after every 4 cycles)
                  if (showContinuePrompt) ...[
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 80,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Great Job!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'You have completed $completedCycles breathing cycles',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha:0.8),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: _continueExercise,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Continue 4 More Cycles',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: 200,
                      child: OutlinedButton(
                        onPressed: _completeExercise,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Complete & Exit'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _exitExercise,
              ),
            ),

            // Task completed indicator
            if (taskMarkedAsCompleted && !showContinuePrompt)
              Positioned(
                top: 20,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha:0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Task Completed',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}