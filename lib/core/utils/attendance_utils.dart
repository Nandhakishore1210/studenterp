import '../constants/app_colors.dart';
import 'package:flutter/material.dart';

enum AttendanceLevel { good, atRisk, detained }

class AttendanceUtils {
  AttendanceUtils._();

  static AttendanceLevel level(double percentage) {
    if (percentage >= 75) return AttendanceLevel.good;
    if (percentage >= 65) return AttendanceLevel.atRisk;
    return AttendanceLevel.detained;
  }

  static Color color(double percentage) => AppColors.attendanceColor(percentage);
  static Color lightColor(double percentage) => AppColors.attendanceLightColor(percentage);

  static String emoji(double percentage) {
    switch (level(percentage)) {
      case AttendanceLevel.good:    return '🟢';
      case AttendanceLevel.atRisk:  return '🟡';
      case AttendanceLevel.detained: return '🔴';
    }
  }

  static String label(double percentage) {
    switch (level(percentage)) {
      case AttendanceLevel.good:    return 'Good Standing';
      case AttendanceLevel.atRisk:  return 'At Risk';
      case AttendanceLevel.detained: return 'At Risk of Detention';
    }
  }

  static String eligibilityLabel(String status) {
    switch (status) {
      case 'eligible':  return 'Eligible';
      case 'at_risk':   return 'At Risk';
      case 'detained':  return 'Detained';
      default:          return status;
    }
  }

  static Color eligibilityColor(String status) {
    switch (status) {
      case 'eligible':  return AppColors.attendanceGreen;
      case 'at_risk':   return AppColors.attendanceYellow;
      case 'detained':  return AppColors.attendanceRed;
      default:          return AppColors.textSecondary;
    }
  }

  static String mlOdTooltip(bool applicable, double rawPct) {
    if (applicable) {
      return 'ML/OD applied. Your raw attendance (${rawPct.toStringAsFixed(1)}%) '
          'is ≥65%, so Medical Leave/On Duty days are counted toward your attendance.';
    }
    return 'ML/OD NOT applied. Your raw attendance (${rawPct.toStringAsFixed(1)}%) '
        'is below 65%. ML/OD is only considered when raw attendance is 65% or above.';
  }

  static int classesToReach75(int totalClasses, int presentCount) {
    if (totalClasses == 0) return 0;
    final current = presentCount / totalClasses;
    if (current >= 0.75) return 0;
    // Solve: (present + x) / (total + x) = 0.75
    // present + x = 0.75 * total + 0.75x
    // x - 0.75x = 0.75*total - present
    // 0.25x = 0.75*total - present
    final x = (0.75 * totalClasses - presentCount) / 0.25;
    return x.ceil().clamp(0, 9999);
  }

  static int classesCanMiss(int totalClasses, int presentCount) {
    if (totalClasses == 0) return 0;
    // Solve: present / (total + x) = 0.75
    // No — present stays same, total increases (absences)
    // Or solve: present stays, total stays, absences increase
    // (present) / (total + x) >= 0.65 → x <= present/0.65 - total
    final maxMiss = (presentCount / 0.65 - totalClasses).floor();
    return maxMiss.clamp(0, 9999);
  }
}
