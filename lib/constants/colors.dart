// lib/constants/colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // 主色调 - 深色渐变
  static const Color primaryDark = Color(0xFF0A0E21);
  static const Color primaryBlue = Color(0xFF1D2671);
  static const Color accentBlue = Color(0xFF6A93FF);
  static const Color lightBlue = Color(0xFF9BC5FF);

  // 卡片背景
  static const Color cardDark = Color(0xFF1A1F38);
  static const Color cardLight = Color(0xFF252A45);

  // 文字
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGray = Color(0xFFB0B0B0);
  static const Color textLight = Color(0xFFE0E0E0);

  // 进度/状态
  static const Color progressStart = Color(0xFF6A93FF);
  static const Color progressEnd = Color(0xFF9BC5FF);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);

  // 渐变
  static const List<Color> bgGradient = [Color(0xFF0A0E21), Color(0xFF1D2671)];

  static const List<Color> cardGradient = [
    Color(0xFF1A1F38),
    Color(0xFF252A45),
  ];

  static const List<Color> accentGradient = [
    Color(0xFF6A93FF),
    Color(0xFF9BC5FF),
  ];

  // 情绪颜色
  static const Color drained = Color(0xFFFF5252);
  static const Color low = Color(0xFFFF9800);
  static const Color medium = Color(0xFF4CAF50);
  static const Color good = Color(0xFF2196F3);
  static const Color high = Color(0xFF9C27B0);

  // 在 AppColors 类中添加这些渐变
  static const List<Color> sunsetGradient = [
    Color(0xFFFF6B6B), // 珊瑚红
    Color(0xFF4ECDC4), // 青绿色
  ];

  static const List<Color> auroraGradient = [
    Color(0xFF9C27B0), // 紫色
    Color(0xFF2196F3), // 蓝色
    Color(0xFF4CAF50), // 绿色
  ];

  static const List<Color> oceanGradient = [
    Color(0xFF0062FF), // 深蓝
    Color(0xFF00E0FF), // 浅蓝
    Color(0xFF00FFB2), // 青绿
  ];

  static const List<Color> fireGradient = [
    Color(0xFFFF416C), // 深红
    Color(0xFFFF4B2B), // 橙红
  ];

  static const List<Color> spaceGradient = [
    Color(0xFF0F2027), // 深空
    Color(0xFF203A43), // 太空蓝
    Color(0xFF2C5364), // 星空紫
  ];

  static const List<Color> magicGradient = [
    Color(0xFF667EEA), // 魔法蓝
    Color(0xFF764BA2), // 魔法紫
  ];

  static const List<Color> candyGradient = [
    Color(0xFFFF9A9E), // 粉红
    Color(0xFFFAD0C4), // 浅桃
    Color(0xFFFAD0C4), // 浅桃
  ];

  // 动态获取渐变 - 根据时间、心情等
  static List<Color> getDynamicGradient() {
    final hour = DateTime.now().hour;

    if (hour >= 6 && hour < 12) {
      return sunsetGradient; // 早晨：日出渐变
    } else if (hour >= 12 && hour < 18) {
      return oceanGradient; // 下午：海洋渐变
    } else {
      return spaceGradient; // 晚上：星空渐变
    }
  }
}
