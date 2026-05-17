import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/attendance_utils.dart';
import '../../data/models/attendance_model.dart';

class AttendanceIndicatorChip extends StatelessWidget {
  final double percentage;
  final bool compact;

  const AttendanceIndicatorChip({
    super.key,
    required this.percentage,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.attendanceColor(percentage);
    final lightColor = AppColors.attendanceLightColor(percentage);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: lightColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              color: color,
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class MlOdBadge extends StatelessWidget {
  final bool applicable;
  final double rawPercentage;

  const MlOdBadge({
    super.key,
    required this.applicable,
    required this.rawPercentage,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showTooltip(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: applicable ? AppColors.greenLight : AppColors.redLight,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: applicable ? AppColors.attendanceGreen : AppColors.attendanceRed,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              applicable ? Icons.check_circle_outline : Icons.cancel_outlined,
              size: 12,
              color: applicable ? AppColors.attendanceGreen : AppColors.attendanceRed,
            ),
            const SizedBox(width: 4),
            Text(
              'ML/OD ${applicable ? "Applied" : "N/A"}',
              style: TextStyle(
                fontSize: 11,
                color: applicable ? AppColors.attendanceGreen : AppColors.attendanceRed,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.info_outline, size: 11,
              color: applicable ? AppColors.attendanceGreen : AppColors.attendanceRed),
          ],
        ),
      ),
    );
  }

  void _showTooltip(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ML/OD Calculation'),
        content: Text(AttendanceUtils.mlOdTooltip(applicable, rawPercentage)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class AttendanceProgressBar extends StatelessWidget {
  final double percentage;
  final double height;

  const AttendanceProgressBar({
    super.key,
    required this.percentage,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.attendanceColor(percentage);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: (percentage / 100).clamp(0.0, 1.0),
        backgroundColor: color.withOpacity(0.15),
        valueColor: AlwaysStoppedAnimation<Color>(color),
        minHeight: height,
      ),
    );
  }
}

class EligibilityBadge extends StatelessWidget {
  final String status;

  const EligibilityBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AttendanceUtils.eligibilityColor(status);
    final label = AttendanceUtils.eligibilityLabel(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class AttendanceCircle extends StatelessWidget {
  final double percentage;
  final double size;
  final String? label;

  const AttendanceCircle({
    super.key,
    required this.percentage,
    this.size = 80,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.attendanceColor(percentage);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: (percentage / 100).clamp(0.0, 1.0),
            strokeWidth: 6,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (label != null)
                Text(label!, style: TextStyle(fontSize: size * 0.12, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
