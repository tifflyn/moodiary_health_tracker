import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/emotionlog.dart';
import '../services/firebase_service.dart';
import '../providers/auth_provider.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../widgets/glass_card.dart';

class LogEmotionScreen extends StatefulWidget {
  const LogEmotionScreen({super.key});

  @override
  State<LogEmotionScreen> createState() => _LogEmotionScreenState();
}

class _LogEmotionScreenState extends State<LogEmotionScreen> {
  String? selectedEnergy;
  final TextEditingController noteController = TextEditingController();
  bool _isSaving = false;

  // 定义一个类型安全的能量级别数据结构
  final List<EnergyLevel> energies = [
    EnergyLevel(
      name: 'totally_drained',
      label: 'Totally drained.',
      icon: Icons.battery_0_bar,
      color: AppColors.drained,
      value: 1,
      gradient: [Colors.red, Colors.red.shade300],
    ),
    EnergyLevel(
      name: 'running_low',
      label: 'Running low...',
      icon: Icons.battery_1_bar,
      color: AppColors.low,
      value: 2,
      gradient: [Colors.orange, Colors.orange.shade300],
    ),
    EnergyLevel(
      name: 'medium_energy',
      label: 'Medium energy',
      icon: Icons.battery_2_bar,
      color: AppColors.medium,
      value: 3,
      gradient: [Colors.green, Colors.green.shade300],
    ),
    EnergyLevel(
      name: 'energized',
      label: 'Energized!',
      icon: Icons.battery_3_bar,
      color: AppColors.good,
      value: 4,
      gradient: [Colors.blue, Colors.blue.shade300],
    ),
    EnergyLevel(
      name: 'fully_charged',
      label: 'Fully charged!!!',
      icon: Icons.battery_full,
      color: AppColors.high,
      value: 5,
      gradient: [Colors.purple, Colors.purple.shade300],
    ),
  ];

  Future<void> saveEmotion() async {
    if (selectedEnergy == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select an energy level',
            style: AppTextStyles.bodySmall,
          ),
          backgroundColor: AppColors.drained,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user.id;

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please sign in first', style: AppTextStyles.bodySmall),
          backgroundColor: AppColors.drained,
        ),
      );
      setState(() => _isSaving = false);
      return;
    }

    // 找到选中的能量级别
    final selected = energies.firstWhere(
      (energy) => energy.name == selectedEnergy,
      orElse: () => energies[2], // 默认为中等能量
    );

    final log = EmotionLog(
      emotion: selectedEnergy!,
      intensity: selected.value,
      note: noteController.text,
      dateTime: DateTime.now(),
    );

    try {
      await FirebaseService.instance.addEmotionLog(userId, log);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Energy level logged successfully!',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
            ),
            backgroundColor: selected.color,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        // 添加轻微延迟，让用户看到成功消息
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e', style: AppTextStyles.bodySmall),
            backgroundColor: AppColors.drained,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildEnergyGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: energies.length,
      itemBuilder: (context, index) {
        final energy = energies[index];
        final isSelected = selectedEnergy == energy.name;

        return GestureDetector(
          onTap: () => setState(() => selectedEnergy = energy.name),
          child: GlassCard(
            padding: const EdgeInsets.all(20),
            color: isSelected ? energy.color.withAlpha(25) : null,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: energy.gradient,
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: energy.color.withAlpha(100),
                              blurRadius: 15,
                              spreadRadius: 3,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(energy.icon, size: 32, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  energy.label,
                  style: AppTextStyles.subtitle2.copyWith(
                    color: isSelected ? energy.color : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${energy.value}/5',
                  style: AppTextStyles.caption.copyWith(
                    color: isSelected ? energy.color : AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.bgGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 头部
              GlassCard(
                margin: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.cardDark,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_back,
                              color: AppColors.lightBlue,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentBlue.withAlpha(25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Log Emotion',
                            style: AppTextStyles.buttonSmall.copyWith(
                              color: AppColors.accentBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'How are you feeling right now?',
                      style: AppTextStyles.headline2,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select your current energy level',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.lightBlue,
                      ),
                    ),
                  ],
                ),
              ),

              // 能量级别选择
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildEnergyGrid(),
                ),
              ),

              // 笔记输入
              GlassCard(
                margin: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add a note (optional)',
                      style: AppTextStyles.subtitle1,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      maxLines: 4,
                      style: AppTextStyles.input,
                      decoration: InputDecoration(
                        hintText:
                            'What\'s on your mind? What triggered this feeling?',
                        hintStyle: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textGray.withAlpha(150),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.cardDark,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),

              // 保存按钮
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: GlassCard(
                  padding: const EdgeInsets.all(0),
                  child: ElevatedButton(
                    onPressed: _isSaving || selectedEnergy == null
                        ? null
                        : saveEmotion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedEnergy != null
                          ? _getSelectedColor()
                          : AppColors.cardDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    child: _isSaving
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save, size: 20),
                              const SizedBox(width: 12),
                              Text('Save Entry', style: AppTextStyles.button),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSelectedColor() {
    if (selectedEnergy == null) return AppColors.cardDark;

    final selected = energies.firstWhere(
      (energy) => energy.name == selectedEnergy,
      orElse: () => energies[2],
    );

    return selected.color;
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }
}

// 定义一个类型安全的 EnergyLevel 类
class EnergyLevel {
  final String name;
  final String label;
  final IconData icon;
  final Color color;
  final int value;
  final List<Color> gradient;

  EnergyLevel({
    required this.name,
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
    required this.gradient,
  });
}
