import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primary      = Color(0xFF2563EB);
  static const Color primaryDark  = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFFEFF6FF);
  static const Color primaryMid   = Color(0xFF3B82F6);
  static const Color accent       = Color(0xFF06B6D4);

  // Background
  static const Color background     = Color(0xFFF5F7FA);
  static const Color surface        = Colors.white;
  static const Color surfaceVariant = Color(0xFFF0F4FF);

  // Attendance status colors
  static const Color attendanceGreen  = Color(0xFF16A34A);
  static const Color attendanceYellow = Color(0xFFD97706);
  static const Color attendanceRed    = Color(0xFFDC2626);

  static const Color greenLight  = Color(0xFFF0FDF4);
  static const Color yellowLight = Color(0xFFFFFBEB);
  static const Color redLight    = Color(0xFFFEF2F2);

  // Text
  static const Color textPrimary   = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint      = Color(0xFF94A3B8);
  static const Color textOnPrimary = Colors.white;

  // Semantic
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color error   = Color(0xFFDC2626);
  static const Color info    = Color(0xFF2563EB);

  // Role accent colors
  static const Color studentColor = Color(0xFF2563EB);
  static const Color staffColor   = Color(0xFF7C3AED);
  static const Color adminColor   = Color(0xFFDB2777);

  // Gradients
  static const List<Color> studentGradient = [Color(0xFF1D4ED8), Color(0xFF3B82F6)];
  static const List<Color> staffGradient   = [Color(0xFF5B21B6), Color(0xFF7C3AED)];
  static const List<Color> adminGradient   = [Color(0xFF9D174D), Color(0xFFDB2777)];

  // Border / divider
  static const Color border   = Color(0xFFE2E8F0);
  static const Color divider  = Color(0xFFF1F5F9);

  // Card shadow
  static const Color shadow = Color(0x0F000000);

  static Color attendanceColor(double percentage) {
    if (percentage >= 75) return attendanceGreen;
    if (percentage >= 65) return attendanceYellow;
    return attendanceRed;
  }

  static Color attendanceLightColor(double percentage) {
    if (percentage >= 75) return greenLight;
    if (percentage >= 65) return yellowLight;
    return redLight;
  }
}
